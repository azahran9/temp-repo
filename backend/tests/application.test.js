const mongoose = require('mongoose');
const request = require('supertest');
const app = require('../src/server');
const User = require('../src/models/User');
const Job = require('../src/models/Job');
const Application = require('../src/models/Application');
const jwt = require('jsonwebtoken');
const config = require('../src/config');

// Mock data
const testUser = {
  _id: new mongoose.Types.ObjectId(),
  email: 'testuser@example.com',
  password: 'password123',
  firstName: 'Test',
  lastName: 'User',
  role: 'jobseeker',
  skills: ['JavaScript', 'React', 'Node.js']
};

const testEmployer = {
  _id: new mongoose.Types.ObjectId(),
  email: 'employer@example.com',
  password: 'password123',
  firstName: 'Test',
  lastName: 'Employer',
  role: 'employer',
  company: 'Test Company'
};

const testJob = {
  _id: new mongoose.Types.ObjectId(),
  title: 'Software Developer',
  company: 'Test Company',
  description: 'Test job description',
  requirements: ['3+ years experience'],
  skills: ['JavaScript', 'React', 'Node.js'],
  location: 'Remote',
  salary: { min: 80000, max: 120000, currency: 'USD' },
  employmentType: 'full-time',
  employer: testEmployer._id,
  active: true
};

// Generate token for test user
const generateToken = (user) => {
  return jwt.sign(
    { id: user._id, role: user.role },
    config.jwtSecret,
    { expiresIn: '1h' }
  );
};

// Setup and teardown
beforeAll(async () => {
  // Connect to test database
  await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/job-matching-test', {
    useNewUrlParser: true,
    useUnifiedTopology: true
  });
});

afterAll(async () => {
  // Clean up and close connection
  await mongoose.connection.close();
});

beforeEach(async () => {
  // Clear collections before each test
  await User.deleteMany({});
  await Job.deleteMany({});
  await Application.deleteMany({});
  
  // Create test user and employer
  await User.create(testUser);
  await User.create(testEmployer);
  
  // Create test job
  await Job.create(testJob);
});

describe('POST /apply', () => {
  test('should allow a user to apply for a job', async () => {
    const token = generateToken(testUser);
    
    const response = await request(app)
      .post('/api/apply')
      .set('Authorization', `Bearer ${token}`)
      .send({
        jobId: testJob._id,
        coverLetter: 'I am interested in this position',
        resume: 'resume-url'
      });
    
    expect(response.status).toBe(201);
    expect(response.body.message).toBe('Application submitted successfully');
    expect(response.body.application).toHaveProperty('job', testJob._id.toString());
    expect(response.body.application).toHaveProperty('applicant', testUser._id.toString());
    
    // Verify application was saved to database
    const application = await Application.findOne({ 
      job: testJob._id,
      applicant: testUser._id
    });
    expect(application).not.toBeNull();
    
    // Verify job application count was incremented
    const job = await Job.findById(testJob._id);
    expect(job.applicationCount).toBe(1);
  });
  
  test('should prevent duplicate applications', async () => {
    const token = generateToken(testUser);
    
    // First application
    await request(app)
      .post('/api/apply')
      .set('Authorization', `Bearer ${token}`)
      .send({
        jobId: testJob._id,
        coverLetter: 'First application',
        resume: 'resume-url'
      });
    
    // Duplicate application
    const response = await request(app)
      .post('/api/apply')
      .set('Authorization', `Bearer ${token}`)
      .send({
        jobId: testJob._id,
        coverLetter: 'Duplicate application',
        resume: 'resume-url'
      });
    
    expect(response.status).toBe(400);
    expect(response.body.message).toBe('You have already applied for this job');
    
    // Verify only one application exists
    const count = await Application.countDocuments({
      job: testJob._id,
      applicant: testUser._id
    });
    expect(count).toBe(1);
  });
  
  test('should return 404 for non-existent job', async () => {
    const token = generateToken(testUser);
    const nonExistentJobId = new mongoose.Types.ObjectId();
    
    const response = await request(app)
      .post('/api/apply')
      .set('Authorization', `Bearer ${token}`)
      .send({
        jobId: nonExistentJobId,
        coverLetter: 'Application for non-existent job',
        resume: 'resume-url'
      });
    
    expect(response.status).toBe(404);
    expect(response.body.message).toBe('Job not found');
  });
  
  test('should require authentication', async () => {
    const response = await request(app)
      .post('/api/apply')
      .send({
        jobId: testJob._id,
        coverLetter: 'Application without auth',
        resume: 'resume-url'
      });
    
    expect(response.status).toBe(401);
  });
});
