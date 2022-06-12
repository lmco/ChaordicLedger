package main

import (
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
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

	r := io.LimitReader(u.NewTimeSeededRand(), int64(size))
	sleep()
	return sh.Add(r)
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

	// Try using the go-ipfs-api
	sh = shell.NewShell("ipfs-service:12345")
	for i := 0; i < 200; i++ {
		_, err := makeRandomObject()
		if err != nil {
			fmt.Println("err: ", err)
		}
	}
	fmt.Println("we're okay")

	// // Test HTTP connectivity

	// resp, err := http.Get("http://localhost:8080/api-docs/")
	// if err != nil {
	// 	log.Fatalln(err)
	// }

	// defer resp.Body.Close()

	// body, err := ioutil.ReadAll(resp.Body)
	// if err != nil {
	// 	log.Fatalln(err)
	// }

	// log.Println(string(body))

	return ctx.GetStub().PutState(id, contentJSON)
}
