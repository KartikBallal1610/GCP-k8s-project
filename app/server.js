const http = require('http');

const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || 'v1.0.0';

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', version: VERSION }));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Hello from GKE</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
               display: flex; flex-direction: column; align-items: center;
               justify-content: center; min-height: 100vh; margin: 0;
               background: #f0f4f8; color: #1a202c; }
        .card { background: white; border-radius: 12px; padding: 40px 60px;
                box-shadow: 0 4px 20px rgba(0,0,0,0.08); text-align: center; }
        h1 { font-size: 2.5rem; margin: 0 0 8px; color: #4F46E5; }
        p  { font-size: 1rem; color: #718096; margin: 4px 0; }
        .badge { display: inline-block; background: #EEF2FF; color: #4F46E5;
                 padding: 4px 12px; border-radius: 999px; font-size: 0.8rem;
                 margin-top: 16px; }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>Hello, World!</h1>
        <p>Running on <strong>Google Kubernetes Engine</strong></p>
        <p>Deployed automatically via GitHub Actions</p>
        <span class="badge">${VERSION}</span>
      </div>
    </body>
    </html>
  `);
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
