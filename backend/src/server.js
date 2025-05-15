const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const { createClient } = require('redis');
const config = require('./config');
const jobRoutes = require('./routes/jobs');
const applicationRoutes = require('./routes/apply');
const matchRoutes = require('./routes/matches');
const authRoutes = require('./routes/auth');

// Initialize Express app
const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Connect to MongoDB
mongoose.connect(config.mongoURI)
  .then(() => console.log('MongoDB connected'))
  .catch(err => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });

// Initialize Redis client for caching
let redisClient;
const connectRedis = async () => {
  try {
    redisClient = createClient({
      url: config.redisURI
    });
    
    redisClient.on('error', (err) => {
      console.error('Redis error:', err);
    });
    
    await redisClient.connect();
    console.log('Redis connected');
    
    // Make Redis client available globally
    app.set('redisClient', redisClient);
  } catch (err) {
    console.error('Redis connection error:', err);
    // Continue without Redis - app should work with reduced performance
  }
};

// Connect to Redis if enabled
if (config.useRedis) {
  connectRedis();
}

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/jobs', jobRoutes);
app.use('/api/apply', applicationRoutes);
app.use('/api/matches', matchRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    message: 'Something went wrong',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start server
const PORT = config.port || 3000;
const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    mongoose.connection.close(false, () => {
      console.log('MongoDB connection closed');
      if (redisClient) redisClient.quit();
      process.exit(0);
    });
  });
});

module.exports = app;
