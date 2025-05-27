###############################
# Builder Stage
###############################
FROM node:16-alpine AS builder

WORKDIR /app

# Install Corepack and build tools
RUN npm install --global corepack@latest
RUN apk --no-cache add python3 py3-setuptools build-base curl

# Enable Corepack and install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy package.json and lockfile if you have them (optional)
# COPY package.json pnpm-lock.yaml* ./

# If you have a package.json for extensions, uncomment above and run:
# RUN pnpm install --frozen-lockfile

# Or install your extensions directly (replace with your actual extensions)
RUN pnpm add @directus-labs/seo-plugin directus-extension-ai-operations

# Copy your extensions source (if any raw code to copy)
COPY ./extensions /app/extensions

# Build your extensions if needed (example, adjust as per your extensions)
# RUN pnpm run build

###############################
# Final Stage
###############################
FROM directus/directus:latest

WORKDIR /directus

# Switch to root to install extra tools and set permissions
USER root

# Enable Corepack
RUN corepack enable

# Install tools needed by your start scripts
RUN apk add --no-cache jq curl

# Copy built extensions from builder stage, with correct ownership
COPY --from=builder --chown=node:node /app/extensions /directus/extensions

# Copy templates and startup scripts
COPY ./templates /directus/templates
COPY ./scripts/start.sh /directus/start.sh
COPY ./scripts/start.bat /directus/start.bat

# Make the start script executable
RUN chmod +x /directus/start.sh

# Drop back to non-root user for security
USER node

# Start Directus using your custom shell script
CMD ["sh", "/directus/start.sh"]

