const express = require('express');
const router = express.Router();
const { 
  createJob, 
  getJobs, 
  getJobById, 
  updateJob, 
  deleteJob 
} = require('../controllers/jobController');
const { auth, isEmployer } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');
const { cacheMiddleware } = require('../middleware/cache');

// Create job (protected, employers only)
router.post('/', auth, isEmployer, createJob);

// Get all jobs (public, cached)
router.get('/', cacheMiddleware(300), getJobs);

// Get job by ID (public, cached)
router.get('/:id', cacheMiddleware(300), getJobById);

// Update job (protected, employers only)
router.put('/:id', auth, isEmployer, updateJob);

// Delete job (protected, employers only)
router.delete('/:id', auth, isEmployer, deleteJob);

module.exports = router;
