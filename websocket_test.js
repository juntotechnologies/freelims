// WebSocket Test Client for FreeLIMS
const { io } = require("socket.io-client");

// Connect to the WebSocket server
// NOTE: We're removing /api from the URL since the WebSocket is mounted directly at /ws
const socket = io("http://localhost:8001/ws", {
  transports: ["websocket"],
  reconnection: true,
  timeout: 10000,
  path: ""  // Remove default path since we're already specifying it in the URL
});

// Connection events
socket.on("connect", () => {
  console.log("Connected to the WebSocket server!");
  console.log("Socket ID:", socket.id);
  
  // Subscribe to inventory updates
  socket.emit("subscribe", { resource: "inventory" });
  console.log("Subscribed to inventory updates");
});

socket.on("subscription_success", (data) => {
  console.log("Successfully subscribed to:", data.resource);
});

socket.on("subscription_error", (data) => {
  console.error("Failed to subscribe:", data.message);
});

// Listen for inventory updates
socket.on("inventory_updated", (data) => {
  console.log("Received inventory update:", data);
});

socket.on("connect_error", (error) => {
  console.error("Connection error:", error.message);
});

socket.on("disconnect", (reason) => {
  console.log("Disconnected from server. Reason:", reason);
});

// Keep the script running
console.log("Test client started. Waiting for events...");
setInterval(() => {
  console.log("Still connected:", socket.connected ? "Yes" : "No");
}, 10000); 