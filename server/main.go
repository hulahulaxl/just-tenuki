package main

import (
	"encoding/json"
	"log"
	"net/http"

	"tenuki-server/engine"
	"tenuki-server/protocol"

	"github.com/gorilla/websocket"
)

const (
	OpPing    = 0x99
	OpPong    = 0x9A
	OpAnalyze = 0x01
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

var globalEngine *engine.KataGoEngine

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade error:", err)
		return
	}
	defer conn.Close()

	log.Println("Client connected!")

	// Start writer goroutine
	go func() {
		for binaryPayload := range globalEngine.Broadcast {
			err := conn.WriteMessage(websocket.BinaryMessage, binaryPayload)
			if err != nil {
				log.Println("Write error:", err)
				return
			}
		}
	}()

	for {
		messageType, payload, err := conn.ReadMessage()
		if err != nil {
			log.Println("Client disconnected:", err)
			break
		}

		if messageType != websocket.BinaryMessage || len(payload) == 0 {
			continue
		}

		// Handle Application Ping
		if payload[0] == OpPing {
			conn.WriteMessage(websocket.BinaryMessage, []byte{OpPong})
			continue
		}
		
		// Handle Analyze Request
		if payload[0] == OpAnalyze {
			query, err := protocol.ParseRequest(payload)
			if err != nil {
				log.Println("[Error] Failed to parse binary request:", err)
				continue
			}

			q := query
			q.MaxVisits = 50 // Static, fast query
			
			jsonBytes, _ := json.Marshal(q)
			log.Println("[DEBUG] Sending static KataGo Query:", string(jsonBytes))
			globalEngine.SendQuery(jsonBytes)
		}
	}
}

func main() {
	var err error
	
	log.Println("Booting up KataGo Engine...")
	// Make sure the model and config are in the same directory where you run this!
	globalEngine, err = engine.StartKataGo("kata1-b18c384nbt-s9996604416-d4316597426.bin.gz", "analysis.cfg")
	if err != nil {
		log.Fatal("Failed to start KataGo:", err)
	}

	http.HandleFunc("/ws", handleWebSocket)

	log.Println("Starting Tenuki WebSocket Server on :8080...")
	err = http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal("Server failed:", err)
	}
}
