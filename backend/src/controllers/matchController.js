const User = require('../models/User');
const Job = require('../models/Job');

// Get AI-based job matches for a user
const getJobMatches = async (req, res) => {
  try {
    const userId = req.params.userId;
    
    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Check if requesting user is authorized
    if (userId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to view these matches' });
    }
    
    // Get user skills
    const userSkills = user.skills || [];
    if (userSkills.length === 0) {
      return res.json({
        message: 'User has no skills defined',
        matches: []
      });
    }
    
    // Find jobs matching user skills
    // This is a simple matching algorithm - in a real app, you'd use more sophisticated ML/AI
    const matches = await Job.aggregate([
      // Only include active jobs
      { $match: { active: true } },
      
      // Calculate match score based on skills overlap
      {
        $addFields: {
          skillsMatch: {
            $size: {
              $setIntersection: ["$skills", userSkills]
            }
          },
          totalJobSkills: { $size: "$skills" }
        }
      },
      
      // Calculate match percentage
      {
        $addFields: {
          matchScore: {
            $multiply: [
              { $divide: ["$skillsMatch", { $max: ["$totalJobSkills", 1] }] },
              100
            ]
          }
        }
      },
      
      // Only include jobs with at least one skill match
      { $match: { skillsMatch: { $gt: 0 } } },
      
      // Sort by match score (descending)
      { $sort: { matchScore: -1 } },
      
      // Limit to top 20 matches
      { $limit: 20 },
      
      // Project only needed fields
      {
        $project: {
          _id: 1,
          title: 1,
          company: 1,
          location: 1,
          employmentType: 1,
          salary: 1,
          skills: 1,
          matchScore: 1,
          matchedSkills: {
            $setIntersection: ["$skills", userSkills]
          }
        }
      }
    ]);
    
    res.json({
      matches,
      userSkills
    });
  } catch (error) {
    console.error('Get job matches error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  getJobMatches
};
