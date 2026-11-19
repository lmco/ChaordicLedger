package main

// CreateContent and UpdateContent write to IPFS at a fixed address
// (ipfs-rpc-api:5001), so these tests cover the paths that read and write the
// world state alone.

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shimtest"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func newLedger(t *testing.T) (*SmartContract, *contractapi.TransactionContext, *shimtest.MockStub) {
	t.Helper()
	stub := shimtest.NewMockStub("artifact-content", nil)
	stub.MockTransactionStart("tx1")
	ctx := new(contractapi.TransactionContext)
	ctx.SetStub(stub)
	return new(SmartContract), ctx, stub
}

const seedA, seedB = "68b2bc65-b487-45b5-b166-52fe496515f9", "d762245e-acd1-4162-95b5-0da6d2889893"

func seeded(t *testing.T) (*SmartContract, *contractapi.TransactionContext, *shimtest.MockStub) {
	t.Helper()
	s, ctx, stub := newLedger(t)
	if err := s.InitLedger(ctx); err != nil {
		t.Fatal(err)
	}
	return s, ctx, stub
}

func wantError(t *testing.T, err error, part string) {
	t.Helper()
	if err == nil || !strings.Contains(err.Error(), part) {
		t.Fatalf("want an error containing %q, got %v", part, err)
	}
}

func TestInitLedgerSeedsTheTwoSampleArtifacts(t *testing.T) {
	s, ctx, _ := seeded(t)
	for id, ipfs := range map[string]string{seedA: "None", seedB: "Nada"} {
		c, err := s.ReadContent(ctx, id)
		if err != nil {
			t.Fatal(err)
		}
		if c.ID != id || c.IPFSName != ipfs || c.CreationTimestamp.IsZero() {
			t.Errorf("%s: %+v", id, c)
		}
	}
	all, err := s.GetAllContent(ctx)
	if err != nil || len(all) != 2 {
		t.Fatalf("GetAllContent: %d records, %v", len(all), err)
	}
}

func TestReadingAMissingIDIsAnError(t *testing.T) {
	s, ctx, _ := seeded(t)
	_, err := s.ReadContent(ctx, "nope")
	wantError(t, err, "does not exist")
}

func TestExistsTellsPresentFromAbsent(t *testing.T) {
	s, ctx, _ := seeded(t)
	for id, want := range map[string]bool{seedA: true, "nope": false} {
		got, err := s.ContentExists(ctx, id)
		if err != nil || got != want {
			t.Errorf("ContentExists(%s) = %v, %v; want %v", id, got, err, want)
		}
	}
}

func TestDeleteIsRefusedAndKeepsTheRecord(t *testing.T) {
	s, ctx, _ := seeded(t)
	wantError(t, s.DeleteContent(ctx, "nope"), "does not exist")
	// IPFS has no delete, so neither does the ledger.
	wantError(t, s.DeleteContent(ctx, seedA), "Not implemented")
	if ok, _ := s.ContentExists(ctx, seedA); !ok {
		t.Fatal("the record went")
	}
}

func TestGetAllContentOnAnEmptyLedgerIsEmpty(t *testing.T) {
	s, ctx, _ := newLedger(t)
	all, err := s.GetAllContent(ctx)
	if err != nil || len(all) != 0 {
		t.Fatalf("got %v, %v", all, err)
	}
}

func TestTheJSONHasTheKeysClientsRead(t *testing.T) {
	// The ledger's records and the graph service's posts (which it reads by
	// "Type" and "Data", graph/httpserver.py): pin their bytes.
	when := time.Date(2024, time.March, 5, 6, 7, 8, 0, time.UTC)
	for _, c := range []struct {
		value interface{}
		want  string
	}{
		{Content{CreationTimestamp: when, ID: "id-1", IPFSName: "Qm1"},
			`{"CreationTimestamp":"2024-03-05T06:07:08Z","ID":"id-1","IPFSName":"Qm1"}`},
		{NodeData{Type: "node", Data: Node{NodeID: "Qm1", FileID: "a.txt"}},
			`{"Type":"node","Data":{"NodeID":"Qm1","FileID":"a.txt"}}`},
	} {
		got, err := json.Marshal(c.value)
		if err != nil || string(got) != c.want {
			t.Errorf("marshalled\n  %s (%v)\nwant\n  %s", got, err, c.want)
		}
	}
}

func TestAStoredRecordReadsBack(t *testing.T) {
	s, ctx, stub := newLedger(t)
	when := time.Date(2024, time.March, 5, 6, 7, 8, 0, time.UTC)
	b, _ := json.Marshal(Content{CreationTimestamp: when, ID: "id-1", IPFSName: "Qm1"})
	if err := stub.PutState("id-1", b); err != nil {
		t.Fatal(err)
	}
	c, err := s.ReadContent(ctx, "id-1")
	if err != nil || !c.CreationTimestamp.Equal(when) || c.ID != "id-1" || c.IPFSName != "Qm1" {
		t.Fatalf("read back %+v, %v", c, err)
	}
}
