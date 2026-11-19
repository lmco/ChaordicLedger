package main

import (
	"strings"
	"testing"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shimtest"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// newLedger returns the contract and a transaction context over an empty
// in-memory world state (Fabric's own MockStub), inside an open transaction.
func newLedger(t *testing.T) (*SmartContract, *contractapi.TransactionContext, *shimtest.MockStub) {
	t.Helper()
	stub := shimtest.NewMockStub("artifact-metadata", nil)
	stub.MockTransactionStart("tx1")
	ctx := new(contractapi.TransactionContext)
	ctx.SetStub(stub)
	return new(SmartContract), ctx, stub
}

var when = time.Date(2024, time.March, 5, 6, 7, 8, 0, time.UTC)

func create(t *testing.T, s *SmartContract, ctx *contractapi.TransactionContext, id string, size int) {
	t.Helper()
	if err := s.CreateMetadata(ctx, when, "h-"+id, "SHA512", id, size); err != nil {
		t.Fatalf("CreateMetadata(%s): %v", id, err)
	}
}

func wantError(t *testing.T, err error, part string) {
	t.Helper()
	if err == nil || !strings.Contains(err.Error(), part) {
		t.Fatalf("want an error containing %q, got %v", part, err)
	}
}

func TestInitLedgerSeedsTheTwoSampleArtifacts(t *testing.T) {
	s, ctx, _ := newLedger(t)
	if err := s.InitLedger(ctx); err != nil {
		t.Fatal(err)
	}
	all, err := s.GetAllMetadata(ctx)
	if err != nil {
		t.Fatal(err)
	}
	sizes := map[string]int{}
	for _, m := range all {
		sizes[m.ID] = m.SizeInBytes
		if !m.CreationTimestamp.Equal(seedCreationTimestamp) || m.HashType != "SHA512" || len(m.Hash) != 128 {
			t.Errorf("seed record %s: %+v", m.ID, m)
		}
	}
	want := map[string]int{"68b2bc65-b487-45b5-b166-52fe496515f9": 1024, "d762245e-acd1-4162-95b5-0da6d2889893": 394}
	if len(sizes) != len(want) {
		t.Fatalf("seeded %v, want %v", sizes, want)
	}
	for id, size := range want {
		if sizes[id] != size {
			t.Errorf("%s: size %d, want %d", id, sizes[id], size)
		}
	}
}

func TestCreatedMetadataReadsBackFieldByField(t *testing.T) {
	s, ctx, _ := newLedger(t)
	if err := s.CreateMetadata(ctx, when, "abc", "SHA256", "id-1", 42); err != nil {
		t.Fatal(err)
	}
	m, err := s.ReadMetadata(ctx, "id-1")
	if err != nil {
		t.Fatal(err)
	}
	if !m.CreationTimestamp.Equal(when) || m.Hash != "abc" || m.HashType != "SHA256" || m.ID != "id-1" || m.SizeInBytes != 42 {
		t.Fatalf("read back %+v", m)
	}
}

func TestTheStoredJSONHasTheKeysClientsRead(t *testing.T) {
	// The world state's bytes are what other peers and clients read: pin them.
	s, ctx, stub := newLedger(t)
	if err := s.CreateMetadata(ctx, when, "abc", "SHA256", "id-1", 42); err != nil {
		t.Fatal(err)
	}
	got := string(stub.State["id-1"])
	want := `{"CreationTimestamp":"2024-03-05T06:07:08Z","Hash":"abc","HashType":"SHA256","ID":"id-1","SizeInBytes":42}`
	if got != want {
		t.Fatalf("stored\n  %s\nwant\n  %s", got, want)
	}
}

func TestCreateRefusesAnExistingIDAndKeepsTheRecord(t *testing.T) {
	s, ctx, _ := newLedger(t)
	create(t, s, ctx, "id-1", 1)
	wantError(t, s.CreateMetadata(ctx, when, "other", "MD5", "id-1", 2), "already exists")
	m, err := s.ReadMetadata(ctx, "id-1")
	if err != nil || m.Hash != "h-id-1" || m.SizeInBytes != 1 {
		t.Fatalf("the first record changed: %+v, %v", m, err)
	}
}

func TestReadingAMissingIDIsAnError(t *testing.T) {
	s, ctx, _ := newLedger(t)
	_, err := s.ReadMetadata(ctx, "nope")
	wantError(t, err, "does not exist")
}

func TestExistsTellsPresentFromAbsent(t *testing.T) {
	s, ctx, _ := newLedger(t)
	create(t, s, ctx, "id-1", 1)
	for id, want := range map[string]bool{"id-1": true, "id-2": false} {
		got, err := s.MetadataExists(ctx, id)
		if err != nil || got != want {
			t.Errorf("MetadataExists(%s) = %v, %v; want %v", id, got, err, want)
		}
	}
}

func TestUpdateReplacesEveryField(t *testing.T) {
	s, ctx, _ := newLedger(t)
	create(t, s, ctx, "id-1", 1)
	later := when.Add(time.Hour)
	if err := s.UpdateMetadata(ctx, later, "new", "SHA1", "id-1", 7); err != nil {
		t.Fatal(err)
	}
	m, err := s.ReadMetadata(ctx, "id-1")
	if err != nil {
		t.Fatal(err)
	}
	if !m.CreationTimestamp.Equal(later) || m.Hash != "new" || m.HashType != "SHA1" || m.SizeInBytes != 7 {
		t.Fatalf("updated to %+v", m)
	}
}

func TestUpdatingAMissingIDIsAnErrorAndCreatesNothing(t *testing.T) {
	s, ctx, stub := newLedger(t)
	wantError(t, s.UpdateMetadata(ctx, when, "h", "SHA1", "nope", 1), "does not exist")
	if len(stub.State) != 0 {
		t.Fatalf("the world state holds %d records", len(stub.State))
	}
}

func TestDeleteRemovesOnlyThatRecord(t *testing.T) {
	s, ctx, _ := newLedger(t)
	create(t, s, ctx, "id-1", 1)
	create(t, s, ctx, "id-2", 2)
	if err := s.DeleteMetadata(ctx, "id-1"); err != nil {
		t.Fatal(err)
	}
	if ok, _ := s.MetadataExists(ctx, "id-1"); ok {
		t.Fatal("id-1 is still there")
	}
	if ok, _ := s.MetadataExists(ctx, "id-2"); !ok {
		t.Fatal("id-2 went too")
	}
}

func TestDeletingAMissingIDIsAnError(t *testing.T) {
	s, ctx, _ := newLedger(t)
	wantError(t, s.DeleteMetadata(ctx, "nope"), "does not exist")
}

func TestGetAllMetadataOnAnEmptyLedgerIsEmpty(t *testing.T) {
	s, ctx, _ := newLedger(t)
	all, err := s.GetAllMetadata(ctx)
	if err != nil || len(all) != 0 {
		t.Fatalf("got %v, %v", all, err)
	}
}

func TestGetAllMetadataReturnsEachRecordOnce(t *testing.T) {
	s, ctx, _ := newLedger(t)
	for i, id := range []string{"b", "a", "c"} {
		create(t, s, ctx, id, i+1)
	}
	all, err := s.GetAllMetadata(ctx)
	if err != nil {
		t.Fatal(err)
	}
	seen := map[string]int{}
	for _, m := range all {
		seen[m.ID] = m.SizeInBytes
	}
	if len(all) != 3 || seen["b"] != 1 || seen["a"] != 2 || seen["c"] != 3 {
		t.Fatalf("got %v", seen)
	}
}
