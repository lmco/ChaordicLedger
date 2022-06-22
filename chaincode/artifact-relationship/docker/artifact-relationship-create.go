package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// InitLedger adds a base set of content to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	return nil
}

func PostRelationshipToGraph(relationshipData RelationshipData, url string) {
	fmt.Println("Posting to ", url)
	relationshipDataJSON, err := json.Marshal(relationshipData)
	fmt.Println(string(relationshipDataJSON))
	body := strings.NewReader(string(relationshipDataJSON))
	req, err := http.NewRequest("POST", url, body)
	if err != nil {
		fmt.Println("Error creating request:", err)
	} else {
		req.Header.Set("Content-Type", "application/json")
		fmt.Println("Executing request")
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			fmt.Println("Error sending relationship creation request: ", err)
		} else {
			fmt.Println("Request executed")
		}
		defer resp.Body.Close()
	}
}

// CreateRelationship issues a new relationship to the world state with given details.
func (s *SmartContract) CreateRelationship(ctx contractapi.TransactionContextInterface, nodeida string, nodeidb string) error {
	fmt.Println("Node ID A: ", nodeida)
	fmt.Println("Node ID B: ", nodeidb)
	fmt.Println("")

	relationship := Relationship{
		NodeIDA: nodeida,
		NodeIDB: nodeidb,
	}

	relationshipData := RelationshipData{
		Type: "relationship",
		Data: relationship,
	}

	// Create a relationship in the relationship tree
	PostRelationshipToGraph(relationshipData, "http://graph-service:12345")

	relationshipDataJSON, err := json.Marshal(relationshipData)
	if err != nil {
		return err
	}

	fmt.Println("Adding record to the ledger: ", string(relationshipDataJSON))

	// ISO-8601 time format
	return ctx.GetStub().PutState(time.Now().Format(time.RFC3339), relationshipDataJSON)
}
