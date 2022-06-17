package main

import (
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// DeleteContent deletes an existing content from the world state
func (s *SmartContract) DeleteContent(ctx contractapi.TransactionContextInterface, id string) error {
	exists, err := s.ContentExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("Content %s does not exist", id)
	}

	return ctx.GetStub().DelState(id)
}
