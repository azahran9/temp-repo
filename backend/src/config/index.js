require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  mongoURI: process.env.MONGO_URI || 'mongodb://localhost:27017/job-matching',
  jwtSecret: process.env.JWT_SECRET || 'your_jwt_secret',
  jwtExpiration: process.env.JWT_EXPIRATION || '1d',
  redisURI: process.env.REDIS_URI || 'redis://localhost:6379',
  useRedis: process.env.USE_REDIS === 'true' || false,
  rateLimit: {
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5, // 5 requests per hour for job applications
    standardHeaders: true,
    legacyHeaders: false,
  },
  environment: process.env.NODE_ENV || 'development'
};
