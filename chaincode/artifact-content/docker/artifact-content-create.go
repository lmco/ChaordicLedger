package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	//"github.com/stretchr/testify/assert"
	"io"
	"io/ioutil"
	"math/rand"
	"mime/multipart"
	"net/http"
	"os"
	"strings"
	//"testing"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	shell "github.com/ipfs/go-ipfs-api"
)

// type Annotatedbuffer struct {
// 	// defining struct variables
// 	dataType string
// 	data     []byte
// }

// type Formdata struct {

// 	// defining struct variables
// 	fieldname    string
// 	originalname string
// 	encoding     string
// 	mimetype     string
// 	buffer       Annotatedbuffer
// 	size         int
// }

// type SimpleFormdata struct {
// 	fieldname    string
// 	originalname string
// }

// type SimpleFormdata struct {

// 	// defining struct variables
// 	fieldname    string
// 	originalname string
// 	encoding     string
// 	mimetype     string
// 	size         int
// }

var sh *shell.Shell

func makeRandomObject() (string, error) {
	// do some math to make a size
	x := rand.Intn(120) + 1
	y := rand.Intn(120) + 1
	z := rand.Intn(120) + 1
	size := x * y * z

	something := strings.NewReader("Some random text here.")
	r := io.LimitReader(something, int64(size))
	time.Sleep(time.Second)
	return sh.Add(r)
}

// Alternatively, we could write to a local service that interacts with the IPFS MFS.
func makeObject(content string) (string, error) {
	r := strings.NewReader(content)
	return sh.Add(r)
}

func makeFile(content []byte) (string, error) {
	fmt.Println("Attempting to write to IPFS: " + string(content))
	r := bytes.NewReader(content)
	return sh.Add(r)
}

// func listFiles() (string, error) {
// 	return sh.Unixfs().ls()
// }

func TestUploadFolderRaw() {
	ct, r, err := createForm(map[string]string{
		"/file1":    "@/my/path/file1",
		"/dir":      "@/my/path/dir",
		"/dir/file": "@/my/path/dir/file",
	})

	resp, err := http.Post("http://ipfs-ui:5001/api/v0/add?pin=true&recursive=true&wrap-with-directory=true", ct, r)

	respAsBytes, err := ioutil.ReadAll(resp.Body)
	fmt.Println("response: ", string(respAsBytes))
	fmt.Println("err: ", err)
}

func createForm(form map[string]string) (string, io.Reader, error) {
	body := new(bytes.Buffer)
	mp := multipart.NewWriter(body)
	defer mp.Close()
	for key, val := range form {
		if strings.HasPrefix(val, "@") {
			val = val[1:]
			file, err := os.Open(val)
			if err != nil {
				return "", nil, err
			}
			defer file.Close()
			part, err := mp.CreateFormFile(key, val)
			if err != nil {
				return "", nil, err
			}
			io.Copy(part, file)
		} else {
			mp.WriteField(key, val)
		}
	}
	return mp.FormDataContentType(), body, nil
}

func TestAPI(url string) {
	resp, err := http.Get(url)
	if err != nil {
		fmt.Println(err)
	}

	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("err:", err)
	}

	fmt.Println("response: ", string(body))
}

// InitLedger adds a base set of content to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	// Used the following commands to generate the values:
	//   head -c 1KiB /dev/urandom > randomArtifact0.bin
	//   sha512sum randomArtifact0.bin
	//   uuidgen
	//
	//   tr -dc '[:alnum:] \n' < /dev/urandom | head -c 394 > randomArtifact1.txt
	contents := []Content{
		{CreationTimestamp: time.Now(), ID: "68b2bc65-b487-45b5-b166-52fe496515f9", IPFSName: "None"},
		{CreationTimestamp: time.Now(), ID: "d762245e-acd1-4162-95b5-0da6d2889893", IPFSName: "Nada"},
	}

	for _, content := range contents {
		contentJSON, err := json.Marshal(content)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(content.ID, contentJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

func TryListingFiles(baseURL string) {
	fmt.Println("Listing files via " + baseURL)
	fmt.Println("With filestore")
	TestAPI(baseURL + "filestore/ls")
	fmt.Println("With files")
	TestAPI(baseURL + "files/ls")
	fmt.Println("With files on /tmp and short format")
	TestAPI(baseURL + "files/ls?arg=/tmp")
	fmt.Println("With files on /tmp and long format")
	TestAPI(baseURL + "files/ls?arg=%2Ftmp&long=true")
	fmt.Println("With files on tmp and short format")
	TestAPI(baseURL + "files/ls?arg=%2Ftmp")
	fmt.Println("With files on tmp and long format")
	TestAPI(baseURL + "files/ls?arg=%2Ftmp&long=true")
	fmt.Println("With files on root")
	TestAPI(baseURL + "files/ls?arg=/")
	fmt.Println("Key list")
	TestAPI(baseURL + "key/list")
	fmt.Println("Pin list")
	TestAPI(baseURL + "pin/ls")
	fmt.Println("Diag")
	TestAPI(baseURL + "diag/sys")
	fmt.Println("Version")
	TestAPI(baseURL + "version")
	fmt.Println("Log tail")
	TestAPI(baseURL + "log/tail")
}

func TryGetURL(url string) {
	fmt.Println("Trying ", url)
	resp, err := http.Get(url)
	if err != nil {
		fmt.Println(err)
	}

	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println(err)
	}

	fmt.Println(string(body))
}

// type Bird struct {
// 	Species     string
// 	Description string
// }

type AnnotatedBuffer struct {
	Type string
	Data []int
}

type FormData struct {
	FieldName    string
	OriginalName string
	Encoding     string
	MimeType     string
	Buffer       AnnotatedBuffer
	Size         int
}

func PostToGraph(nodedata NodeData, url string) {
	fmt.Println("Posting to ", url)
	nodedataJSON, err := json.Marshal(nodedata)
	fmt.Println(string(nodedataJSON))
	body := strings.NewReader(string(nodedataJSON))
	req, err := http.NewRequest("POST", url, body)
	if err != nil {
		fmt.Println("Error creating request:", err)
	} else {
		req.Header.Set("Content-Type", "application/json")
		fmt.Println("Executing request")
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			fmt.Println("Error sending node data creation request: ", err)
		} else {
			fmt.Println("Request executed")
		}
		defer resp.Body.Close()
	}
}

// func (s *SmartContract) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
// 	// Return the result as success payload
// 	return shim.Success([]byte("Hello, world!"))
// }

// CreateContent issues a new content to the world state with given details.
//func (s *SmartContract) CreateContent(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, id string, formContent string) ([]*Content, error) {
func (s *SmartContract) CreateContent(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, id string, formContent string) (*Content, error) {
	exists, err := s.ContentExists(ctx, id)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, fmt.Errorf("Content %s already exists", id)
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
	fmt.Printf("Buffer Data: %d\n", formData.Buffer.Data)
	fmt.Printf("Size: %d\n", formData.Size)
	fmt.Println()

	ipfsName := ""
	sh = shell.NewShell("ipfs-ui:5001")
	for i := 0; i < 1; i++ {
		resp, err := makeObject(formJson)
		if err != nil {
			fmt.Println("err: ", err)
		}
		fmt.Println("Done making object via API module. IPFS Name for " + formData.OriginalName + " is " + string(resp))
		ipfsName = string(resp)
	}

	// Create a node in the relationship tree
	// curl -X POST http://localhost:7070 -H 'Content-Type: application/json' -d '{{body}}'
	node := Node{
		NodeID: ipfsName,
		FileID: formData.OriginalName,
	}

	nodedata := NodeData{
		Type: "node",
		Data: node,
	}

	PostToGraph(nodedata, "http://graph-service:12345")

	content := Content{
		CreationTimestamp: creationTimestamp,
		ID:                id,
		IPFSName:          ipfsName,
	}

	contentJSON, err := json.Marshal(content)
	if err != nil {
		return nil, err
	}

	fmt.Println("Adding record to the ledger: ", string(contentJSON))

	// var contentArray []*Content
	// contentArray = append(contentArray, &content)

	return &content, ctx.GetStub().PutState(ipfsName, contentJSON)
}
