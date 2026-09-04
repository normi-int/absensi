#!/bin/bash
# Run this from inside your absensi project folder (the one with .git).
# Sets up GitHub Pages deployment: subpath config + gh-pages package + deploy.
set -e

cat > vite.config.js << 'ABSENSI_EOF'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // Served from https://normi-int.github.io/absensi/ via GitHub Pages,
  // so all asset URLs need this subpath prefix (not needed for local dev).
  base: '/absensi/',
})
ABSENSI_EOF

# Update App.jsx: add basename="/absensi" to BrowserRouter (only if not already there)
if ! grep -q 'basename="/absensi"' src/App.jsx; then
  sed -i.bak 's/<BrowserRouter>/<BrowserRouter basename="\/absensi">/' src/App.jsx
  rm -f src/App.jsx.bak
fi

# Update package.json: add deploy script + gh-pages devDependency
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts.deploy = 'vite build && gh-pages -d dist';
pkg.devDependencies['gh-pages'] = '^6.3.0';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

echo "Files updated. Installing gh-pages package..."
npm install

echo ""
echo "Committing..."
git add -A
git commit -m "Add GitHub Pages deployment (base path + gh-pages script)"
git push

echo ""
echo "Now deploying to GitHub Pages (this builds and pushes to the gh-pages branch)..."
npm run deploy

echo ""
echo "Done! Your app will be live shortly at:"
echo "https://normi-int.github.io/absensi/"
echo ""
echo "One more manual step (first time only):"
echo "Go to https://github.com/normi-int/absensi/settings/pages"
echo "Under 'Build and deployment' -> Source, select 'Deploy from a branch'"
echo "Branch: gh-pages, folder: / (root) -> Save"
