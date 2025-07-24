# Use official Node image to build
FROM node:18 AS builder
WORKDIR /app

# Copy package files and install dependencies first
# This layer is only rebuilt if package.json or package-lock.json changes
COPY package.json package-lock.json ./
RUN npm install

# Copy the rest of the application source code
COPY . .

# Build the application
RUN npm run build

# Use nginx to serve the static site
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]