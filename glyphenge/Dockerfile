FROM node:22.14.0

WORKDIR /usr/src/app

# Clone the-advancement repo to get linkhub
RUN git clone https://github.com/planet-nine-app/the-advancement.git

# Install dependencies
WORKDIR /usr/src/app/the-advancement/linkhub
RUN npm install

# Expose LinkHub port
EXPOSE 3010

# Set environment variables
ENV PORT=3010
ENV FOUNT_BASE_URL=http://localhost:3004/

# Start LinkHub
CMD ["node", "server.js"]
