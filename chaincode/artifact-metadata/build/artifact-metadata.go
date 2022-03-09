// Reference: https://github.com/hyperledgendary/fabric-ccaas-asset-transfer-basic/blob/main/assetTransfer.go
// Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.0/chaincode4ade.html#chaincode-api
// Reference: https://hyperledger-fabric.readthedocs.io/en/release-2.2/smartcontract/smartcontract.html
// Reference: https://hyperledger-fabric.readthedocs.io/en/latest/cc_service.html
// Reference: https://github.com/hyperledger/fabric-samples/tree/main/asset-transfer-basic/chaincode-external#running-the-asset-transfer-basic-external-service

// TODO: Refactor supporting shim code into a separate package.

package main

import (
	"encoding/json"
	"fmt"
	"time"

	"io/ioutil"
	"log"
	"os"
	"strconv"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	//"github.com/hyperledger/fabric-protos-go/peer"
)

type serverConfig struct {
	CCID    string
	Address string
}

// SmartContract provides functions for managing an Metadata
type SmartContract struct {
	contractapi.Contract
}

// Metadata describes basic details of what makes up a simple metadata
// Insert struct field in alphabetic order => to achieve determinism accross languages
// golang keeps the order when marshal to json but doesn't order automatically
type Metadata struct {
	CreationTimestamp time.Time `json:CreationTimestamp`
	Hash              string    `json:Hash`
	HashType          string    `json:HashType`
	ID                string    `json:ID`
	SizeInBytes       int       `json:SizeInBytes`
}

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
		return fmt.Errorf("the metadata %s already exists", id)
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

func getTLSProperties() shim.TLSProperties {
	// Check if chaincode is TLS enabled
	tlsDisabledStr := getEnvOrDefault("CHAINCODE_TLS_DISABLED", "true")
	key := getEnvOrDefault("CHAINCODE_TLS_KEY", "")
	cert := getEnvOrDefault("CHAINCODE_TLS_CERT", "")
	clientCACert := getEnvOrDefault("CHAINCODE_CLIENT_CA_CERT", "")

	// convert tlsDisabledStr to boolean
	tlsDisabled := getBoolOrDefault(tlsDisabledStr, false)
	var keyBytes, certBytes, clientCACertBytes []byte
	var err error

	if !tlsDisabled {
		keyBytes, err = ioutil.ReadFile(key)
		if err != nil {
			log.Panicf("error while reading the crypto file: %s", err)
		}
		certBytes, err = ioutil.ReadFile(cert)
		if err != nil {
			log.Panicf("error while reading the crypto file: %s", err)
		}
	}
	// Did not request for the peer cert verification
	if clientCACert != "" {
		clientCACertBytes, err = ioutil.ReadFile(clientCACert)
		if err != nil {
			log.Panicf("error while reading the crypto file: %s", err)
		}
	}

	return shim.TLSProperties{
		Disabled:      tlsDisabled,
		Key:           keyBytes,
		Cert:          certBytes,
		ClientCACerts: clientCACertBytes,
	}
}

func getEnvOrDefault(env, defaultVal string) string {
	value, ok := os.LookupEnv(env)
	if !ok {
		value = defaultVal
	}
	return value
}

// Note that the method returns default value if the string
// cannot be parsed!
func getBoolOrDefault(value string, defaultVal bool) bool {
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return defaultVal
	}
	return parsed
}

func main() {
	// See chaincode.env.example
	config := serverConfig{
		CCID:    os.Getenv("CHAINCODE_ID"),
		Address: os.Getenv("CHAINCODE_SERVER_ADDRESS"),
	}

	metadataChaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Error creating metadata chaincode: %v", err)
	}

	server := &shim.ChaincodeServer{
		CCID:     config.CCID,
		Address:  config.Address,
		CC:       metadataChaincode,
		TLSProps: getTLSProperties(),
	}

	if err := server.Start(); err != nil {
		log.Panicf("Error starting metadata chaincode: %v", err)
	}
}
