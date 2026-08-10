package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
	"tenuki-server/protocol"
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

var engine *KataGoEngine

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
		for binaryPayload := range engine.Broadcast {
			err := conn.WriteMessage(websocket.BinaryMessage, binaryPayload)
			if err != nil {
				log.Println("Write error:", err)
				return
			}
		}
	}()

	var currentCancel context.CancelFunc

	for {
		messageType, payload, err := conn.ReadMessage()
		if err != nil {
			log.Println("Client disconnected:", err)
			if currentCancel != nil {
				currentCancel()
			}
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
			if currentCancel != nil {
				currentCancel()
			}

			query, err := protocol.ParseRequest(payload)
			if err != nil {
				log.Println("[Error] Failed to parse binary request:", err)
				continue
			}

			ctx, cancel := context.WithCancel(context.Background())
			currentCancel = cancel

			// Start the pseudo-streaming loop!
			go func(q *protocol.KataGoQuery, ctx context.Context) {
				log.Printf("Starting stream for query %s\n", q.ID)
				visits := 20 // Start small for instant first-frame
				for {
					select {
					case <-ctx.Done():
						return
					default:
					}

					q.MaxVisits = visits
					jsonBytes, _ := json.Marshal(q)
					engine.SendQuery(jsonBytes)

					visits += 50
					if visits > 2000 {
						return // Stop at 2000 visits
					}
					
					// Pace the queries so we don't flood the engine
					time.Sleep(300 * time.Millisecond)
				}
			}(query, ctx)
		}
	}
}

func main() {
	var err error
	
	log.Println("Booting up KataGo Engine...")
	// Make sure the model and config are in the same directory where you run this!
	engine, err = StartKataGo("kata1-b18c384nbt-s9996604416-d4316597426.bin.gz", "analysis.cfg")
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
