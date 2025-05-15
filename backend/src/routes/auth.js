const express = require('express');
const router = express.Router();
const { register, login, getProfile, updateProfile } = require('../controllers/authController');
const { auth } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');

// Register new user
router.post('/register', apiLimiter, register);

// Login user
router.post('/login', apiLimiter, login);

// Get user profile (protected)
router.get('/profile', auth, getProfile);

// Update user profile (protected)
router.put('/profile', auth, updateProfile);

module.exports = router;
