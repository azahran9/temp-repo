const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema({
  job: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Job',
    required: true
  },
  applicant: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  coverLetter: {
    type: String
  },
  resume: {
    type: String
  },
  status: {
    type: String,
    enum: ['pending', 'reviewed', 'interviewed', 'rejected', 'accepted'],
    default: 'pending'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Compound index to ensure a user can only apply once to a job
applicationSchema.index({ job: 1, applicant: 1 }, { unique: true });

// Indexes for faster queries
applicationSchema.index({ applicant: 1 });
applicationSchema.index({ job: 1 });
applicationSchema.index({ status: 1 });
applicationSchema.index({ createdAt: -1 });

const Application = mongoose.model('Application', applicationSchema);

module.exports = Application;
