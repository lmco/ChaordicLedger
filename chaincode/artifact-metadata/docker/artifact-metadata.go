package main

import (
	"time"
)

// Metadata describes basic details of what makes up a simple metadata record.
//
// Insert struct fields in alphabetic order to help achieve deterministic JSON
// output across peers. Go preserves struct field order when marshaling to JSON,
// but it does not sort fields automatically.
type Metadata struct {
	CreationTimestamp time.Time `json:"CreationTimestamp"`
	Hash              string    `json:"Hash"`
	HashType          string    `json:"HashType"`
	ID                string    `json:"ID"`
	SizeInBytes       int       `json:"SizeInBytes"`
}

func main() {
	Init()
}
