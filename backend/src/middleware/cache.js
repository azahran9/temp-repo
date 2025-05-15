// Middleware for Redis caching
const cacheMiddleware = (duration) => {
  return async (req, res, next) => {
    // Skip caching if Redis is not available
    const redisClient = req.app.get('redisClient');
    if (!redisClient) return next();
    
    try {
      // Create a unique cache key based on the route and query parameters
      const cacheKey = `api:${req.originalUrl}`;
      
      // Try to get cached response
      const cachedResponse = await redisClient.get(cacheKey);
      
      if (cachedResponse) {
        // Return cached response
        return res.json(JSON.parse(cachedResponse));
      }
      
      // If no cache found, continue with request and cache the response
      const originalSend = res.json;
      res.json = function(body) {
        // Only cache successful responses
        if (res.statusCode >= 200 && res.statusCode < 300) {
          redisClient.set(cacheKey, JSON.stringify(body), {
            EX: duration // Set expiration in seconds
          }).catch(err => console.error('Redis cache error:', err));
        }
        originalSend.call(this, body);
      };
      
      next();
    } catch (err) {
      console.error('Cache middleware error:', err);
      next(); // Continue without caching
    }
  };
};

// Clear cache for specific patterns
const clearCache = async (pattern, req) => {
  try {
    const redisClient = req.app.get('redisClient');
    if (!redisClient) return;
    
    const keys = await redisClient.keys(pattern);
    if (keys.length > 0) {
      await redisClient.del(keys);
    }
  } catch (err) {
    console.error('Clear cache error:', err);
  }
};

module.exports = { cacheMiddleware, clearCache };
