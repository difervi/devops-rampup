Quick Docker build & push to ECR

Prerequisites:
- Docker Desktop running (or Docker available in WSL)
- AWS CLI configured with permissions to ECR

Build & push (PowerShell example):

```powershell
# Authenticate to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 439391123226.dkr.ecr.us-east-1.amazonaws.com

# Build image (run from repo root where Dockerfile is)
docker build -t movie-analyst:latest .

# Tag image for ECR (replace account id if needed)
docker tag movie-analyst:latest 439391123226.dkr.ecr.us-east-1.amazonaws.com/movie-analyst:latest

# Push image
docker push 439391123226.dkr.ecr.us-east-1.amazonaws.com/movie-analyst:latest
```

If you use WSL, run the same commands inside WSL. If Docker Desktop WSL integration is enabled, the Docker CLI will use the same daemon.

If your app uses a different start command, update the `CMD` in the Dockerfile or add a `start` script to `package.json`.
