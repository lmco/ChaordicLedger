package main

import (
	"time"
)

// Metadata describes basic details of what makes up a simple metadata
// Insert struct field in alphabetic order => to achieve determinism accross languages
// golang keeps the order when marshal to json but doesn't order automatically
type Metadata struct {
	CreationTimestamp time.Time `json:CreationTimestamp`
	Hash              string    `json:Hash`
	HashType          string    `json:HashType`
	ID                string    `json:ID`
	SizeInBytes       int       `json:SizeInBytes`
}

func main() {
	Init()
}
