# Job Matching API (Backend)

This is a Node.js/Express backend for a job-matching platform with JWT authentication, MongoDB for storage, and Redis for caching (optional).

## Features
- REST API for job postings, applications, and job matching
- JWT authentication and role-based access
- Rate limiting (users can apply for up to 5 jobs per hour)
- AI-based job matching (skill overlap)
- Pagination, filtering, and caching for job listings
- Jest tests for core endpoints

## Setup
1. Copy `.env.example` to `.env` and fill in your values.
2. Install dependencies:
   ```sh
   npm install
   ```
3. Start MongoDB (and Redis if using caching).
4. Run the server:
   ```sh
   npm run dev
   ```
5. Run tests:
   ```sh
   npm test
   ```

## API Endpoints
- `POST /api/jobs` — Create a new job (employers only)
- `GET /api/jobs` — List jobs (paginated, filterable)
- `POST /api/apply` — Apply for a job (jobseekers only, rate-limited)
- `GET /api/matches/:userId` — Get job matches for a user (AI-based)

## Notes
- Uses in-memory rate limiting and caching by default (Redis recommended for production)
- See source for detailed field requirements and response formats
