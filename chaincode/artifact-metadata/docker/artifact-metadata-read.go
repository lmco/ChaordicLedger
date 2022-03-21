package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// MetadataExists returns true when metadata with given ID exists in world state
func (s *SmartContract) MetadataExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	metadataJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return metadataJSON != nil, nil
}

// GetAllMetadata returns all metadata found in world state
func (s *SmartContract) GetAllMetadata(ctx contractapi.TransactionContextInterface) ([]*Metadata, error) {
	// range query with empty string for startKey and endKey does an
	// open-ended query of all metadata in the chaincode namespace.
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var metadataArray []*Metadata
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var metadata Metadata
		err = json.Unmarshal(queryResponse.Value, &metadata)
		if err != nil {
			return nil, err
		}
		metadataArray = append(metadataArray, &metadata)
	}

	return metadataArray, nil
}

// ReadMetadata returns the metadata stored in the world state with given id.
func (s *SmartContract) ReadMetadata(ctx contractapi.TransactionContextInterface, id string) (*Metadata, error) {
	metadataJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if metadataJSON == nil {
		return nil, fmt.Errorf("the metadata %s does not exist", id)
	}

	var metadata Metadata
	err = json.Unmarshal(metadataJSON, &metadata)
	if err != nil {
		return nil, err
	}

	return &metadata, nil
}
