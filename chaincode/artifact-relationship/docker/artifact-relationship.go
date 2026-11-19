package main

// Content describes basic details of what makes up a simple relationship
// Insert struct field in alphabetic order => to achieve determinism across languages
// golang keeps the order when marshal to json but doesn't order automatically
type Relationship struct {
	NodeIDA string `json:"NodeIDA"`
	NodeIDB string `json:"NodeIDB"`
}

type RelationshipData struct {
	Type string       `json:"Type"`
	Data Relationship `json:"Data"`
}

type Node struct {
	NodeID string `json:"NodeID"`
	FileID string `json:"FileID"`
}

type NodeData struct {
	Type string `json:"Type"`
	Data Node   `json:"Data"`
}

// graphServiceURL is where nodes and relationships are posted. A variable so a
// test can point it at a local server.
var graphServiceURL = "http://graph-service:12345"

func main() {
	Init()
}
