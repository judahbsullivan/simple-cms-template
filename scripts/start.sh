#!/bin/bash
set -e

# Function to output error messages
error_exit() {
	echo "❌ $1"
	exit 1
}

# Check required environment variables
if [ -z "$ADMIN_EMAIL" ]; then
	error_exit "ADMIN_EMAIL environment variable is not set."
fi

if [ -z "$ADMIN_PASSWORD" ]; then
	error_exit "ADMIN_PASSWORD environment variable is not set."
fi

# Step 1: Bootstrap Directus BEFORE starting the server
echo "🛠️ Bootstrapping Directus (safe to skip if already done)..."
if npx directus bootstrap; then
	echo "✅ Directus bootstrap completed."
else
	echo "⚠️ Bootstrap failed or already completed, continuing..."
fi

# Step 2: Start Directus in the background
echo "🚀 Starting Directus..."
npx directus start &
DIRECTUS_PID=$!

# Step 3: Wait for Directus to be ready
echo "⏳ Waiting for Directus to be ready..."
until curl -s http://localhost:8055/server/ping | grep -q "pong"; do
	sleep 2
done

echo "✅ Directus is ready."

# Step 4: Apply the local template using admin email and password
echo "📦 Applying template..."
npx directus-template-cli@latest apply -p --directusUrl="http://localhost:8055" --userEmail="${ADMIN_EMAIL}" --userPassword="${ADMIN_PASSWORD}" --templateLocation="./templates" --templateType="local"

echo "🎉 Template applied successfully."

# Step 5: Wait for the Directus process to finish
wait $DIRECTUS_PID
