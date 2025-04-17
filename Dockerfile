###############################
# Builder Stage
###############################
FROM node:16-alpine AS builder

WORKDIR /app

# Install Corepack and build tools
RUN npm install --global corepack@latest
RUN apk --no-cache add python3 py3-setuptools build-base

# Copy extensions
COPY ./extensions /app/extensions

###############################
# Final Stage
###############################
FROM directus/directus:latest

WORKDIR /directus

# Switch to root to install tools and set permissions
USER root

# Enable Corepack
RUN corepack enable

# Install jq and curl for start.sh
RUN apk add --no-cache jq curl

# Copy built extensions from builder stage
COPY --from=builder --chown=node:node /app/extensions /directus/extensions

# Copy templates and both startup scripts
COPY ./templates /directus/templates
COPY ./scripts/start.sh /directus/start.sh
COPY ./scripts/start.bat /directus/start.bat

# Make shell script executable
RUN chmod +x /directus/start.sh

# Debug: Show files are present (optional)
# RUN echo "📁 Contents of /directus:" && ls -al /directus
# RUN echo "📄 Contents of start.sh:" && cat /directus/start.sh

# Drop back to non-root user
USER node

# Start container using the Linux shell script
CMD ["sh", "/directus/start.sh"]

