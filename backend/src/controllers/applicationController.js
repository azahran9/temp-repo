const Application = require('../models/Application');
const Job = require('../models/Job');
const mongoose = require('mongoose');

// Apply for a job
const applyForJob = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();
  
  try {
    const { jobId, coverLetter, resume } = req.body;
    
    // Check if job exists
    const job = await Job.findById(jobId).session(session);
    if (!job) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ message: 'Job not found' });
    }
    
    // Check if job is active
    if (!job.active) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ message: 'This job is no longer accepting applications' });
    }
    
    // Check if user has already applied
    const existingApplication = await Application.findOne({
      job: jobId,
      applicant: req.user.id
    }).session(session);
    
    if (existingApplication) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ message: 'You have already applied for this job' });
    }
    
    // Create application
    const application = new Application({
      job: jobId,
      applicant: req.user.id,
      coverLetter,
      resume,
      status: 'pending'
    });
    
    await application.save({ session });
    
    // Increment application count on job
    job.applicationCount += 1;
    await job.save({ session });
    
    await session.commitTransaction();
    session.endSession();
    
    res.status(201).json({
      message: 'Application submitted successfully',
      application
    });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    
    if (error.code === 11000) {
      return res.status(400).json({ message: 'You have already applied for this job' });
    }
    
    console.error('Apply for job error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get user's applications
const getUserApplications = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    
    const applications = await Application.find({ applicant: req.user.id })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate({
        path: 'job',
        select: 'title company location salary employmentType'
      });
    
    const total = await Application.countDocuments({ applicant: req.user.id });
    
    res.json({
      applications,
      pagination: {
        total,
        page,
        limit,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get user applications error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get applications for a job (for employers)
const getJobApplications = async (req, res) => {
  try {
    const { jobId } = req.params;
    
    // Check if job exists and user is the employer
    const job = await Job.findById(jobId);
    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }
    
    if (job.employer.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to view these applications' });
    }
    
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    
    const applications = await Application.find({ job: jobId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate({
        path: 'applicant',
        select: 'firstName lastName email skills experience education'
      });
    
    const total = await Application.countDocuments({ job: jobId });
    
    res.json({
      applications,
      pagination: {
        total,
        page,
        limit,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get job applications error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update application status (for employers)
const updateApplicationStatus = async (req, res) => {
  try {
    const { applicationId } = req.params;
    const { status } = req.body;
    
    const application = await Application.findById(applicationId)
      .populate('job', 'employer');
    
    if (!application) {
      return res.status(404).json({ message: 'Application not found' });
    }
    
    // Check if user is the employer or admin
    if (application.job.employer.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to update this application' });
    }
    
    application.status = status;
    await application.save();
    
    res.json({
      message: 'Application status updated successfully',
      application
    });
  } catch (error) {
    console.error('Update application status error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  applyForJob,
  getUserApplications,
  getJobApplications,
  updateApplicationStatus
};
