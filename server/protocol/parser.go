package protocol

import (
	"encoding/binary"
	"errors"
	"fmt"
)

// KataGoQuery represents the JSON structure we send to KataGo
type KataGoQuery struct {
	ID           string     `json:"id"`
	Rules        string     `json:"rules"`
	BoardXSize   int        `json:"boardXSize"`
	BoardYSize   int        `json:"boardYSize"`
	Komi         float64    `json:"komi"`
	InitialStones [][]string `json:"initialStones,omitempty"`
	Moves        [][]string `json:"moves,omitempty"`
	AnalyzeTurns []int      `json:"analyzeTurns"`
	MaxVisits    int        `json:"maxVisits"`
}

// FlatCoordToVertex converts our 1D index (e.g. 0 to 360) into SGF strings (e.g. "Q4")
func FlatCoordToVertex(index uint16, boardSize uint8) string {
	// Our 1D index maps to SGF: x + y*boardSize
	// Note: KataGo uses GTP vertex format (e.g., A1, D4, Q16) OR SGF letters.
	// But in the JSON API, it expects letters like "D4" for GTP format.
	// Wait! SGF coordinates are "pd", but KataGo JSON expects GTP-style strings like "Q4".
	
	// Let's implement this calculation:
	x := int(index) % int(boardSize)
	y := int(index) / int(boardSize)
	
	// GTP skips the letter 'I' to avoid confusion with '1' or 'l'
	letters := "ABCDEFGHJKLMNOPQRSTUVWXYZ"
	if x >= len(letters) || y >= int(boardSize) {
		return "PASS"
	}
	
	// GTP y-axis is inverted compared to SGF. KataGo accepts standard GTP.
	// 0,0 in our Flutter UI is top-left. GTP 1 is bottom. 
	// So y coordinate for KataGo is (boardSize - y).
	gtpY := int(boardSize) - y
	gtpX := letters[x]
	
	return fmt.Sprintf("%c%d", gtpX, gtpY)
}

// ParseRequest parses a binary byte array into a JSON-ready KataGoQuery
func ParseRequest(payload []byte) (*KataGoQuery, error) {
	if len(payload) < 8 {
		return nil, errors.New("payload too short")
	}

	// 0x00 OpCode is checked before calling this.
	// 0x01 Query ID (uint16)
	queryID := binary.BigEndian.Uint16(payload[1:3])
	
	// 0x03 Board Size
	boardSize := payload[3]
	
	// 0x04 Rules
	var rules string
	switch payload[4] {
	case 1:
		rules = "chinese"
	case 2:
		rules = "tromp-taylor"
	default:
		rules = "japanese"
	}

	// 0x05 Komi
	komi := float64(payload[5]) / 10.0

	// 0x06 Setup Count
	setupCount := binary.BigEndian.Uint16(payload[6:8])
	
	offset := 8
	var initialStones [][]string
	for i := 0; i < int(setupCount); i++ {
		if offset+3 > len(payload) {
			return nil, errors.New("invalid setup stones length")
		}
		playerByte := payload[offset]
		playerStr := "B"
		if playerByte == 1 {
			playerStr = "W"
		}
		
		index := binary.BigEndian.Uint16(payload[offset+1 : offset+3])
		vertex := FlatCoordToVertex(index, boardSize)
		initialStones = append(initialStones, []string{playerStr, vertex})
		
		offset += 3
	}

	// Read Moves
	if offset+2 > len(payload) {
		return nil, errors.New("invalid move count length")
	}
	moveCount := binary.BigEndian.Uint16(payload[offset : offset+2])
	offset += 2

	var moves [][]string
	for i := 0; i < int(moveCount); i++ {
		if offset+3 > len(payload) {
			return nil, errors.New("invalid moves length")
		}
		playerByte := payload[offset]
		playerStr := "B"
		if playerByte == 1 {
			playerStr = "W"
		}
		
		index := binary.BigEndian.Uint16(payload[offset+1 : offset+3])
		vertex := FlatCoordToVertex(index, boardSize)
		moves = append(moves, []string{playerStr, vertex})
		
		offset += 3
	}

	// Convert uint16 QueryID to string for KataGo
	idStr := fmt.Sprintf("%d", queryID)

	query := &KataGoQuery{
		ID:           idStr,
		Rules:        rules,
		BoardXSize:   int(boardSize),
		BoardYSize:   int(boardSize),
		Komi:         komi,
		InitialStones: initialStones,
		Moves:        moves,
		AnalyzeTurns: []int{int(moveCount)}, // Analyze the final state after all moves are played
	}

	return query, nil
}

// KataGoResponse represents the JSON output from KataGo
type KataGoResponse struct {
	ID        string `json:"id"`
	MoveInfos []struct {
		Move      string   `json:"move"`
		Winrate   float64  `json:"winrate"`
		ScoreLead float64  `json:"scoreLead"`
		Visits    int      `json:"visits"`
		PV        []string `json:"pv"`
	} `json:"moveInfos"`
	RootInfo struct {
		Winrate   float64 `json:"winrate"`
		ScoreLead float64 `json:"scoreLead"`
	} `json:"rootInfo"`
}

// VertexToFlatCoord converts GTP strings (e.g. "Q4") back into a 1D index
func VertexToFlatCoord(vertex string, boardSize uint8) uint16 {
	if vertex == "pass" || vertex == "PASS" {
		return 0xFFFF // Max uint16 represents Pass
	}
	if len(vertex) < 2 {
		return 0xFFFF
	}

	xChar := vertex[0]
	var x int
	if xChar >= 'A' && xChar <= 'Z' {
		x = int(xChar - 'A')
		if xChar > 'I' {
			x-- // GTP skips 'I'
		}
	} else if xChar >= 'a' && xChar <= 'z' {
		x = int(xChar - 'a')
		if xChar > 'i' {
			x--
		}
	} else {
		return 0xFFFF
	}

	var gtpY int
	fmt.Sscanf(vertex[1:], "%d", &gtpY)
	
	// GTP y-axis is inverted
	y := int(boardSize) - gtpY
	
	if x < 0 || x >= int(boardSize) || y < 0 || y >= int(boardSize) {
		return 0xFFFF
	}

	return uint16(x + y*int(boardSize))
}

// EncodeResponse converts KataGo JSON output into our ultra-tight custom binary protocol
func EncodeResponse(resp *KataGoResponse, boardSize uint8) ([]byte, error) {
	var payload []byte
	
	// 0x00 OpCode (0x02 = Analysis Response)
	payload = append(payload, 0x02)
	
	// 0x01 Query ID (uint16)
	var queryID uint16
	fmt.Sscanf(resp.ID, "%d", &queryID)
	buf16 := make([]byte, 2)
	binary.BigEndian.PutUint16(buf16, queryID)
	payload = append(payload, buf16...)
	
	// 0x03 Winrate (uint16) - 0.0 to 1.0 mapped to 0 to 1000
	winrateInt := uint16(resp.RootInfo.Winrate * 1000)
	binary.BigEndian.PutUint16(buf16, winrateInt)
	payload = append(payload, buf16...)
	
	// 0x05 ScoreLead (int16) - mapped to +/- 3600
	scoreLeadInt := int16(resp.RootInfo.ScoreLead * 10)
	binary.BigEndian.PutUint16(buf16, uint16(scoreLeadInt))
	payload = append(payload, buf16...)
	
	// 0x07 Move Options count (uint8)
	optionsCount := uint8(len(resp.MoveInfos))
	payload = append(payload, optionsCount)
	
	buf32 := make([]byte, 4)
	
	// Move Blocks
	for _, moveInfo := range resp.MoveInfos {
		// Move Index (uint16)
		index := VertexToFlatCoord(moveInfo.Move, boardSize)
		binary.BigEndian.PutUint16(buf16, index)
		payload = append(payload, buf16...)
		
		// Winrate (uint16)
		moveWinrate := uint16(moveInfo.Winrate * 1000)
		binary.BigEndian.PutUint16(buf16, moveWinrate)
		payload = append(payload, buf16...)
		
		// ScoreLead (int16)
		moveScoreLead := int16(moveInfo.ScoreLead * 10)
		binary.BigEndian.PutUint16(buf16, uint16(moveScoreLead))
		payload = append(payload, buf16...)
		
		// Visits (uint32)
		binary.BigEndian.PutUint32(buf32, uint32(moveInfo.Visits))
		payload = append(payload, buf32...)
		
		// PV Length (uint8)
		pvLen := uint8(len(moveInfo.PV))
		payload = append(payload, pvLen)
		
		// PV Indices ([...]uint16)
		for _, pvVertex := range moveInfo.PV {
			pvIndex := VertexToFlatCoord(pvVertex, boardSize)
			binary.BigEndian.PutUint16(buf16, pvIndex)
			payload = append(payload, buf16...)
		}
	}
	
	return payload, nil
}

