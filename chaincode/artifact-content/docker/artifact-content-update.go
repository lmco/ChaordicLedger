package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// UpdateContent replaces the existing content in the world state with the given details.
// It's realy the Boolean opposite of CreateContent and likely could be combined.
func (s *SmartContract) UpdateContent(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, id string, base64encodedContent string) error {
	exists, err := s.ContentExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("Content %s does not exist", id)
	}

	content := Content{
		CreationTimestamp:    creationTimestamp,
		ID:                   id,
		Base64EncodedContent: base64encodedContent,
	}

	contentJSON, err := json.Marshal(content)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, contentJSON)
}
