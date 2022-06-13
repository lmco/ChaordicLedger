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
		{CreationTimestamp: time.Now(), ID: "68b2bc65-b487-45b5-b166-52fe496515f9", Base64EncodedContent: "aZM+rwqJuL4EkDL99P+z29WeoznFi8hSZ+FGw7k+n264GKYW4jEuUw8KaauIC3whG9EgwBwSBV5AVCQttivZHUrPTAeP22XyKhMeQ570/62nNIxuOUtlSjPYWXixJMwmKErJsD42xMUDDpUU3tJdrWi7X7fDt703dulQiTSyp2v7fksj58PDRfe+CYTgxwaKt7BtIulA2c9/rnvS5GZypFL++RDLHX6cGKd5LoJMH25NZNVr/BazWhcqkesUij5P8yAzh+hjhndZQBw3Mf3xOR5vhuEnMceGHVRCj6U8de5x60MtjWJcL5lyl2R9VlH+VYqklWqupc7fzHln5+bezzaca59ARr/EylLk6U8hxyU7/rKYUVWW0Oz4qghZONtQhIweNU7GYueARVPKzwis1s2wgq4vN4Ad43mPAu1A0txG/ThG4bM8ZkMm0bcVvx8YwdRpARirCMgkpAD3p9GBWixBcuXNxeBbDnlj66uzCdWvsjPQyCSjdGs7zXiQDxCDtAi4uYSajUYe+ecSVTNmeNmxHHdRhvZSWAzmLlyGYOOFKdUfu/m1OPbwQ4X6/jryDyBOg8f+6CjrNtca1Tmx8PvpKSqbyOkTEFYlgvoARYrWihuvwgfcmESDjWIkvjOBa3QunQ0DZyy5EAyUeZqdpm8IgYzhXvrJsggwFhTJ+gArls2W1cOWG2T076f4lWhxzPohTc/bGkwjTJ0GrM+zMnqKDqBvpKiATt2uH+TEs3/L+CjALZUHWSL4w41QeFPvZfH4ZoncvYJ4OFEVsgJ5jrCi77kIcQiw+Wd0/NdwSOa/nb9hBxPK4cwFqMiPP1+7sEzeMX/wMjoK/zoCgUfglXF+YtjLnLoJqOQ6f4n6hKwVGzZfqd6/RxfWcb9ieR83sgSsu6ezfwOMSTUR5fox8C4g0dlnZHDlacVgJIASytCwIoYnsBMSFF8LT+f/hDT79kN1X7lh3yjHwwdT8hWZyCRLj+pNqHpadwHOza2n2VIIC5xoMwrfLG2RQ1D1P1nj+MBuMBEVywWz0XZraeyZSCTNnrvynzN3rJIgCa8/EpWx52Cn+D3t3Zj77oL0351AK6+KbQI5fivxVjjEsuFk/CeDidmHlDydNATgTVY//9WoKIxwoUOVMvLi98JfI19/OWlF+SlppzHuGejfsinxabBKhWACyjl8iBxYWNx6jCL/hnf2+sAjJM8bT7hIKXseeJNVJ2Jv/+dJi2t1MHnkWsyaFXu8rJ3T8VenoMGyfxUj3WTpME0UrvLS2Fya/uP9d/Oc3YWHJVBgoy/kh5lL8jdzIjSrI3X3DCZn4APwtN2uB5NGVK1youxlzfaigIFp9drxqZLdISAeYsDD4sRbCw=="},
		{CreationTimestamp: time.Now(), ID: "d762245e-acd1-4162-95b5-0da6d2889893", Base64EncodedContent: "aZM+rwqJuL4EkDL99P+z29WeoznFi8hSZ+FGw7k+n264GKYW4jEuUw8KaauIC3whG9EgwBwSBV5AVCQttivZHUrPTAeP22XyKhMeQ570/62nNIxuOUtlSjPYWXixJMwmKErJsD42xMUDDpUU3tJdrWi7X7fDt703dulQiTSyp2v7fksj58PDRfe+CYTgxwaKt7BtIulA2c9/rnvS5GZypFL++RDLHX6cGKd5LoJMH25NZNVr/BazWhcqkesUij5P8yAzh+hjhndZQBw3Mf3xOR5vhuEnMceGHVRCj6U8de5x60MtjWJcL5lyl2R9VlH+VYqklWqupc7fzHln5+bezzaca59ARr/EylLk6U8hxyU7/rKYUVWW0Oz4qghZONtQhIweNU7GYueARVPKzwis1s2wgq4vN4Ad43mPAu1A0txG/ThG4bM8ZkMm0bcVvx8YwdRpARirCMgkpAD3p9GBWixBcuXNxeBbDnlj66uzCdWvsjPQyCSjdGs7zXiQDxCDtAi4uYSajUYe+ecSVTNmeNmxHHdRhvZSWAzmLlyGYOOFKdUfu/m1OPbwQ4X6/jryDyBOg8f+6CjrNtca1Tmx8PvpKSqbyOkTEFYlgvoARYrWihuvwgfcmESDjWIkvjOBa3QunQ0DZyy5EAyUeZqdpm8IgYzhXvrJsggwFhTJ+gArls2W1cOWG2T076f4lWhxzPohTc/bGkwjTJ0GrM+zMnqKDqBvpKiATt2uH+TEs3/L+CjALZUHWSL4w41QeFPvZfH4ZoncvYJ4OFEVsgJ5jrCi77kIcQiw+Wd0/NdwSOa/nb9hBxPK4cwFqMiPP1+7sEzeMX/wMjoK/zoCgUfglXF+YtjLnLoJqOQ6f4n6hKwVGzZfqd6/RxfWcb9ieR83sgSsu6ezfwOMSTUR5fox8C4g0dlnZHDlacVgJIASytCwIoYnsBMSFF8LT+f/hDT79kN1X7lh3yjHwwdT8hWZyCRLj+pNqHpadwHOza2n2VIIC5xoMwrfLG2RQ1D1P1nj+MBuMBEVywWz0XZraeyZSCTNnrvynzN3rJIgCa8/EpWx52Cn+D3t3Zj77oL0351AK6+KbQI5fivxVjjEsuFk/CeDidmHlDydNATgTVY//9WoKIxwoUOVMvLi98JfI19/OWlF+SlppzHuGejfsinxabBKhWACyjl8iBxYWNx6jCL/hnf2+sAjJM8bT7hIKXseeJNVJ2Jv/+dJi2t1MHnkWsyaFXu8rJ3T8VenoMGyfxUj3WTpME0UrvLS2Fya/uP9d/Oc3YWHJVBgoy/kh5lL8jdzIjSrI3X3DCZn4APwtN2uB5NGVK1youxlzfaigIFp9drxqZLdISAeYsDD4sRbCw=="},
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
	fmt.Println("Done listing files")
	fmt.Println("With files on root")
	TestAPI(baseURL + "files/ls?arg=/")
	fmt.Println("Done listing files")
	fmt.Println("Key list")
	TestAPI(baseURL + "key/list")
	fmt.Println("Done Key list")
	fmt.Println("Pin list")
	TestAPI(baseURL + "pin/ls")
	fmt.Println("Done Pin list")
	fmt.Println("Diag")
	TestAPI(baseURL + "diag/sys")
	fmt.Println("Done Diag")
	fmt.Println("Version")
	TestAPI(baseURL + "version")
	fmt.Println("Done version")
	fmt.Println("Log tail")
	TestAPI(baseURL + "log/tail")
	fmt.Println("Done log tail")
}

func TryGetURL(url string) {
	fmt.Println("Trying ", url)
	resp, err := http.Get(url)
	if err != nil {
		fmt.Fatalln(err)
	}

	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Fatalln(err)
	}

	fmt.Println(string(body))
}

// CreateContent issues a new content to the world state with given details.
func (s *SmartContract) CreateContent(ctx contractapi.TransactionContextInterface, creationTimestamp time.Time, id string, base64encodedContent string) error {
	exists, err := s.ContentExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("Content %s already exists", id)
	}

	content := Content{
		CreationTimestamp:    creationTimestamp,
		ID:                   id,
		Base64EncodedContent: base64encodedContent,
	}

	contentJSON, err := json.Marshal(content)
	if err != nil {
		return err
	}

	// _, err := listFiles()
	// if err != nil {
	// 	fmt.Println("err: ", err)
	// }
	// fmt.Println("Done listing files via API module")

	// TestUploadFolderRaw()
	// fmt.Println("we're okay, too!")

	// Test HTTP connectivity

	TryListingFiles("http://ipfs-ui:5001/api/v0/")
	TryListingFiles("http://ipfs-ui:5001/api/api/v0/")
	TryListingFiles("http://ipfs-ui:5001/v0/")

	TryGetURL("http://foo-service:12345/foo/")
	TryGetURL("http://foo-service:12345/")

	// Try using the go-ipfs-api
	sh = shell.NewShell("ipfs-ui:5001")
	for i := 0; i < 1; i++ {
		_, err := makeRandomObject()
		if err != nil {
			fmt.Println("err: ", err)
		}
		fmt.Println("Done making random object via API module")
	}

	return ctx.GetStub().PutState(id, contentJSON)
}
