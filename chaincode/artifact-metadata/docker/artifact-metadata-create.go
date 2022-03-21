package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// InitLedger adds a base set of metadata to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	// Used the following commands to generate the values:
	//   head -c 1KiB /dev/urandom > randomArtifact0.bin
	//   sha512sum randomArtifact0.bin
	//   uuidgen
	//
	//   tr -dc '[:alnum:] \n' < /dev/urandom | head -c 394 > randomArtifact1.txt
	metadatas := []Metadata{
		{CreationTimestamp: time.Now(), Hash: "89624e43c5c4d85c476f578443b083d55e5bcf75de9852e61e921d2e75971e2b26302ae70e6ac465e07141a048ae97fc7d58dffffb7d4702d23ac359bc2c3edc", HashType: "SHA512", ID: "68b2bc65-b487-45b5-b166-52fe496515f9", SizeInBytes: 1024},
		{CreationTimestamp: time.Now(), Hash: "fd1f049abeb128218e0bd77fa1346d11ce4414ac7dcb66ee015e5bbb0e984dd146621917c7a81cf4a4d680042510ba2dc171911897bda3dbb1e6517a0e82a1f2", HashType: "SHA512", ID: "d762245e-acd1-4162-95b5-0da6d2889893", SizeInBytes: 394},
	}

	for _, metadata := range metadatas {
		metadataJSON, err := json.Marshal(metadata)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(metadata.ID, metadataJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

// CreateMetadata issues a new metadata to the world state with given details.
func (s *SmartContract) CreateMetadata(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, hash string, hashType string, id string, sizeInBytes int) error {
	exists, err := s.MetadataExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("Metadata %s already exists", id)
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
