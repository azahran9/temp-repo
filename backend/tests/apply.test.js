const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/server');
const User = require('../src/models/User');
const Job = require('../src/models/Job');
const Application = require('../src/models/Application');
const jwt = require('jsonwebtoken');
const config = require('../src/config');

describe('POST /api/apply', () => {
  let user, token, job;

  beforeAll(async () => {
    await User.deleteMany({});
    await Job.deleteMany({});
    await Application.deleteMany({});
    user = await User.create({
      email: 'test@example.com',
      password: 'password123',
      firstName: 'Test',
      lastName: 'User',
      role: 'jobseeker',
      skills: ['javascript', 'react']
    });
    token = jwt.sign({ id: user._id }, config.jwtSecret, { expiresIn: '1h' });
    job = await Job.create({
      title: 'Frontend Developer',
      company: 'Acme Inc',
      description: 'Build UIs',
      requirements: ['javascript'],
      skills: ['javascript', 'react'],
      location: 'Remote',
      employer: user._id
    });
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  it('should allow user to apply for a job', async () => {
    const res = await request(app)
      .post('/api/apply')
      .set('Authorization', `Bearer ${token}`)
      .send({ jobId: job._id });
    expect(res.statusCode).toBe(201);
    expect(res.body.application).toBeDefined();
  });

  it('should prevent duplicate applications', async () => {
    const res = await request(app)
      .post('/api/apply')
      .set('Authorization', `Bearer ${token}`)
      .send({ jobId: job._id });
    expect(res.statusCode).toBe(409);
    expect(res.body.message).toMatch(/already applied/i);
  });
});
