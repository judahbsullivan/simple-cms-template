###############################
# Builder Stage
###############################
FROM node:18-alpine AS builder

WORKDIR /app

# Install build tools (optional, remove if not needed)
RUN apk add --no-cache python3 py3-setuptools build-base curl

# Copy extensions folder as-is, no npm install/build because no package.json
COPY ./extensions /app/extensions

###############################
# Final Stage
###############################
FROM directus/directus:latest

WORKDIR /directus

# Switch to root for installing tools and permissions
USER root

# Install jq and curl needed by start.sh
RUN apk add --no-cache jq curl

# Copy extensions from builder to final image, set ownership
COPY --from=builder --chown=node:node /app/extensions /directus/extensions

# Copy templates and start scripts
COPY ./templates /directus/templates
COPY ./scripts/start.sh /directus/start.sh
COPY ./scripts/start.bat /directus/start.bat

# Make start.sh executable
RUN chmod +x /directus/start.sh

# Drop to non-root user
USER node

CMD ["sh", "/directus/start.sh"]

