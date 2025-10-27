# Multi-stage Dockerfile for a Node.js app
# Stage 1: install dependencies
FROM node:18-alpine AS build
WORKDIR /usr/src/app

# Install production dependencies only
COPY package*.json ./
RUN npm install --omit=dev

# Copy app source
COPY . .

# Stage 2: runtime
FROM node:18-alpine
WORKDIR /usr/src/app
COPY --from=build /usr/src/app /usr/src/app

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# Default start command - adjust if your project uses a different start script
CMD ["npm", "start"]
