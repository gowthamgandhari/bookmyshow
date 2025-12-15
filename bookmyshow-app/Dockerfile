# STEP 1: Use Node.js 18 as the base image
FROM node:18

# STEP 2: Set working directory inside the container
WORKDIR /app

# STEP 2.1: Set environment variable to fix OpenSSL issues
ENV NODE_OPTIONS=--openssl-legacy-provider

# STEP 3: Copy package files for dependency installation
COPY package.json package-lock.json ./

# STEP 4: Install compatible PostCSS versions (fixes build issues)
RUN npm install postcss@8.4.21 postcss-safe-parser@6.0.0 --legacy-peer-deps

# STEP 5: Install all project dependencies
RUN npm install

# STEP 6: Copy the complete application source code
COPY . .

# STEP 7: Build the React application (production build)
RUN npm run build

# STEP 8: Install a lightweight static server to serve build files
RUN npm install -g serve

# STEP 9: Set environment variables for container runtime
ENV PORT=3000
ENV HOST=0.0.0.0
ENV BROWSER=none

# STEP 10: Expose the application port
EXPOSE 3000

# STEP 11: Start the production server
CMD ["serve", "-s", "build", "-l", "3000"]
