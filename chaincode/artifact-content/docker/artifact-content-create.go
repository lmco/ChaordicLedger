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

// CreateContent issues a new content to the world state with given details.
func (s *SmartContract) CreateContent(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, id string, formContent string) error {
	//func (s *SmartContract) CreateContent(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, id string, localFilePath string) error {
	exists, err := s.ContentExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("Content %s already exists", id)
	}

	// _, err := listFiles()
	// if err != nil {
	// 	fmt.Println("err: ", err)
	// }
	// fmt.Println("Done listing files via API module")

	// TestUploadFolderRaw()
	// fmt.Println("we're okay, too!")

	// Test HTTP connectivity
	//var theData SimpleData // formdata

	//file, _ := ioutil.ReadFile(localFilePath)
	//formErr := json.Unmarshal([]byte(file), &artifact)
	//var altFormContent = `{\"fieldname\":\"upfile\",\"originalname\":\"randomArtifact1.txt\",\"encoding\":\"7bit\",\"mimetype\":\"text/plain\",\"buffer\":{\"type\":\"Buffer\",\"data\":[113,115,115,80,68,107,84,118,65,75,97,48,103,98,107,107,117,67,100,113,111,86,66,115,52,109,52,53,83,65,72,90,116,52,109,86,73,72,70,113,104,113,119,65,80,72,73,106,82,49,52,117,108,72,112,106,10,80,79,51,122,81,66,101,87,74,74,74,83,97,70,107,73,113,112,121,114,81,105,84,108,100,120,103,65,102,81,52,109,67,74,90,106,122,107,118,108,56,87,86,69,109,32,112,67,117,32,101,120,81,10,109,79,79,74,97,72,71,56,51,74,87,52,113,79,84,111,82,115,107,86,66,120,74,119,118,113,75,109,80,117,112,120,77,68,74,82,75,112,74,115,57,51,110,90,71,56,56,119,100,66,80,74,48,57,112,80,108,32,100,120,68,100,72,108,118,107,112,107,107,105,78,74,81,75,79,121,85,103,68,122,120,109,121,81,103,98,114,81,115,121,103,103,50,77,78,65,110,118,98,54,53,85,72,81,53,97,50,101,75,103,76,89,51,117,119,98,108,108,56,87,84,68,79,103,105,73,53,77,107,10,122,110,78,49,72,120,89,72,83,86,118,101,100,88,77,72,119,49,67,113,122,114,105,99,73,89,115,69,114,68,76,53,86,48,110,49,109,100,56,57,102,122,105,83,105,115,32,82,110,101,120,112,57,73,89,115,115,69,71,81,104,68,53,98,81,98,119,69,66,116,68,86,51,70,53,65,54,99,87,116,113,100,112,119,90,55,73,101,49,122,90,55,122,84,57,68,49,111,52,89,89,10,103,32,104,69,82,53,80,66,53,69,106,53,116,105,73,56,68,103,100,68,122,110,110,122,104,72,74,50,52,48,77,85,52,48,48,69,72,76,77,97,56,69,120,54,110,57,52,80,113,105,67]},\"size\":394}`
	//var simpleFormContent = `{"fieldname":"upfile","originalname":"randomArtifact1.txt","encoding":"7bit","mimetype":"text/plain", "size":394}`
	//var simpleFormContent = `{"fieldname":"upfile","originalname":"randomArtifact1.txt"}`

	//var formdata SimpleFormdata
	//json.Unmarshal([]byte(simpleFormContent), &formdata)

	fmt.Println("Timestamp: ", creationTimestamp)
	fmt.Println("ID: ", id)
	fmt.Println("Form Content: ", formContent)
	//fmt.Printf("fieldname: %s, originalname: %s, encoding: %s, mimetype: %s, size: %s", formdata.fieldname, formdata.originalname, formdata.encoding, formdata.mimetype, formdata.size)
	// fmt.Printf("fieldname: %s, originalname: %s", formdata.fieldname, formdata.originalname)
	fmt.Println("")
	// jsonData, err := json.Marshal(theData)
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// fmt.Println("theData: ", string(jsonData))

	// birdJson := `{"species": "pigeon","description": "likes to perch on rocks"}`
	// var bird Bird
	// json.Unmarshal([]byte(birdJson), &bird)
	// fmt.Printf("Species: %s, Description: %s", bird.Species, bird.Description)

	// catJson := `{"species": "upfile","description": "randomfile1.txt"}`
	// var cat Cat
	// json.Unmarshal([]byte(catJson), &cat)
	// fmt.Printf("Field Name: %s, Original Name: %s", cat.Species, cat.Description)

	//catJson := `{"fieldname": "upfile","originalname": "randomfile1.txt","encoding": "7bit","mimetype": "text/plain","size": 394}`
	//catJson := `{"fieldname":"upfile","originalname":"randomArtifact1.txt","encoding":"7bit","mimetype":"text/plain","buffer":{"type":"Buffer","data":[113,115,115,80,68,107,84,118,65,75,97,48,103,98,107,107,117,67,100,113,111,86,66,115,52,109,52,53,83,65,72,90,116,52,109,86,73,72,70,113,104,113,119,65,80,72,73,106,82,49,52,117,108,72,112,106,10,80,79,51,122,81,66,101,87,74,74,74,83,97,70,107,73,113,112,121,114,81,105,84,108,100,120,103,65,102,81,52,109,67,74,90,106,122,107,118,108,56,87,86,69,109,32,112,67,117,32,101,120,81,10,109,79,79,74,97,72,71,56,51,74,87,52,113,79,84,111,82,115,107,86,66,120,74,119,118,113,75,109,80,117,112,120,77,68,74,82,75,112,74,115,57,51,110,90,71,56,56,119,100,66,80,74,48,57,112,80,108,32,100,120,68,100,72,108,118,107,112,107,107,105,78,74,81,75,79,121,85,103,68,122,120,109,121,81,103,98,114,81,115,121,103,103,50,77,78,65,110,118,98,54,53,85,72,81,53,97,50,101,75,103,76,89,51,117,119,98,108,108,56,87,84,68,79,103,105,73,53,77,107,10,122,110,78,49,72,120,89,72,83,86,118,101,100,88,77,72,119,49,67,113,122,114,105,99,73,89,115,69,114,68,76,53,86,48,110,49,109,100,56,57,102,122,105,83,105,115,32,82,110,101,120,112,57,73,89,115,115,69,71,81,104,68,53,98,81,98,119,69,66,116,68,86,51,70,53,65,54,99,87,116,113,100,112,119,90,55,73,101,49,122,90,55,122,84,57,68,49,111,52,89,89,10,103,32,104,69,82,53,80,66,53,69,106,53,116,105,73,56,68,103,100,68,122,110,110,122,104,72,74,50,52,48,77,85,52,48,48,69,72,76,77,97,56,69,120,54,110,57,52,80,113,105,67]},"size":394}`
	formJson := formContent
	//{"fieldname":"upfile","originalname":"randomArtifact1.txt","encoding":"7bit","mimetype":"text/plain","buffer":{"type":"Buffer","data":[113,115,115,80,68,107,84,118,65,75,97,48,103,98,107,107,117,67,100,113,111,86,66,115,52,109,52,53,83,65,72,90,116,52,109,86,73,72,70,113,104,113,119,65,80,72,73,106,82,49,52,117,108,72,112,106,10,80,79,51,122,81,66,101,87,74,74,74,83,97,70,107,73,113,112,121,114,81,105,84,108,100,120,103,65,102,81,52,109,67,74,90,106,122,107,118,108,56,87,86,69,109,32,112,67,117,32,101,120,81,10,109,79,79,74,97,72,71,56,51,74,87,52,113,79,84,111,82,115,107,86,66,120,74,119,118,113,75,109,80,117,112,120,77,68,74,82,75,112,74,115,57,51,110,90,71,56,56,119,100,66,80,74,48,57,112,80,108,32,100,120,68,100,72,108,118,107,112,107,107,105,78,74,81,75,79,121,85,103,68,122,120,109,121,81,103,98,114,81,115,121,103,103,50,77,78,65,110,118,98,54,53,85,72,81,53,97,50,101,75,103,76,89,51,117,119,98,108,108,56,87,84,68,79,103,105,73,53,77,107,10,122,110,78,49,72,120,89,72,83,86,118,101,100,88,77,72,119,49,67,113,122,114,105,99,73,89,115,69,114,68,76,53,86,48,110,49,109,100,56,57,102,122,105,83,105,115,32,82,110,101,120,112,57,73,89,115,115,69,71,81,104,68,53,98,81,98,119,69,66,116,68,86,51,70,53,65,54,99,87,116,113,100,112,119,90,55,73,101,49,122,90,55,122,84,57,68,49,111,52,89,89,10,103,32,104,69,82,53,80,66,53,69,106,53,116,105,73,56,68,103,100,68,122,110,110,122,104,72,74,50,52,48,77,85,52,48,48,69,72,76,77,97,56,69,120,54,110,57,52,80,113,105,67]},"size":394}
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

	//TryListingFiles("http://ipfs-ui:5001/api/v0/")
	//TryListingFiles("http://ipfs-ui:5001/api/api/v0/")
	//TryListingFiles("http://ipfs-ui:5001/v0/")

	//TryGetURL("http://foo-service:12345/foo/")
	//TryGetURL("http://foo-service:12345/")

	ipfsName := ""
	// Try using the go-ipfs-api
	sh = shell.NewShell("ipfs-ui:5001")
	for i := 0; i < 1; i++ {
		resp, err := makeObject(formJson)
		if err != nil {
			fmt.Println("err: ", err)
		}
		fmt.Println("Done making object via API module. IPFS Name for " + id + " is " + string(resp))
		ipfsName = string(resp)
	}

	// // Try using the go-ipfs-api
	// sh = shell.NewShell("ipfs-ui:5001")
	// for i := 0; i < 1; i++ {
	// 	resp, err := makeRandomObject()
	// 	if err != nil {
	// 		fmt.Println("err: ", err)
	// 	}
	// 	fmt.Println("Done making random object via API module" + string(resp))
	// 	ipfsName = string(resp)
	// }

	content := Content{
		CreationTimestamp: creationTimestamp,
		ID:                id,
		IPFSName:          ipfsName,
	}

	contentJSON, err := json.Marshal(content)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, contentJSON)
}
