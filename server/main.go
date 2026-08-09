package main

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

// We define our custom Application-Level Ping/Pong bytes
// This is for web-client, which may not support the WebSocket protocol-level ping/pong frames.
const (
	OpPing = 0x99
	OpPong = 0x9A
)

// The Upgrader transforms a standard HTTP connection into a WebSocket connection
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow connections from any origin (Flutter Web/Mobile/Desktop)
	},
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	// Upgrade the HTTP request to a WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer conn.Close()

	log.Println("Client connected!")

	// Infinite loop to read incoming binary messages
	for {
		messageType, payload, err := conn.ReadMessage()
		if err != nil {
			log.Println("Client disconnected:", err)
			break
		}

		// We only care about Binary messages (messageType == 2)
		if messageType != websocket.BinaryMessage {
			log.Println("Ignoring non-binary message")
			continue
		}

		// Check if it's our custom Application-Level Ping
		if len(payload) == 1 && payload[0] == OpPing {
			log.Println("Received Application Ping (0x99). Sending Pong (0x9A)...")
			
			// Respond with exactly 1 byte: 0x9A
			err := conn.WriteMessage(websocket.BinaryMessage, []byte{OpPong})
			if err != nil {
				log.Println("Write error:", err)
				break
			}
		} else {
			log.Printf("Received %d bytes of binary data: %x\n", len(payload), payload)
		}
	}
}

func main() {
	http.HandleFunc("/ws", handleWebSocket)

	log.Println("Starting Tenuki WebSocket Server on :8080...")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal("Server failed:", err)
	}
}
