const express = require('express');
const router = express.Router();
const { 
  applyForJob, 
  getUserApplications, 
  getJobApplications, 
  updateApplicationStatus 
} = require('../controllers/applicationController');
const { auth, isEmployer } = require('../middleware/auth');
const { applicationLimiter } = require('../middleware/rateLimiter');

// Apply for a job (protected, rate limited)
router.post('/', auth, applicationLimiter, applyForJob);

// Get user's applications (protected)
router.get('/user', auth, getUserApplications);

// Get applications for a job (protected, employers only)
router.get('/job/:jobId', auth, isEmployer, getJobApplications);

// Update application status (protected, employers only)
router.put('/:applicationId', auth, isEmployer, updateApplicationStatus);

module.exports = router;
