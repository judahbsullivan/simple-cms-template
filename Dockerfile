###############################
# Builder Stage
###############################
FROM node:16-alpine AS builder

WORKDIR /app

###############################
RUN npm install --global corepack@latest
RUN apk --no-cache add python3 py3-setuptools build-base
# Copy the extensions folder (built extensions from local machine)
#
COPY ./extensions /app/extensions


###############################
# Final Stage
###############################
FROM directus/directus:latest

WORKDIR /directus

# Enable Corepack and install the Directus extensions SDK as before
USER root
RUN corepack enable 

# Copy built extensions from the builder stage
COPY --from=builder --chown=node:node /app/extensions /directus/extensions

# Copy remaining assets as needed
COPY ./templates /directus/templates

# Switch to non-root user
USER node

# Start Directus on container start
CMD ["node", "/directus/cli.js", "start"]


