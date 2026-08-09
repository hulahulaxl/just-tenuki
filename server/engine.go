package main

import (
	"bufio"
	"io"
	"log"
	"os/exec"
)

// KataGoEngine manages the background KataGo process
type KataGoEngine struct {
	cmd    *exec.Cmd
	stdin  io.WriteCloser
	stdout io.ReadCloser
	stderr io.ReadCloser
}

// StartKataGo boots the engine and begins listening to its stdout
func StartKataGo(modelPath, configPath string) (*KataGoEngine, error) {
	cmd := exec.Command("katago", "analysis", "-model", modelPath, "-config", configPath)

	stdin, err := cmd.StdinPipe()
	if err != nil {
		return nil, err
	}

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return nil, err
	}

	if err := cmd.Start(); err != nil {
		return nil, err
	}

	engine := &KataGoEngine{
		cmd:    cmd,
		stdin:  stdin,
		stdout: stdout,
		stderr: stderr,
	}

	// Start a background goroutine to read KataGo's output line-by-line
	go engine.readLoop()
	// Start a background goroutine to read KataGo's stderr (Startup Logs)
	go engine.readStderr()

	return engine, nil
}

// readStderr continuously reads KataGo's startup logs
func (e *KataGoEngine) readStderr() {
	scanner := bufio.NewScanner(e.stderr)
	for scanner.Scan() {
		log.Println("[KataGo LOG]:", scanner.Text())
	}
}

// readLoop continuously reads JSON lines from KataGo
func (e *KataGoEngine) readLoop() {
	scanner := bufio.NewScanner(e.stdout)
	for scanner.Scan() {
		line := scanner.Text()
		// For now, just log the raw JSON so we can prove it's streaming!
		log.Println("[KataGo Output]:", line)
	}

	if err := scanner.Err(); err != nil {
		log.Println("[KataGo Error]:", err)
	}
	log.Println("KataGo process died.")
}

// SendQuery writes a raw JSON string to KataGo's stdin
func (e *KataGoEngine) SendQuery(jsonQuery string) {
	// KataGo requires a newline \n after the JSON to know the query is finished
	queryWithNewline := jsonQuery + "\n"
	_, err := e.stdin.Write([]byte(queryWithNewline))
	if err != nil {
		log.Println("Failed to send query to KataGo:", err)
	}
}
