# Use official Node.js image for React development
FROM node:18

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose React development server port
EXPOSE 3000

# Start the React app in development mode with hot reload
CMD ["npm", "run", "dev", "--", "--host"]
