###############################
# Builder Stage
###############################
FROM node:18-alpine AS builder

WORKDIR /app

# Install build tools for native dependencies if needed
RUN apk add --no-cache python3 py3-setuptools build-base curl

# Copy extensions source code
COPY ./extensions /app/extensions

# If you have package.json inside extensions and want to install dependencies & build
WORKDIR /app/extensions

RUN npm install
RUN npm run build

###############################
# Final Stage
###############################
FROM directus/directus:latest

WORKDIR /directus

# Switch to root to install utilities and set permissions
USER root

# Install jq and curl needed by your start.sh script
RUN apk add --no-cache jq curl

# Copy built extensions from builder stage, set ownership to node user
COPY --from=builder --chown=node:node /app/extensions /directus/extensions

# Copy templates and startup scripts
COPY ./templates /directus/templates
COPY ./scripts/start.sh /directus/start.sh
COPY ./scripts/start.bat /directus/start.bat

# Make shell script executable
RUN chmod +x /directus/start.sh

# Drop back to non-root user
USER node

# Start container using the Linux shell script
CMD ["sh", "/directus/start.sh"]

