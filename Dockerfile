###############################
# Builder Stage
###############################
FROM oven/bun:1.1.13-alpine AS builder

WORKDIR /app/extensions

# Install build tools if needed for native modules
RUN apk add --no-cache python3 py3-setuptools build-base curl

# Copy package files first
COPY ./extensions/package.json ./extensions/bun.lockb* ./

# Install dependencies using Bun
RUN bun install

# Copy the rest of the extension source code
COPY ./extensions .

# Run your custom build script via bun
RUN bun run build-extensions


###############################
# Final Stage
###############################
FROM directus/directus:latest

WORKDIR /directus

# Become root to install tools and adjust file permissions
USER root

# Install tools used in startup script
RUN apk add --no-cache jq curl

# Copy the built extensions over and fix ownership
COPY --from=builder --chown=node:node /app/extensions /directus/extensions

# Copy templates and entry scripts
COPY ./templates /directus/templates
COPY ./scripts/start.sh /directus/start.sh
COPY ./scripts/start.bat /directus/start.bat

# Make the start.sh script executable
RUN chmod +x /directus/start.sh

# Drop to node user
USER node

# Start using the custom entrypoint
CMD ["sh", "/directus/start.sh"]

