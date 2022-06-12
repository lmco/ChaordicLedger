package main

import (
	"time"
)

// Content describes basic details of what makes up a simple content
// Insert struct field in alphabetic order => to achieve determinism accross languages
// golang keeps the order when marshal to json but doesn't order automatically
type Content struct {
	CreationTimestamp time.Time `json:CreationTimestamp`
	Hash              string    `json:Hash`
	HashType          string    `json:HashType`
	ID                string    `json:ID`
	SizeInBytes       int       `json:SizeInBytes`
}

func main() {
	Init()
}
