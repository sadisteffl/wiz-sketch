# Stage 1: Build the React app
FROM node:18 AS builder
WORKDIR /app

# Copy package files and install dependencies
# Using npm ci for faster, more reliable builds in CI/CD environments
COPY package*.json ./
RUN npm ci

# Copy the rest of the application source code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve the app with NGINX
FROM nginx:1.25-alpine
# Copy the built assets from the 'builder' stage
COPY --from=builder /app/build /usr/share/nginx/html
# Expose port 80 and start nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]