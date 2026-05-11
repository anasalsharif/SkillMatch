# SkillMatch Platform

SkillMatch is a capstone web application for skill-based recruitment, candidate matching, volunteer/job discovery, and freelance opportunities.

The defended scope is the web application:

- Flutter Web frontend
- Node.js/Express backend
- MongoDB Atlas database through Mongoose
- Google Cloud Storage and Vision OCR for CV processing
- Deterministic fallback matching with optional OpenAI-compatible AI extraction/scoring
- Socket.IO chat and role-based workflows for job seekers, organizations, freelancers, and admins

## Repository Structure

```text
SkillMatch/
├─ skillmatch-backend-main/           # Express API, MongoDB models, matching, OCR/AI pipeline
├─ skillmatch-frontend-main/skillmatch-web/ # Flutter Web app
├─ docs/                              # Report draft/source notes
├─ defense-prep/                      # Presentation and discussion materials
├─ RUNBOOK.md                         # Local setup and demo instructions
└─ run-skillmatch.ps1                 # Windows helper to start backend + web demo
```

## Quick Start

Copy the environment templates first:

```powershell
Copy-Item skillmatch-backend-main\.env.example skillmatch-backend-main\.env
Copy-Item skillmatch-frontend-main\skillmatch-web\api.env.example skillmatch-frontend-main\skillmatch-web\api.env
```

Then edit the local files with your own MongoDB, Google Cloud, Firebase, email, and AI provider values.

Start the full local web demo from the repository root:

```powershell
.\run-skillmatch.ps1
```

The app runs at:

- Backend API: `http://localhost:5000`
- Flutter Web: `http://localhost:5050`

For detailed setup, demo accounts, cloud configuration, and troubleshooting, see [RUNBOOK.md](RUNBOOK.md).

## Demo Data

After configuring MongoDB Atlas, seed the capstone demo scenario:

```powershell
cd skillmatch-backend-main
npm install
npm run seed:demo
```

The seeded scenario includes a job seeker profile, organization jobs, applications, match records, freelance posts, chat data, and admin-visible statistics.

## Security Notes

Real credentials are intentionally excluded from Git. Keep these files local:

- `skillmatch-backend-main/.env`
- `skillmatch-frontend-main/skillmatch-web/api.env`
- Firebase service account JSON files
- Google Cloud service account JSON files
- Android `google-services.json`
- iOS `GoogleService-Info.plist`

Use the `.example` files as templates when setting up a new machine.
