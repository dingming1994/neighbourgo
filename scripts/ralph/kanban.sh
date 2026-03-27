#!/bin/bash
# Start Ralph Kanban dashboard
# Usage: ./scripts/ralph/kanban.sh [port]

PORT=${1:-3731}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🏘️  Starting Ralph Kanban for NeighbourGo..."
node "$SCRIPT_DIR/kanban/server.js" $PORT &
SERVER_PID=$!

sleep 0.5
open "http://localhost:$PORT" 2>/dev/null || xdg-open "http://localhost:$PORT" 2>/dev/null || true

echo "   PID: $SERVER_PID  (kill with: kill $SERVER_PID)"
echo ""
wait $SERVER_PID
