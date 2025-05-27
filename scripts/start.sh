#!/usr/bin/env bash
set -e

# ─── Detect whether to use bunx or npx ───────────────────────────────────────
if command -v bun >/dev/null 2>&1; then
  RUNNER="bunx"
  echo "🐰 Using Bun (bunx) to run Directus CLI"
else
  RUNNER="npx"
  echo "📦 Using npx to run Directus CLI"
fi

# ─── Validate required environment variables ────────────────────────────────
: "${ADMIN_EMAIL:?❌ ADMIN_EMAIL environment variable is not set.}"
: "${ADMIN_PASSWORD:?❌ ADMIN_PASSWORD environment variable is not set.}"

# ─── 1) Bootstrap Directus (idempotent) ────────────────────────────────────
echo "🛠️  Bootstrapping Directus (safe to skip if already done)..."
if $RUNNER directus bootstrap; then
  echo "✅ Bootstrap completed."
else
  echo "⚠️  Bootstrap step failed or was already run, continuing..."
fi

# ─── 2) Start Directus in background ───────────────────────────────────────
echo "🚀 Starting Directus..."
$RUNNER directus start &
DIRECTUS_PID=$!

# ─── 3) Wait for Directus to respond ──────────────────────────────────────
echo "⏳ Waiting for Directus to be ready at http://localhost:8055..."
until curl -s http://localhost:8055/server/ping | grep -q pong; do
  sleep 2
done
echo "✅ Directus is up!"

# ─── 4) Apply your local template ──────────────────────────────────────────
echo "📦 Applying local template from ./templates..."
$RUNNER directus-template-cli@latest apply \
  -p \
  --directusUrl="http://localhost:8055" \
  --userEmail="$ADMIN_EMAIL" \
  --userPassword="$ADMIN_PASSWORD" \
  --templateLocation="./templates" \
  --templateType="local"

echo "🎉 Template applied successfully."

# ─── 5) Tail off into the Directus process ─────────────────────────────────
wait $DIRECTUS_PID
