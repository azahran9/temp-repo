const rateLimit = require('express-rate-limit');
const config = require('../config');

// General rate limiter for API endpoints
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    message: 'Too many requests, please try again later.'
  }
});

// Specific rate limiter for job applications
const applicationLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs, // 1 hour
  max: config.rateLimit.max, // 5 applications per hour
  standardHeaders: config.rateLimit.standardHeaders,
  legacyHeaders: config.rateLimit.legacyHeaders,
  message: {
    message: `You can only apply to ${config.rateLimit.max} jobs per hour.`
  },
  keyGenerator: (req) => {
    // Use user ID as key if authenticated, otherwise use IP
    return req.user ? req.user.id : req.ip;
  },
  skip: (req) => {
    // Skip rate limiting for admins
    return req.user && req.user.role === 'admin';
  }
});

module.exports = { apiLimiter, applicationLimiter };
