# Cleanup unused artifacts

This document explains how to safely remove a small set of non-source artifacts from the repository root.

Files targeted:

- `AWSSetup1.png`
- `AWSSetup2.png`
- `AWSSetup3.png`
- `movie-analyst-api;C`

What the provided scripts do

- `scripts/cleanup-unused.ps1` — PowerShell script for Windows. It moves the files (if present) into `backup-unused` and prints a summary. It prompts before acting.
- `scripts/cleanup-unused.sh` — Bash equivalent (for Git Bash, WSL, macOS, Linux).

Safe workflow

1. From the repository root run the appropriate script and type `YES` to confirm.
2. Inspect the `backup-unused` folder and verify contents.
3. Run `git status --short` and check the files that changed.
4. If everything looks good, stage and commit:

   git add -A
   git commit -m "chore: remove unused artifacts"

5. If you have your upstream/fork remotes set up, push the branch. For example (replace URL with your fork):

   git remote rename origin upstream
   git remote add origin git@github.com:<you>/<your-repo>.git
   git push -u origin infra/initial-structure

Notes

- The scripts do not delete files permanently; they move them into `backup-unused` so you can recover if needed.
- If you want the assistant to commit the changes for you, grant explicit permission and ensure the remote is set to your fork (the assistant will not push to the original project).
