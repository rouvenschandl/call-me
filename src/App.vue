<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue';
import { io, Socket } from 'socket.io-client';

const clientName = ref<'clientA' | 'clientB'>('clientA');
const registered = ref(false);
const isRinging = ref(false);
const isCallTimeout = ref(false);
const timeoutCounter = ref(5);
const isConnected = ref(false);
const registrationError = ref('');
const ping = ref(0);
const originalFaviconHref = ref<string | null>(null);
const hadOriginalFavicon = ref(false);
const originalTitle = ref('');
const blinkInterval = ref<ReturnType<typeof setInterval> | null>(null);
const cleanupInterval = ref<ReturnType<typeof setInterval> | null>(null);
let socket: Socket;
let pingInterval: ReturnType<typeof setInterval>;

const containerClass = computed(() => ({
  ringing: isRinging.value,
}));

// Save client selection to localStorage
const saveClientChoice = (name: 'clientA' | 'clientB') => {
  localStorage.setItem('selectedClient', name);
};

// Load client selection from localStorage
const loadClientChoice = () => {
  const saved = localStorage.getItem('selectedClient');
  if (saved === 'clientA' || saved === 'clientB') {
    clientName.value = saved;
  }
};

// Watch for client name changes and reconnect
const changeClient = (newName: 'clientA' | 'clientB') => {
  if (newName !== clientName.value && isConnected.value) {
    // Disconnect from old client
    socket.disconnect();

    // Update client name
    clientName.value = newName;
    saveClientChoice(newName);
    registrationError.value = '';

    // Reconnect with new client
    setTimeout(() => {
      connect();
    }, 500);
  } else {
    clientName.value = newName;
    saveClientChoice(newName);
  }
};

// Measure ping/latency
const measurePing = () => {
  if (socket && isConnected.value) {
    const start = Date.now();
    socket.emit('ping', () => {
      ping.value = Date.now() - start;
    });
  }
};

const connect = () => {
  // Use current origin for connection (works in dev and production)
  // This allows connection from any device in the network
  const socketUrl =
    import.meta.env.DEV && import.meta.env.VITE_SERVER_URL
      ? import.meta.env.VITE_SERVER_URL
      : window.location.origin.replace(/:\d+$/, ':3000'); // Use current host but port 3000

  console.log('🔌 Connecting to:', socketUrl);

  socket = io(socketUrl, {
    transports: ['websocket', 'polling'],
  });

  socket.on('connect', () => {
    isConnected.value = true;
    registrationError.value = '';
    console.log('✓ Connected to server');

    // Start ping measurements every 3 seconds
    if (pingInterval) clearInterval(pingInterval);
    pingInterval = setInterval(measurePing, 3000);
    measurePing(); // Immediate first ping

    socket.emit('register', clientName.value);
  });

  socket.on('registered', (data: any) => {
    if (data.success) {
      registered.value = true;
      registrationError.value = '';
      console.log(`✓ Registered as ${clientName.value}`);
    } else {
      registered.value = false;
      registrationError.value = data.message || 'Registration failed';
      console.error('✗ Registration failed:', data.message);
      // Try to reconnect if registration failed
      setTimeout(() => {
        socket.emit('register', clientName.value);
      }, 1000);
    }
  });

  socket.on('bell-rung', () => {
    triggerRing();
  });

  socket.on('disconnect', () => {
    isConnected.value = false;
    registered.value = false;
    registrationError.value = '';
    if (pingInterval) clearInterval(pingInterval);
    console.log('✗ Disconnected from server');
  });
};

const ringBell = () => {
  if (socket && registered.value && !isCallTimeout.value) {
    socket.emit('ring');

    // Disable button for 5 seconds with countdown
    isCallTimeout.value = true;
    timeoutCounter.value = 5;

    const interval = setInterval(() => {
      timeoutCounter.value--;
      if (timeoutCounter.value <= 0) {
        clearInterval(interval);
        isCallTimeout.value = false;
        timeoutCounter.value = 5;
      }
    }, 1000);
  }
};

const getFaviconLink = () =>
  document.querySelector("link[rel='icon']") as HTMLLinkElement | null;

const setFavicon = (href: string) => {
  let link = document.getElementById(
    'dynamic-favicon'
  ) as HTMLLinkElement | null;
  if (!link) {
    link = document.createElement('link');
    link.rel = 'icon';
    link.type = 'image/png';
    link.sizes = '32x32';
    link.id = 'dynamic-favicon';
    document.head.appendChild(link);
  }
  link.href = href;
};

const removeDynamicFavicon = () => {
  const link = document.getElementById('dynamic-favicon');
  if (link) {
    link.remove();
  }
};

const restoreOriginalFavicon = () => {
  removeDynamicFavicon();
  if (hadOriginalFavicon.value && originalFaviconHref.value) {
    const link = getFaviconLink();
    if (link) {
      link.href = originalFaviconHref.value;
    } else {
      const newLink = document.createElement('link');
      newLink.rel = 'icon';
      newLink.href = originalFaviconHref.value;
      document.head.appendChild(newLink);
    }
  }
};

const createRedIcon = () => {
  const canvas = document.createElement('canvas');
  canvas.width = 32;
  canvas.height = 32;
  const ctx = canvas.getContext('2d');
  if (ctx) {
    ctx.fillStyle = '#ff0000';
    ctx.beginPath();
    ctx.arc(16, 16, 14, 0, Math.PI * 2);
    ctx.fill();
  }
  return canvas.toDataURL();
};

const createBlackIcon = () => {
  const canvas = document.createElement('canvas');
  canvas.width = 32;
  canvas.height = 32;
  const ctx = canvas.getContext('2d');
  if (ctx) {
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.arc(16, 16, 14, 0, Math.PI * 2);
    ctx.fill();
  }
  return canvas.toDataURL();
};

const createDefaultIcon = () => {
  const canvas = document.createElement('canvas');
  canvas.width = 32;
  canvas.height = 32;
  const ctx = canvas.getContext('2d');
  if (ctx) {
    ctx.fillStyle = '#111';
    ctx.beginPath();
    ctx.arc(16, 16, 14, 0, Math.PI * 2);
    ctx.fill();
  }
  return canvas.toDataURL();
};

const ensureBaseFavicon = () => {
  if (!originalFaviconHref.value) {
    const existing = getFaviconLink();
    if (existing?.href) {
      originalFaviconHref.value = existing.href;
      hadOriginalFavicon.value = true;
    } else {
      const icon = createDefaultIcon();
      const link = document.createElement('link');
      link.rel = 'icon';
      link.type = 'image/png';
      link.sizes = '32x32';
      link.href = icon;
      document.head.appendChild(link);
      originalFaviconHref.value = link.href;
      hadOriginalFavicon.value = true;
    }
  }
  if (!originalTitle.value) {
    originalTitle.value = document.title || 'call-me';
  }
};

const stopRinging = () => {
  if (blinkInterval.value) {
    clearInterval(blinkInterval.value);
    blinkInterval.value = null;
  }
  isRinging.value = false;
  restoreOriginalFavicon();
  if (!hadOriginalFavicon.value && !originalFaviconHref.value) {
    // fallback to default icon
    setFavicon('/favicon.ico');
  }
  document.title = originalTitle.value || 'call-me';
};

const triggerRing = () => {
  stopRinging();

  if (!originalFaviconHref.value) {
    const currentLink = getFaviconLink();
    if (currentLink?.href) {
      originalFaviconHref.value = currentLink.href;
      hadOriginalFavicon.value = true;
    } else {
      originalFaviconHref.value = '/favicon.ico';
      hadOriginalFavicon.value = false;
    }
  }
  if (!originalTitle.value) {
    originalTitle.value = document.title || 'call-me';
  }

  isRinging.value = true;

  let isBlinkingOn = true;
  blinkInterval.value = setInterval(() => {
    if (isBlinkingOn) {
      setFavicon(createRedIcon());
      document.title = '📞 INCOMING CALL!';
    } else {
      setFavicon(createBlackIcon());
      document.title = originalTitle.value || 'call-me';
    }
    isBlinkingOn = !isBlinkingOn;
  }, 250);

  setTimeout(() => {
    stopRinging();
  }, 5000);
};

// Handle keyboard shortcuts
const handleKeyPress = (event: KeyboardEvent) => {
  if (event.code === 'Space' && !event.repeat) {
    event.preventDefault();
    ringBell();
  }
};

// Update favicon dynamically when ringing
const updateFavicon = (ringing: boolean) => {
  if (!ringing) {
    stopRinging();
  }
};

// Watch isRinging and update favicon
watch(isRinging, (newVal) => {
  updateFavicon(newVal);
});

onMounted(() => {
  ensureBaseFavicon();
  // Load saved client choice
  loadClientChoice();
  // Connect to server
  connect();

  // Add keyboard listener
  window.addEventListener('keydown', handleKeyPress);

  // Cleanup interval: Remove favicon every second if NOT ringing
  cleanupInterval.value = setInterval(() => {
    if (!isRinging.value) {
      stopRinging();
    }
  }, 1000);
});

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleKeyPress);
  if (cleanupInterval.value) clearInterval(cleanupInterval.value);
  if (pingInterval) clearInterval(pingInterval);
  stopRinging();
  if (socket) {
    socket.disconnect();
  }
});
</script>

<template>
  <div :class="containerClass" class="container">
    <!-- Connection Indicator (Top Right) with Ping Tooltip -->
    <div
      class="connection-indicator"
      :class="{ connected: isConnected }"
      :title="isConnected ? `Ping: ${ping}ms` : 'No connection'"
    >
      <span class="dot"></span>
      <span class="label">{{ isConnected ? 'ONLINE' : 'OFFLINE' }}</span>
      <span v-if="isConnected" class="ping-info">{{ ping }}ms</span>
    </div>

    <!-- Client Selection (Top Left - Always Visible) -->
    <div class="client-selector">
      <button
        @click="changeClient('clientA')"
        class="client-button"
        :class="{ active: clientName === 'clientA' }"
      >
        A
      </button>
      <button
        @click="changeClient('clientB')"
        class="client-button"
        :class="{ active: clientName === 'clientB' }"
      >
        B
      </button>
    </div>

    <!-- Registration Error -->
    <div v-if="registrationError" class="error-message">
      ✗ {{ registrationError }}
    </div>

    <!-- Main App Area -->
    <div v-if="registered" class="app">
      <button @click="ringBell" class="call-button" :disabled="isCallTimeout">
        CALL
      </button>

      <div v-if="isCallTimeout" class="timeout-indicator">
        {{ timeoutCounter }}s
      </div>

      <!-- Spacebar hint -->
      <div class="spacebar-hint">Press <kbd>SPACE</kbd> to call</div>
    </div>

    <!-- Loading State -->
    <div v-if="!registered && isConnected" class="connecting">
      <div class="spinner"></div>
      <p>{{ clientName }}</p>
    </div>

    <!-- Footer: Version and Author -->
    <div class="footer">
      <span class="version">v0.1</span>
      <a href="https://github.com/rouvenschandl" target="_blank" class="author"
        >Rouven Schandl</a
      >
    </div>
  </div>
</template>

<style scoped>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

.container {
  width: 100vw;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #000;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
    'Helvetica Neue', Arial, sans-serif;
  transition: background-color 0.1s;
  position: relative;
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
}

.connection-indicator {
  position: fixed;
  top: 20px;
  right: 20px;
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.6rem 1rem;
  background: rgba(100, 100, 100, 0.3);
  border-radius: 20px;
  font-size: 0.75rem;
  color: #999;
  letter-spacing: 1px;
  font-weight: 600;
  transition: all 0.3s ease;
  z-index: 1000;
}

.connection-indicator.connected {
  background: rgba(0, 255, 0, 0.15);
  color: #00ff00;
}

.connection-indicator .dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #666;
  display: inline-block;
  transition: all 0.3s ease;
}

.connection-indicator.connected .dot {
  background: #00ff00;
  box-shadow: 0 0 10px #00ff00;
  animation: pulse-dot 1.5s infinite;
}

@keyframes pulse-dot {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.connection-indicator .ping-info {
  font-size: 0.7rem;
  color: #00ff00;
  margin-left: 0.3rem;
  font-weight: 700;
}

.error-message {
  position: fixed;
  top: 80px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 0, 0, 0.9);
  color: #fff;
  padding: 1rem 1.5rem;
  border-radius: 8px;
  font-size: 0.9rem;
  letter-spacing: 0.5px;
  font-weight: 600;
  box-shadow: 0 0 20px rgba(255, 0, 0, 0.5);
  z-index: 1000;
  max-width: 80%;
  text-align: center;
  animation: slideDown 0.3s ease;
}

@keyframes slideDown {
  from {
    transform: translateX(-50%) translateY(-20px);
    opacity: 0;
  }
  to {
    transform: translateX(-50%) translateY(0);
    opacity: 1;
  }
}

.client-selector {
  position: fixed;
  top: 20px;
  left: 20px;
  display: flex;
  gap: 0.8rem;
  z-index: 1000;
}

.client-button {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 2px solid #666;
  background: #111;
  color: #666;
  font-weight: 700;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.client-button:hover {
  border-color: #fff;
  color: #fff;
}

.client-button.active {
  background: #ff0000;
  border-color: #ff0000;
  color: #fff;
  box-shadow: 0 0 15px rgba(255, 0, 0, 0.5);
}

.container.ringing {
  animation: blink-red 0.4s infinite;
}

@keyframes blink-red {
  0%,
  100% {
    background-color: #000;
  }
  50% {
    background-color: #ff0000;
  }
}

.connecting {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2rem;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 3px solid #333;
  border-top: 3px solid #fff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.connecting p {
  color: #999;
  font-size: 0.9rem;
  letter-spacing: 2px;
  text-transform: uppercase;
  font-weight: 600;
}

.setup {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2rem;
}

.client-select {
  display: flex;
  gap: 3rem;
  justify-content: center;
}

.radio-label {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  cursor: pointer;
  font-size: 1.1rem;
  color: #fff;
  transition: opacity 0.3s;
}

.radio-label:hover {
  opacity: 0.8;
}

.radio-label input {
  cursor: pointer;
  width: 1.3rem;
  height: 1.3rem;
  accent-color: #fff;
}

.radio-label span {
  font-weight: 500;
}

.app {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3rem;
  position: relative;
}

.client-info {
  font-size: 0.9rem;
  color: #666;
  letter-spacing: 2px;
  text-transform: uppercase;
  font-weight: 600;
}

.call-button {
  width: 250px;
  height: 250px;
  border-radius: 50%;
  background: #ff0000;
  border: none;
  color: #fff;
  font-size: 3rem;
  font-weight: 700;
  letter-spacing: 2px;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 0 40px rgba(255, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  text-transform: uppercase;
}

.call-button:hover:not(:disabled) {
  transform: scale(1.08);
  box-shadow: 0 0 60px rgba(255, 0, 0, 0.7);
}

.call-button:active:not(:disabled) {
  transform: scale(0.98);
}

.call-button:disabled {
  background: #333;
  color: #666;
  box-shadow: 0 0 20px rgba(255, 0, 0, 0.2);
  cursor: not-allowed;
}

.timeout-indicator {
  font-size: 1.5rem;
  color: #666;
  font-weight: 600;
  letter-spacing: 1px;
}

.spacebar-hint {
  margin-top: 1rem;
  font-size: 0.85rem;
  color: #555;
  letter-spacing: 0.5px;
}

.spacebar-hint kbd {
  background: #222;
  color: #aaa;
  padding: 0.3rem 0.6rem;
  border-radius: 4px;
  font-weight: 700;
  font-size: 0.8rem;
  border: 1px solid #444;
  box-shadow: 0 2px 0 #111;
  margin: 0 0.3rem;
}

.footer {
  position: fixed;
  bottom: 15px;
  left: 15px;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  font-size: 0.7rem;
  color: #444;
  letter-spacing: 0.5px;
  z-index: 999;
}

.footer .version {
  font-weight: 700;
}

.footer .author {
  font-weight: 400;
  font-size: 0.65rem;
  color: #444;
  text-decoration: none;
  cursor: pointer;
  transition: color 0.3s ease;
}

.footer .author:hover {
  color: #00ff00;
}
</style>
