import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 3000;

// Determine dist path (different in dev vs production/docker)
const distPath =
  process.env.NODE_ENV === 'production'
    ? path.join(__dirname, '../dist') // In Docker: dist-server/../dist = dist
    : path.join(__dirname, 'dist'); // In dev: ./dist

const app = express();
const httpServer = createServer(app);

const io = new Server(httpServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

// Serve static files from dist
app.use(express.static(distPath));

// Store connected clients
let clientA: string | null = null;
let clientB: string | null = null;

io.on('connection', (socket) => {
  console.log('✓ Client connected:', socket.id);

  // Register client
  socket.on('register', (clientName: string) => {
    if (clientName === 'clientA' && !clientA) {
      clientA = socket.id;
      socket.emit('registered', { name: 'clientA', success: true });
      console.log('✓ Client A registered:', socket.id);
    } else if (clientName === 'clientB' && !clientB) {
      clientB = socket.id;
      socket.emit('registered', { name: 'clientB', success: true });
      console.log('✓ Client B registered:', socket.id);
    } else {
      socket.emit('registered', {
        success: false,
        message: 'Client name already taken or invalid',
      });
    }
  });

  // Handle bell ring
  socket.on('ring', () => {
    console.log(`📞 ${socket.id} rang the bell`);

    // Send to the other client
    if (socket.id === clientA && clientB) {
      io.to(clientB).emit('bell-rung');
    } else if (socket.id === clientB && clientA) {
      io.to(clientA).emit('bell-rung');
    }
  });

  // Handle ping for latency measurement
  socket.on('ping', (callback) => {
    callback();
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    if (socket.id === clientA) {
      clientA = null;
      console.log('✗ Client A disconnected');
    } else if (socket.id === clientB) {
      clientB = null;
      console.log('✗ Client B disconnected');
    }
  });
});

// Fallback to index.html for SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(distPath, 'index.html'));
});

httpServer.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════╗
║  🔔 Call Me - Server Running           ║
║  http://localhost:${PORT}           ║
║  WebSocket ready                       ║
╚════════════════════════════════════════╝
  `);
});
