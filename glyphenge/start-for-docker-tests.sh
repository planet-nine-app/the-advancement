#!/bin/bash

# Start Glyphenge for Docker test environment (Base 1)
# Runs on port 5125 to match allyabase-base1 container port mapping

echo "🚀 Starting Glyphenge for Docker test environment..."
echo "   Glyphenge Port: 5125"
echo "   BDO Service: http://localhost:5114"
echo ""
echo "Note: Clients construct URLs, but server needs to know"
echo "which BDO service to fetch from."

PORT=5125 BDO_BASE_URL=http://localhost:5114 node server.js
