const express = require('express');
const router = express.Router();
const { getJobMatches } = require('../controllers/matchController');
const { auth } = require('../middleware/auth');
const { cacheMiddleware } = require('../middleware/cache');

// Get job matches for a user (protected)
router.get('/:userId', auth, cacheMiddleware(600), getJobMatches);

module.exports = router;
