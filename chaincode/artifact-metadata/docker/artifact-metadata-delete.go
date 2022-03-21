package main

import (
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// DeleteMetadata deletes an existing metadata from the world state
func (s *SmartContract) DeleteMetadata(ctx contractapi.TransactionContextInterface, id string) error {
	exists, err := s.MetadataExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("Metadata %s does not exist", id)
	}

	return ctx.GetStub().DelState(id)
}
