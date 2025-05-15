const mongoose = require('mongoose');
const { MongoClient } = require('mongodb');

// MongoDB connection
let cachedDb = null;

async function connectToDatabase() {
  if (cachedDb) {
    return cachedDb;
  }

  const client = await MongoClient.connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });

  const db = client.db();
  cachedDb = db;
  return db;
}

// Handler function
exports.handler = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;
  
  try {
    // Parse query parameters
    const queryParams = event.queryStringParameters || {};
    const userId = queryParams.userId;
    
    if (!userId) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({ error: 'userId is required' }),
      };
    }
    
    // Connect to MongoDB
    const db = await connectToDatabase();
    
    // Get user skills
    const user = await db.collection('users').findOne({ _id: mongoose.Types.ObjectId(userId) });
    
    if (!user) {
      return {
        statusCode: 404,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({ error: 'User not found' }),
      };
    }
    
    const userSkills = user.skills || [];
    
    if (userSkills.length === 0) {
      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({ matches: [] }),
      };
    }
    
    // Find matching jobs
    const matchingJobs = await db.collection('jobs')
      .find({
        'skills': { $in: userSkills },
        'status': 'active',
      })
      .project({
        _id: 1,
        title: 1,
        company: 1,
        location: 1,
        skills: 1,
        description: 1,
        createdAt: 1,
      })
      .sort({ createdAt: -1 })
      .limit(20)
      .toArray();
    
    // Calculate match score for each job
    const jobMatches = matchingJobs.map(job => {
      const jobSkills = job.skills || [];
      const matchingSkillsCount = jobSkills.filter(skill => userSkills.includes(skill)).length;
      const matchScore = (matchingSkillsCount / jobSkills.length) * 100;
      
      return {
        ...job,
        matchScore: Math.round(matchScore),
      };
    });
    
    // Sort by match score (highest first)
    jobMatches.sort((a, b) => b.matchScore - a.matchScore);
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({ matches: jobMatches }),
    };
    
  } catch (error) {
    console.error('Error:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};
