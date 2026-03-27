#!/usr/bin/env node
/**
 * Ralph Kanban Server - serves prd.json as API + static kanban UI
 * Usage: node server.js [port]
 * No npm install needed — uses only built-in Node.js modules
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.argv[2] || 3731;
const PRD_FILE = path.join(__dirname, '..', 'prd.json');
const PROGRESS_FILE = path.join(__dirname, '..', 'progress.txt');
const INDEX_FILE = path.join(__dirname, 'index.html');

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');

  // API: GET /api/prd
  if (url.pathname === '/api/prd') {
    try {
      if (!fs.existsSync(PRD_FILE)) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'prd.json not found', hint: 'Create scripts/ralph/prd.json to get started' }));
        return;
      }
      const data = JSON.parse(fs.readFileSync(PRD_FILE, 'utf8'));
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(data));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: e.message }));
    }
    return;
  }

  // API: GET /api/progress
  if (url.pathname === '/api/progress') {
    try {
      const text = fs.existsSync(PROGRESS_FILE)
        ? fs.readFileSync(PROGRESS_FILE, 'utf8')
        : '(no progress.txt yet)';
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end(text);
    } catch (e) {
      res.writeHead(500);
      res.end(e.message);
    }
    return;
  }

  // Static: serve index.html for /
  const filePath = url.pathname === '/' ? INDEX_FILE : path.join(__dirname, url.pathname);
  const ext = path.extname(filePath);

  try {
    const content = fs.readFileSync(filePath);
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'text/plain' });
    res.end(content);
  } catch {
    // fallback to index.html
    try {
      const html = fs.readFileSync(INDEX_FILE, 'utf8');
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(html);
    } catch {
      res.writeHead(404);
      res.end('Not found');
    }
  }
});

server.listen(PORT, () => {
  console.log(`\n🎯  Ralph Kanban running at: http://localhost:${PORT}\n`);
  console.log(`    PRD file:      ${PRD_FILE}`);
  console.log(`    Progress file: ${PROGRESS_FILE}`);
  console.log(`\n    Ctrl+C to stop\n`);
});
