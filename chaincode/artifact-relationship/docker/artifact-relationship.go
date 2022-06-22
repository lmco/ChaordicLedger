package main

// Content describes basic details of what makes up a simple relationship
// Insert struct field in alphabetic order => to achieve determinism across languages
// golang keeps the order when marshal to json but doesn't order automatically
type Relationship struct {
	NodeIDA string `json:NodeIDA`
	NodeIDB string `json:NodeIDB`
}

type RelationshipData struct {
	Type string       `json:type`
	Data Relationship `json:data`
}

type Node struct {
	NodeID string `json:nodeid`
	FileID string `json:fileid`
}

type NodeData struct {
	Type string `json:type`
	Data Node   `json:data`
}

func main() {
	Init()
}
