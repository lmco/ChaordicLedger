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

type AnnotatedBuffer struct {
	// defining struct variables
	dataType string
	data     []int
}

type FormData struct {

	// defining struct variables
	fieldname    string
	originalname string
	encoding     string
	mimetype     string
	buffer       AnnotatedBuffer
	size         int
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

// CreateContent issues a new content to the world state with given details.
func (s *SmartContract) CreateContent(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, id string, formContent string) error {
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
	var formData FormData

	formErr := json.Unmarshal(formContent, &FormData)

	if formErr != nil {
		// if error is not nil
		// print error
		fmt.Println(formErr)
	}

	TryListingFiles("http://ipfs-ui:5001/api/v0/")
	//TryListingFiles("http://ipfs-ui:5001/api/api/v0/")
	//TryListingFiles("http://ipfs-ui:5001/v0/")

	//TryGetURL("http://foo-service:12345/foo/")
	//TryGetURL("http://foo-service:12345/")

	ipfsName := ""
	// Try using the go-ipfs-api
	sh = shell.NewShell("ipfs-ui:5001")
	for i := 0; i < 1; i++ {
		resp, err := makeObject(formData.buffer.data)
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
