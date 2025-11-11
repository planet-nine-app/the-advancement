#!/bin/bash

# Start Glyphenge for Docker test environment (Base 1)
# Runs on port 5125 to match allyabase-base1 container port mapping

echo "🚀 Starting Glyphenge for Docker test environment..."
echo "   Glyphenge Port: 5125"
echo "   BDO Port (Docker): 5114"
echo ""
echo "Note: Clients construct URLs based on their own environment,"
echo "so we only need to set the PORT here."

PORT=5125 node server.js
