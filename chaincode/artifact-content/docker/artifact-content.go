package main

import (
	"time"
)

// Content describes basic details of what makes up a simple content
// Insert struct field in alphabetic order => to achieve determinism across languages
// golang keeps the order when marshal to json but doesn't order automatically
type Content struct {
	CreationTimestamp time.Time `json:"CreationTimestamp"`
	ID                string    `json:"ID"`
	IPFSName          string    `json:"IPFSName"`
}

type Node struct {
	NodeID string `json:"NodeID"`
	FileID string `json:"FileID"`
}

type NodeData struct {
	Type string `json:"Type"`
	Data Node   `json:"Data"`
}

func main() {
	Init()
}
