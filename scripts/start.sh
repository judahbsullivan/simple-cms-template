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

# Start Directus in the background
echo "🚀 Starting Directus..."
npx directus start &
DIRECTUS_PID=$!

# Wait for Directus to be ready
echo "⏳ Waiting for Directus to be ready..."
# until curl -s http://localhost:8055/server/health | grep '"status":"ok"' >/dev/null; do
until curl -s http://localhost:8055/server/ping | grep -q "pong"; do
	sleep 2
done

echo "✅ Directus is ready."

# Apply the local template using admin email and password
echo "📦 Applying template..."

# npx directus-template-cli@latest apply -p --directusUrl="http://localhost:8055" --userEmail="admin@example.com" --userPassword="admin" --templateLocation="./templates" --templateType="local"
npx directus-template-cli@latest apply -p --directusUrl="http://localhost:8055" --userEmail="${ADMIN_EMAIL}" --userPassword="${ADMIN_PASSWORD}" --templateLocation="./templates" --templateType="local"
echo "🎉 Template applied successfully."

# Wait for the Directus process to finish
wait $DIRECTUS_PID
