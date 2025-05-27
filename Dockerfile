###############################
# Builder Stage
###############################
FROM oven/bun:1.1.13-alpine AS builder

# Set the working directory to the project root
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache python3 py3-setuptools build-base curl

# Copy root-level package files
COPY ./package.json ./bun.lockb* ./

# Install dependencies
RUN bun install

# Copy the rest of the project files (including extensions, scripts, etc.)
COPY . .

# Run the extension build script (defined in root package.json)
RUN bun run build-extensions


###############################
# Final Stage
###############################
FROM directus/directus:latest

WORKDIR /directus

USER root

RUN apk add --no-cache jq curl

# Copy built extensions from builder (adjust if your build output goes elsewhere)
COPY --from=builder --chown=node:node /app/extensions /directus/extensions

# Copy templates and start scripts
COPY ./templates /directus/templates
COPY ./scripts/start.sh /directus/start.sh
COPY ./scripts/start.bat /directus/start.bat

RUN chmod +x /directus/start.sh

USER node

CMD ["sh", "/directus/start.sh"]

