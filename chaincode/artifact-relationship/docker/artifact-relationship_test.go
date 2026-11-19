package main

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shimtest"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func newLedger(t *testing.T) (*SmartContract, *contractapi.TransactionContext, *shimtest.MockStub) {
	t.Helper()
	stub := shimtest.NewMockStub("artifact-relationship", nil)
	stub.MockTransactionStart("tx1")
	ctx := new(contractapi.TransactionContext)
	ctx.SetStub(stub)
	return new(SmartContract), ctx, stub
}

// graph stands in for the graph service: it records each post's body and
// content type, and points graphServiceURL at itself for the test.
type graph struct {
	mu     sync.Mutex
	bodies []string
	types  []string
}

func newGraph(t *testing.T) *graph {
	t.Helper()
	g := &graph{}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b, _ := ioutil.ReadAll(r.Body)
		g.mu.Lock()
		g.bodies = append(g.bodies, string(b))
		g.types = append(g.types, r.Header.Get("Content-Type"))
		g.mu.Unlock()
	}))
	old := graphServiceURL
	graphServiceURL = srv.URL
	t.Cleanup(func() { graphServiceURL = old; srv.Close() })
	return g
}

// onlyRecord is the world state's one record: its key and its bytes.
func onlyRecord(t *testing.T, stub *shimtest.MockStub) (string, string) {
	t.Helper()
	if len(stub.State) != 1 {
		t.Fatalf("the world state holds %d records, want 1", len(stub.State))
	}
	for k, v := range stub.State {
		return k, string(v)
	}
	return "", ""
}

func TestCreateRelationshipRecordsItAndPostsItToTheGraph(t *testing.T) {
	g := newGraph(t)
	s, ctx, stub := newLedger(t)
	if err := s.CreateRelationship(ctx, "node-a", "node-b"); err != nil {
		t.Fatal(err)
	}
	// The graph service reads "Type" and "Data" (graph/httpserver.py), so
	// these keys are the interface: pin the bytes.
	want := `{"Type":"relationship","Data":{"NodeIDA":"node-a","NodeIDB":"node-b"}}`
	key, value := onlyRecord(t, stub)
	if value != want {
		t.Errorf("stored\n  %s\nwant\n  %s", value, want)
	}
	if _, err := time.Parse(time.RFC3339, key); err != nil {
		t.Errorf("the record's key %q is not an RFC 3339 time: %v", key, err)
	}
	if len(g.bodies) != 1 || g.bodies[0] != want || g.types[0] != "application/json" {
		t.Errorf("the graph service received %q as %q", g.bodies, g.types)
	}
}

func TestCreateNodeRecordsItAndPostsItToTheGraph(t *testing.T) {
	g := newGraph(t)
	s, ctx, stub := newLedger(t)
	if err := s.CreateNode(ctx, "node-1", "file-1"); err != nil {
		t.Fatal(err)
	}
	want := `{"Type":"node","Data":{"NodeID":"node-1","FileID":"file-1"}}`
	if _, value := onlyRecord(t, stub); value != want {
		t.Errorf("stored\n  %s\nwant\n  %s", value, want)
	}
	if len(g.bodies) != 1 || g.bodies[0] != want || g.types[0] != "application/json" {
		t.Errorf("the graph service received %q as %q", g.bodies, g.types)
	}
}

// downGraph points graphServiceURL at an address nothing answers on.
func downGraph(t *testing.T) {
	t.Helper()
	srv := httptest.NewServer(http.NotFoundHandler())
	url := srv.URL
	srv.Close()
	old := graphServiceURL
	graphServiceURL = url
	t.Cleanup(func() { graphServiceURL = old })
}

func TestARelationshipIsStillRecordedWhenTheGraphServiceIsDown(t *testing.T) {
	// The post failing returned a nil response, and closing its body
	// panicked: the transaction failed whenever the graph service was down.
	downGraph(t)
	s, ctx, stub := newLedger(t)
	if err := s.CreateRelationship(ctx, "node-a", "node-b"); err != nil {
		t.Fatal(err)
	}
	if _, value := onlyRecord(t, stub); value != `{"Type":"relationship","Data":{"NodeIDA":"node-a","NodeIDB":"node-b"}}` {
		t.Errorf("stored %s", value)
	}
}

func TestANodeIsStillRecordedWhenTheGraphServiceIsDown(t *testing.T) {
	downGraph(t)
	s, ctx, stub := newLedger(t)
	if err := s.CreateNode(ctx, "node-1", "file-1"); err != nil {
		t.Fatal(err)
	}
	onlyRecord(t, stub)
}

func TestInitLedgerWritesNothing(t *testing.T) {
	s, ctx, stub := newLedger(t)
	if err := s.InitLedger(ctx); err != nil || len(stub.State) != 0 {
		t.Fatalf("InitLedger: %v, %d records", err, len(stub.State))
	}
}
