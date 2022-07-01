package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// ContentExists returns true when content with given ID exists in world state
func (s *SmartContract) ContentExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	contentJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return contentJSON != nil, nil
}

// GetAllContent returns all content found in world state
func (s *SmartContract) GetAllContent(ctx contractapi.TransactionContextInterface) ([]*Content, error) {
	// range query with empty string for startKey and endKey does an
	// open-ended query of all content in the chaincode namespace.
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		fmt.Println("Returning nil 1")
		return nil, err
	}
	defer resultsIterator.Close()

	var contentArray []*Content
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			fmt.Println("Returning nil 2")
			return nil, err
		}

		var content Content
		err = json.Unmarshal(queryResponse.Value, &content)
		if err != nil {
			fmt.Println("Returning nil 3")
			return nil, err
		}
		fmt.Println("Appending content to array.")
		contentArray = append(contentArray, &content)
	}

	return contentArray, nil
}

// ReadContent returns the content stored in the world state with given id.
func (s *SmartContract) ReadContent(ctx contractapi.TransactionContextInterface, id string) (*Content, error) {
	contentJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if contentJSON == nil {
		return nil, fmt.Errorf("the content %s does not exist", id)
	}

	var content Content
	err = json.Unmarshal(contentJSON, &content)
	if err != nil {
		return nil, err
	}

	return &content, nil
}
