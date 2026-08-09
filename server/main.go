package main

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

const (
	OpPing = 0x99
	OpPong = 0x9A
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

	for {
		messageType, payload, err := conn.ReadMessage()
		if err != nil {
			log.Println("Client disconnected:", err)
			break
		}

		if messageType != websocket.BinaryMessage {
			continue
		}

		// Handle Application Ping
		if len(payload) == 1 && payload[0] == OpPing {
			conn.WriteMessage(websocket.BinaryMessage, []byte{OpPong})
			continue
		}
		
		// If it's a 1-byte command (0x00), let's use it as a debug trigger to send the test JSON to KataGo!
		if len(payload) == 1 && payload[0] == 0x00 {
			log.Println("Received trigger 0x00. Sending JSON to KataGo...")
			// Note: We MUST use maxVisits. KataGo JSON API does not stream natively.
			testJSON := `{"id":"test1","rules":"japanese","boardXSize":19,"boardYSize":19,"moves":[["B","Q4"],["W","D4"]],"analyzeTurns":[2],"maxVisits":100}`
			engine.SendQuery(testJSON)
			continue
		}

		log.Printf("Received %d bytes of binary data: %x\n", len(payload), payload)
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
