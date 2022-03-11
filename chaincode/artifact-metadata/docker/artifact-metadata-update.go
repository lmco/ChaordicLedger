package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// UpdateMetadata replaces the existing metadata in the world state with the given details.
// It's realy the Boolean opposite of CreateMetadata and likely could be combined.
func (s *SmartContract) UpdateMetadata(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, hash string, hashType string, id string, sizeInBytes int) error {
	exists, err := s.MetadataExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("Metadata %s does not exist", id)
	}

	metadata := Metadata{
		CreationTimestamp: creationTimestamp,
		Hash:              hash,
		HashType:          hashType,
		ID:                id,
		SizeInBytes:       sizeInBytes,
	}

	metadataJSON, err := json.Marshal(metadata)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, metadataJSON)
}
