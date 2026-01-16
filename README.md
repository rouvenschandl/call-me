# 📞 Call Me

Simple real-time calling app that lets two clients ring each other. Built with Vue 3, Socket.IO, and TypeScript.

## ✨ Features

- **Two Clients**: Client A and Client B can call each other
- **Real-time**: Instant notifications via WebSocket
- **Visual Feedback**: Screen blinking and favicon animation on incoming calls
- **Keyboard Support**: Press `SPACE` to call
- **Ping Display**: Real-time connection latency
- **Auto-reconnect**: Handles disconnections gracefully
- **Multi-arch Docker**: Supports amd64 and arm64

## � Why Visual Intercom?

This is a **visual intercom system without audio**. Perfect for:
- Getting attention across offices/rooms when audio is unavailable
- Silent notifications in quiet environments (libraries, studios, etc.)
- Quick visual signals - someone needs to talk to you NOW
- Lightweight & fast - no audio codec overhead
- Works on any device with a browser

Just a quick "ring" to let someone know: *Hey, I need you!* 📞

## 🚀 Quick Start

### Using Docker

```bash
docker run -p 3000:3000 ghcr.io/rouvenschandl/call-me:latest
```

Then open http://your-ip:3000 in two different browsers/tabs and select Client A and Client B.

### Development

```bash
# Install dependencies
pnpm install

# Run dev server (client)
pnpm dev

# Run server (in another terminal)
pnpm dev:server
```

Open http://localhost:5173

## 🏗️ Build

```bash
# Build client and server
pnpm build

# Start production server
pnpm start
```

## 🐳 Docker

```bash
# Build
docker build -t call-me .

# Run
docker run -p 3000:3000 call-me
```

## 🛠️ Tech Stack

- **Frontend**: Vue 3, TypeScript, Vite
- **Backend**: Node.js, Express, Socket.IO
- **Deployment**: Docker, GitHub Actions, GHCR

## 📦 Deployment

Push to `main` branch triggers automatic build and deployment to GitHub Container Registry.

```bash
docker pull ghcr.io/rouvenschandl/call-me:latest
```

## 🎮 Usage

1. Open the app in two different browsers/devices
2. Select **Client A** on one device
3. Select **Client B** on the other device
4. Click **CALL** button or press **SPACE** to ring the other client
5. The other client will see a blinking red screen and notification

## 📝 License

MIT © [Rouven Schandl](https://github.com/rouvenschandl)
