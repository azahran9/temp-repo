const express = require('express');
const router = express.Router();
const Application = require('../models/Application');
const Job = require('../models/Job');
const { auth } = require('../middleware/auth');
const { applicationLimiter } = require('../middleware/rateLimiter');

// POST /apply - User applies for a job (only once)
router.post('/', auth, applicationLimiter, async (req, res) => {
  try {
    const { jobId, coverLetter, resume } = req.body;
    if (!jobId) return res.status(400).json({ message: 'Job ID is required.' });

    // Check if job exists
    const job = await Job.findById(jobId);
    if (!job || !job.active) {
      return res.status(404).json({ message: 'Job not found or inactive.' });
    }

    // Check for duplicate application (enforced by DB, but check here for UX)
    const existing = await Application.findOne({ job: jobId, applicant: req.user.id });
    if (existing) {
      return res.status(409).json({ message: 'You have already applied for this job.' });
    }

    // Create application
    const application = new Application({
      job: jobId,
      applicant: req.user.id,
      coverLetter,
      resume
    });
    await application.save();

    // Optionally increment job application count
    await Job.findByIdAndUpdate(jobId, { $inc: { applicationCount: 1 } });

    res.status(201).json({ message: 'Application submitted.', application });
  } catch (err) {
    if (err.code === 11000) {
      // Duplicate key error (unique index)
      return res.status(409).json({ message: 'You have already applied for this job.' });
    }
    console.error('Apply error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
