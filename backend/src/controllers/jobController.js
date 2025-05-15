const Job = require('../models/Job');
const { clearCache } = require('../middleware/cache');

// Create a new job posting
const createJob = async (req, res) => {
  try {
    const {
      title,
      company,
      description,
      requirements,
      skills,
      location,
      salary,
      employmentType
    } = req.body;
    
    const job = new Job({
      title,
      company,
      description,
      requirements,
      skills,
      location,
      salary,
      employmentType,
      employer: req.user.id
    });
    
    await job.save();
    
    // Clear jobs cache
    await clearCache('api:/jobs*', req);
    
    res.status(201).json({
      message: 'Job created successfully',
      job
    });
  } catch (error) {
    console.error('Create job error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get all jobs with pagination
const getJobs = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;
    
    // Build filter object based on query parameters
    const filter = { active: true };
    
    if (req.query.location) {
      filter.location = { $regex: req.query.location, $options: 'i' };
    }
    
    if (req.query.employmentType) {
      filter.employmentType = req.query.employmentType;
    }
    
    if (req.query.skills) {
      const skillsArray = req.query.skills.split(',').map(skill => skill.trim());
      filter.skills = { $in: skillsArray };
    }
    
    if (req.query.search) {
      filter.$text = { $search: req.query.search };
    }
    
    // Build sort object
    let sort = { createdAt: -1 }; // Default: newest first
    
    if (req.query.sort) {
      if (req.query.sort === 'salary') {
        sort = { 'salary.max': -1 };
      }
    }
    
    // Execute query with pagination
    const jobs = await Job.find(filter)
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .populate('employer', 'firstName lastName company');
    
    // Get total count for pagination
    const total = await Job.countDocuments(filter);
    
    res.json({
      jobs,
      pagination: {
        total,
        page,
        limit,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get jobs error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get job by ID
const getJobById = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id)
      .populate('employer', 'firstName lastName company');
    
    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }
    
    res.json(job);
  } catch (error) {
    console.error('Get job by ID error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update job
const updateJob = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    
    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }
    
    // Check if user is the employer or admin
    if (job.employer.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to update this job' });
    }
    
    const {
      title,
      company,
      description,
      requirements,
      skills,
      location,
      salary,
      employmentType,
      active
    } = req.body;
    
    // Update fields if provided
    if (title) job.title = title;
    if (company) job.company = company;
    if (description) job.description = description;
    if (requirements) job.requirements = requirements;
    if (skills) job.skills = skills;
    if (location) job.location = location;
    if (salary) job.salary = salary;
    if (employmentType) job.employmentType = employmentType;
    if (active !== undefined) job.active = active;
    
    await job.save();
    
    // Clear jobs cache
    await clearCache('api:/jobs*', req);
    
    res.json({
      message: 'Job updated successfully',
      job
    });
  } catch (error) {
    console.error('Update job error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Delete job
const deleteJob = async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    
    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }
    
    // Check if user is the employer or admin
    if (job.employer.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to delete this job' });
    }
    
    await job.remove();
    
    // Clear jobs cache
    await clearCache('api:/jobs*', req);
    
    res.json({ message: 'Job deleted successfully' });
  } catch (error) {
    console.error('Delete job error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  createJob,
  getJobs,
  getJobById,
  updateJob,
  deleteJob
};
