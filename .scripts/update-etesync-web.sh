#!/bin/bash
# Update script for etesync-web
set -e

echo "Stopping etesync-web service..."
systemctl --user stop etesync-web.service

echo "Updating repository..."
cd ~/.local/lib/etesync-web
git pull origin master

echo "Installing dependencies..."
npm install

echo "Building with custom API path..."
NODE_OPTIONS=--openssl-legacy-provider REACT_APP_DEFAULT_API_PATH=https://etebase.rolandoahuja.com npm run build

echo "Starting service..."
systemctl --user start etesync-web.service

echo "✓ Update complete!"
systemctl --user status etesync-web.service
