###############################
# Builder Stage
###############################
FROM node:18-alpine AS builder

WORKDIR /app/extensions

# Install build tools for native modules (e.g., for bcrypt, sqlite, etc.)
RUN apk add --no-cache python3 py3-setuptools build-base curl

# Copy package files first (for better Docker caching)
COPY ./extensions/package.json ./extensions/package-lock.json* ./

# Install dependencies
RUN npm install

# Copy the rest of the extension source code
COPY ./extensions .

# Run the build script (assumes "build" exists in package.json)
RUN npm run build


###############################
# Final Stage
###############################
FROM directus/directus:latest

WORKDIR /directus

USER root

# Install jq and curl needed by start.sh
RUN apk add --no-cache jq curl

# Copy built extensions from builder and set proper ownership
COPY --from=builder --chown=node:node /app/extensions /directus/extensions

# Copy templates and start scripts
COPY ./templates /directus/templates
COPY ./scripts/start.sh /directus/start.sh
COPY ./scripts/start.bat /directus/start.bat

# Make start.sh executable
RUN chmod +x /directus/start.sh

# Drop back to non-root user
USER node

# Start the custom entry script
CMD ["sh", "/directus/start.sh"]

