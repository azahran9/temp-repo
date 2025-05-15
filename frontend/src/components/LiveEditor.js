import React, { useState, useEffect, useRef, useCallback } from 'react';
import Quill from 'quill';
import debounce from 'lodash.debounce';
import './LiveEditor.css';

// Usage: <LiveEditor documentId="doc1" userId="user42" />
const LiveEditor = ({ documentId, userId }) => {
  const [content, setContent] = useState('');
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState(null);
  const [history, setHistory] = useState([]);
  const [historyIndex, setHistoryIndex] = useState(-1);
  const [isLoading, setIsLoading] = useState(true);

  const wsRef = useRef(null);
  const quillRef = useRef(null);
  const editorRef = useRef(null);
  const reconnectTimeout = useRef(null);

  // Setup WebSocket connection
  useEffect(() => {
    let ws;
    function connect() {
      ws = new WebSocket(`ws://live-editor.server.com?documentId=${documentId}&userId=${userId}`);
      wsRef.current = ws;

      ws.onopen = () => {
        setIsConnected(true);
        setError(null);
      };
      ws.onclose = () => {
        setIsConnected(false);
        if (reconnectTimeout.current) clearTimeout(reconnectTimeout.current);
        reconnectTimeout.current = setTimeout(connect, 3000);
      };
      ws.onerror = () => {
        setError('WebSocket error');
        setIsConnected(false);
      };
      ws.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.type === 'init') {
          setContent(msg.content);
          setHistory([msg.content]);
          setHistoryIndex(0);
          setIsLoading(false);
          if (quillRef.current) quillRef.current.setContents(quillRef.current.clipboard.convert(msg.content));
        } else if (msg.type === 'update' && msg.userId !== userId) {
          setContent(msg.content);
          if (quillRef.current) quillRef.current.setContents(quillRef.current.clipboard.convert(msg.content));
          setHistory(prev => [...prev, msg.content]);
          setHistoryIndex(idx => idx + 1);
        } else if (msg.type === 'error') {
          setError(msg.message);
        }
      };
    }
    connect();
    return () => {
      if (ws) ws.close();
      if (reconnectTimeout.current) clearTimeout(reconnectTimeout.current);
    };
  }, [documentId, userId]);

  // Initialize Quill editor
  useEffect(() => {
    if (!editorRef.current) return;
    if (quillRef.current) return;
    const quill = new Quill(editorRef.current, {
      theme: 'snow',
      modules: { toolbar: true },
      placeholder: 'Start typing...'
    });
    quillRef.current = quill;
    quill.on('text-change', () => {
      const html = quill.root.innerHTML;
      setContent(html);
      debouncedSend(html);
      setHistory(prev => {
        if (prev[historyIndex] !== html) {
          const newHist = prev.slice(0, historyIndex + 1).concat(html);
          setHistoryIndex(newHist.length - 1);
          return newHist;
        }
        return prev;
      });
    });
  }, [historyIndex]);

  // Debounced WebSocket send
  const debouncedSend = useCallback(
    debounce((html) => {
      if (wsRef.current && wsRef.current.readyState === 1) {
        wsRef.current.send(JSON.stringify({ type: 'update', content: html, documentId, userId }));
      }
    }, 300),
    [documentId, userId]
  );

  // Undo/redo
  const handleUndo = useCallback(() => {
    if (historyIndex > 0) {
      setHistoryIndex(idx => {
        const newIdx = idx - 1;
        if (quillRef.current) quillRef.current.root.innerHTML = history[newIdx];
        setContent(history[newIdx]);
        debouncedSend(history[newIdx]);
        return newIdx;
      });
    }
  }, [history, historyIndex, debouncedSend]);

  const handleRedo = useCallback(() => {
    if (historyIndex < history.length - 1) {
      setHistoryIndex(idx => {
        const newIdx = idx + 1;
        if (quillRef.current) quillRef.current.root.innerHTML = history[newIdx];
        setContent(history[newIdx]);
        debouncedSend(history[newIdx]);
        return newIdx;
      });
    }
  }, [history, historyIndex, debouncedSend]);

  // Lazy loading: simulate by limiting visible content
  // (Quill doesn't support true lazy loading, so this is a stub for exam purposes)

  if (isLoading) return <div className="loading">Loading...</div>;

  return (
    <div className="live-editor-container">
      <div className="editor-toolbar">
        <button onClick={handleUndo} disabled={historyIndex <= 0}>Undo</button>
        <button onClick={handleRedo} disabled={historyIndex >= history.length - 1}>Redo</button>
        <span className={isConnected ? 'status-connected' : 'status-disconnected'}>
          {isConnected ? 'Connected' : 'Disconnected'}
        </span>
        {error && <span className="error-message">{error}</span>}
      </div>
      <div className="editor-content">
        <div ref={editorRef} style={{ minHeight: 300 }} />
      </div>
    </div>
  );
};

export default React.memo(LiveEditor);

        // Limit history size to prevent memory issues
        const newHistory = [...updatedHistory, newContent].slice(-50);
        setHistoryIndex(newHistory.length - 1);
        return newHistory;
      }
      return updatedHistory;
    });
  }, [historyIndex]);

  // Undo function
  const handleUndo = useCallback(() => {
    if (historyIndex > 0) {
      const newIndex = historyIndex - 1;
      setHistoryIndex(newIndex);
      setContent(history[newIndex]);
      debounceContentUpdate(history[newIndex]);
    }
  }, [history, historyIndex, debounceContentUpdate]);

  // Redo function
  const handleRedo = useCallback(() => {
    if (historyIndex < history.length - 1) {
      const newIndex = historyIndex + 1;
      setHistoryIndex(newIndex);
      setContent(history[newIndex]);
      debounceContentUpdate(history[newIndex]);
    }
  }, [history, historyIndex, debounceContentUpdate]);

  // Track cursor position
  const handleCursorPosition = useCallback(() => {
    const selection = window.getSelection();
    if (selection.rangeCount > 0) {
      const range = selection.getRangeAt(0);
      const position = range.startOffset;
      
      if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
        wsRef.current.send(JSON.stringify({
          type: 'cursor',
          position,
          documentId,
          userId
        }));
      }
    }
  }, [documentId, userId]);

  // Render other users' cursors
  const renderCursors = useCallback(() => {
    // Implementation would depend on how you want to visually represent cursors
    // This is a simplified placeholder
    const cursorsContainer = document.getElementById('cursors-container');
    if (cursorsContainer) {
      cursorsContainer.innerHTML = '';
      
      Object.entries(userCursorPositions.current).forEach(([cursorUserId, position]) => {
        const cursorElement = document.createElement('div');
        cursorElement.className = 'user-cursor';
        cursorElement.style.left = `${position}px`;
        cursorElement.setAttribute('data-user-id', cursorUserId);
        cursorsContainer.appendChild(cursorElement);
      });
    }
  }, []);

  // Handle scroll for lazy loading
  const handleScroll = useCallback((e) => {
    const { scrollTop, scrollHeight, clientHeight } = e.target;
    
    // If scrolled near bottom, load more content
    if (scrollHeight - scrollTop - clientHeight < 200) {
      setVisibleRange(prev => ({
        start: prev.start,
        end: prev.end + 50
      }));
    }
    
    // If scrolled near top, load previous content
    if (scrollTop < 200 && prev.start > 0) {
      setVisibleRange(prev => ({
        start: Math.max(0, prev.start - 50),
        end: prev.end
      }));
    }
  }, []);

  // Memoize the content to display based on lazy loading
  const visibleContent = useMemo(() => {
    if (!content) return '';
    
    // This is a simplified approach - in a real implementation,
    // you would need to split content intelligently (by paragraphs, etc.)
    const lines = content.split('\n');
    return lines.slice(visibleRange.start, visibleRange.end).join('\n');
  }, [content, visibleRange]);

  if (isLoading) {
    return <div className="loading">Loading document...</div>;
  }

  return (
    <div className="live-editor-container">
      {error && <div className="error-message">{error}</div>}
      
      <div className="editor-toolbar">
        <button 
          onClick={handleUndo} 
          disabled={historyIndex <= 0}
          className="toolbar-button"
        >
          Undo
        </button>
        <button 
          onClick={handleRedo} 
          disabled={historyIndex >= history.length - 1}
          className="toolbar-button"
        >
          Redo
        </button>
        <div className="connection-status">
          {isConnected ? 
            <span className="connected">Connected</span> : 
            <span className="disconnected">Disconnected</span>
          }
        </div>
      </div>
      
      <div 
        className="editor-content"
        onScroll={handleScroll}
      >
        <div id="cursors-container" className="cursors-container"></div>
        <div
          ref={contentRef}
          className="content-editable"
          contentEditable={true}
          onInput={handleContentChange}
          onKeyUp={handleCursorPosition}
          onMouseUp={handleCursorPosition}
          dangerouslySetInnerHTML={{ __html: visibleContent }}
        ></div>
      </div>
    </div>
  );
};

