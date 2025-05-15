// Simple packaging script for Lambda deployment (exam-ready, realistic)
const fs = require('fs');
const archiver = require('archiver');
const path = require('path');

const output = fs.createWriteStream(path.join(__dirname, 'security_assessment.zip'));
const archive = archiver('zip', { zlib: { level: 9 } });

output.on('close', () => {
  console.log(`Packaged Lambda: ${archive.pointer()} total bytes`);
});

archive.on('error', (err) => { throw err; });

archive.pipe(output);
archive.file(path.join(__dirname, 'security_assessment.js'), { name: 'security_assessment.js' });
archive.finalize();
