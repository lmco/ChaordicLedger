package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	shell "github.com/ipfs/go-ipfs-api"
)

// type AnnotatedBuffer struct {
// 	Type string
// 	Data []int
// }

// type FormData struct {
// 	FieldName    string
// 	OriginalName string
// 	Encoding     string
// 	MimeType     string
// 	Buffer       AnnotatedBuffer
// 	Size         int
// }

// UpdateContent replaces the existing content in the world state with the given details.
// It's realy the Boolean opposite of CreateContent and likely could be combined.
func (s *SmartContract) UpdateContent(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, id string, formContent string) error {
	exists, err := s.ContentExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("Content %s already exists", id)
	}

	fmt.Println("Timestamp: ", creationTimestamp)
	fmt.Println("ID: ", id)
	fmt.Println("Form Content: ", formContent)
	fmt.Println("")

	formJson := formContent
	var formData FormData
	json.Unmarshal([]byte(formJson), &formData)
	fmt.Printf("Field Name: %s\n", formData.FieldName)
	fmt.Printf("Original Name: %s\n", formData.OriginalName)
	fmt.Printf("Encoding: %s\n", formData.Encoding)
	fmt.Printf("MIMEType: %s\n", formData.MimeType)
	fmt.Printf("Buffer Type: %s\n", formData.Buffer.Type)
	fmt.Printf("Buffer Data: %s\n", formData.Buffer.Data)
	fmt.Printf("Size: %d\n", formData.Size)
	fmt.Println()

	ipfsName := ""
	sh = shell.NewShell("ipfs-rpc-api:5001")
	for i := 0; i < 1; i++ {
		resp, err := makeObject(formJson)
		if err != nil {
			fmt.Println("err: ", err)
		}
		fmt.Println("Done making object via API module. IPFS Name for " + id + " is " + string(resp))
		ipfsName = string(resp)
	}

	content := Content{
		CreationTimestamp: creationTimestamp,
		ID:                id,
		IPFSName:          ipfsName,
	}

	contentJSON, err := json.Marshal(content)
	if err != nil {
		return err
	}

	fmt.Println("Adding record to the ledger: ", string(contentJSON))

	return ctx.GetStub().PutState(ipfsName, contentJSON)
}
