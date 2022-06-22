package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func PostNodeToGraph(nodeData NodeData, url string) {
	fmt.Println("Posting to ", url)
	nodeDataJSON, err := json.Marshal(nodeData)
	fmt.Println(string(nodeDataJSON))
	body := strings.NewReader(string(nodeDataJSON))
	req, err := http.NewRequest("POST", url, body)
	if err != nil {
		fmt.Println("Error creating request:", err)
	} else {
		req.Header.Set("Content-Type", "application/json")
		fmt.Println("Executing request")
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			fmt.Println("Error sending node creation request: ", err)
		} else {
			fmt.Println("Request executed")
		}
		defer resp.Body.Close()
	}
}

// CreateNode issues a new node to the world state with given details.
func (s *SmartContract) CreateNode(ctx contractapi.TransactionContextInterface, nodeid string, fileid string) error {
	fmt.Println("Node ID: ", nodeid)
	fmt.Println("File ID: ", fileid)
	fmt.Println("")

	node := Node{
		NodeID: nodeid,
		FileID: fileid,
	}

	nodeData := NodeData{
		Type: "node",
		Data: node,
	}

	// Create a node in the node tree
	PostNodeToGraph(nodeData, "http://graph-service:12345")

	nodeDataJSON, err := json.Marshal(nodeData)
	if err != nil {
		return err
	}

	fmt.Println("Adding record to the ledger: ", string(nodeDataJSON))

	// ISO-8601 time format
	return ctx.GetStub().PutState(time.Now().Format(time.RFC3339), nodeDataJSON)
}
