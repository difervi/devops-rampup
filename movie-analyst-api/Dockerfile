# Multi-stage Dockerfile for the backend (movie-analyst-api)
FROM node:18-alpine AS build
WORKDIR /usr/src/app

# Copy package files and install production deps
COPY package*.json ./
RUN npm install --omit=dev

# Copy app source
COPY . .

# Runtime image
FROM node:18-alpine
WORKDIR /usr/src/app
COPY --from=build /usr/src/app /usr/src/app

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# Use node server.js directly because the project's start script uses Windows 'SET' syntax
CMD ["node", "server.js"]
