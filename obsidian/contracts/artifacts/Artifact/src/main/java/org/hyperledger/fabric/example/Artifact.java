package org.hyperledger.fabric.example;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Base64;
import java.util.HashSet;
import java.util.Set;
import edu.cmu.cs.obsidian.chaincode.BadArgumentException;
import edu.cmu.cs.obsidian.chaincode.BadTransactionException;
import edu.cmu.cs.obsidian.chaincode.HyperledgerChaincodeBase;
import edu.cmu.cs.obsidian.chaincode.IllegalOwnershipConsumptionException;
import edu.cmu.cs.obsidian.chaincode.InvalidStateException;
import edu.cmu.cs.obsidian.chaincode.NoSuchTransactionException;
import edu.cmu.cs.obsidian.chaincode.ObsidianRevertException;
import edu.cmu.cs.obsidian.chaincode.ObsidianSerialized;
import edu.cmu.cs.obsidian.chaincode.ReentrancyException;
import edu.cmu.cs.obsidian.chaincode.SerializationState;
import edu.cmu.cs.obsidian.chaincode.StateLockException;
import edu.cmu.cs.obsidian.chaincode.WrongNumberOfArgumentsException;
import org.hyperledger.fabric.example.ArtifactsOuterClass.ArtifactOrGUID;

public class Artifact
    extends HyperledgerChaincodeBase
    implements ObsidianSerialized
{
    private Artifact.State_Artifact __state;
    private Artifact.State_Initialized __stateInitialized;
    private Artifact.State_Stored __stateStored;
    private String __guid;
    private boolean __modified;
    private boolean __loaded;
    private boolean __constructorReturnsOwned = false;
    public String upstreamArtifact = "";
    public String ipfsPath = "";
    public String uuid = "";
    public String friendlyname = "";
    static HashSet<java.lang.String> transactionsWithOwnedReceiversAtBeginning;
    static HashSet<java.lang.String> transactionsWithOwnedReceiversAtEnd;
    public boolean __isInsideInvocation = false;

    public Artifact(String __guid_) {
        __modified = false;
        __loaded = false;
        __guid = __guid_;
    }

    public Artifact(String targetIpfsPath, String targetUpstreamArtifact, SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        new_Artifact(targetIpfsPath, targetUpstreamArtifact, __st);
    }

    public Artifact(SerializationState __st)
        throws ObsidianRevertException
    {
        new_Artifact(__st);
    }

    public Artifact() {
        __modified = true;
        __loaded = false;
    }

    public Artifact.State_Artifact getState(SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        if (__st!= null) {
            this.__restoreObject(__st);
        }
        return __state;
    }

    private void __oldStateToNull()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        if (this.getState(null) == Artifact.State_Artifact.Initialized) {
            __stateInitialized = null;
        }
        if (this.getState(null) == Artifact.State_Artifact.Stored) {
            __stateStored = null;
        }
    }

    public String __getGUID() {
        return __guid;
    }

    public Set<ObsidianSerialized> __resetModified(Set<ObsidianSerialized> checked)
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        checked.add(this);
        Set<ObsidianSerialized> result = new HashSet<ObsidianSerialized>();
        if (!__loaded) {
            return result;
        }
        if (this.__modified) {
            result.add(this);
        }
        __modified = false;
        return result;
    }

    public boolean __upstreamArtifactIsInScope()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        return Arrays.asList(new String[] {"Stored"}).contains(this.getState(null).toString());
    }

    public boolean __ipfsPathIsInScope()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        return Arrays.asList(new String[] {"Stored"}).contains(this.getState(null).toString());
    }

    public boolean __uuidIsInScope()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        return Arrays.asList(new String[] {"Initialized", "Stored"}).contains(this.getState(null).toString());
    }

    public boolean __friendlynameIsInScope()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        return Arrays.asList(new String[] {"Initialized", "Stored"}).contains(this.getState(null).toString());
    }

    public void __restoreObject(SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        __guid = "Artifact";
        if (!__loaded) {
            String __archive_string = __st.getStub().getStringState(__guid);
            byte[] __archive_bytes = __archive_string.getBytes();
            __initFromArchiveBytes(__archive_bytes, __st);
            __loaded = true;
        }
    }

    protected void __unload() {
        __loaded = false;
    }

    private void new_Artifact(String targetIpfsPath, String targetUpstreamArtifact, SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        __constructorReturnsOwned = true;
        this.ipfsPath = targetIpfsPath;
        __modified = true;
        this.upstreamArtifact = targetUpstreamArtifact;
        __modified = true;
        this.uuid = "someUUID";
        __modified = true;
        this.friendlyname = "Some Friendly Name";
        __modified = true;
        __oldStateToNull();
        __stateInitialized = new Artifact.State_Initialized();
        __state = Artifact.State_Artifact.Initialized;
        __modified = true;
        __guid = "Artifact";
        __modified = true;
        __loaded = true;
        __st.putEntry(__guid, this);
        __st.mapReturnedObject(this, false);
    }

    @Override
    public boolean constructorReturnsOwnedReference() {
        return __constructorReturnsOwned;
    }

    public void remove(SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        __restoreObject(__st);
        if (this.getState(__st)!= org.hyperledger.fabric.example.Artifact.State_Artifact.Stored) {
            throw new InvalidStateException(this, this.getState(__st).toString(), "remove");
        }
        try {
            if (__isInsideInvocation) {
                throw new ReentrancyException("artifacts.obs", 0);
            } else {
                __isInsideInvocation = true;
                __oldStateToNull();
                __stateInitialized = new Artifact.State_Initialized();
                __state = Artifact.State_Artifact.Initialized;
                __modified = true;
            }
        } finally {
            __isInsideInvocation = false;
        }
    }

    private void new_Artifact(SerializationState __st) {
        __guid = "Artifact";
        upstreamArtifact = "";
        ipfsPath = "";
        uuid = "";
        friendlyname = "";
        __st.flushEntries();
    }

    @Override
    public boolean methodReceiverIsOwnedAtBeginning(java.lang.String methodName) {
        if (transactionsWithOwnedReceiversAtBeginning == null) {
            transactionsWithOwnedReceiversAtBeginning = new HashSet<java.lang.String>();
            transactionsWithOwnedReceiversAtBeginning.add("remove");
        }
        return transactionsWithOwnedReceiversAtBeginning.contains(methodName);
    }

    @Override
    public boolean methodReceiverIsOwnedAtEnd(java.lang.String methodName) {
        if (transactionsWithOwnedReceiversAtEnd == null) {
            transactionsWithOwnedReceiversAtEnd = new HashSet<java.lang.String>();
            transactionsWithOwnedReceiversAtBeginning.add("remove");
        }
        return transactionsWithOwnedReceiversAtEnd.contains(methodName);
    }

    public byte[] query(SerializationState __st, String transName, byte[][] args) {
        return new byte[ 0 ] ;
    }

    public byte[] getChaincodeID() {
        return new byte[ 0 ] ;
    }

    public static void main(String[] args) {
        Artifact instance = new Artifact("Artifact");
        instance.serializationState.putEntry(instance.__guid, instance);
        instance.delegatedMain(args);
    }

    public byte[] run(SerializationState __st, String transName, byte[][] args)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, NoSuchTransactionException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        __restoreObject(__st);
        __st.mapReturnedObject(this, false);
        byte[] returnBytes = new byte[ 0 ] ;
        if (transName.equals("remove")) {
            if (args.length == 0) {
                this.remove(__st);
            } else {
                System.err.println("Wrong number of arguments in invocation.");
                throw new WrongNumberOfArgumentsException("remove", args.length, 0);
            }
        } else {
            if (transName.equals("getState")) {
                if (args.length == 0) {
                    returnBytes = Base64 .getEncoder().encode(this.getState(__st).name().getBytes(StandardCharsets.UTF_8));
                } else {
                    System.err.println("Wrong number of arguments in invocation.");
                    throw new WrongNumberOfArgumentsException("getState", args.length, 0);
                }
            } else {
                throw new NoSuchTransactionException();
            }
        }
        return returnBytes;
    }

    @java.lang.Override
    public byte[] __archiveBytes()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        return this.archive().toByteArray();
    }

    @java.lang.Override
    public byte[] __wrappedArchiveBytes()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        org.hyperledger.fabric.example.ArtifactsOuterClass.ArtifactOrGUID.Builder builder = org.hyperledger.fabric.example.ArtifactsOuterClass.ArtifactOrGUID.newBuilder();
        builder.setObj(this.archive());
        ArtifactOrGUID wrappedObject = builder.build();
        return wrappedObject.toByteArray();
    }

    public org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact archive()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Builder builder = org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.newBuilder();
        builder.setGuid(__guid);
        if (upstreamArtifact!= null) {
            builder.setUpstreamArtifact(upstreamArtifact);
        }
        if (ipfsPath!= null) {
            builder.setIpfsPath(ipfsPath);
        }
        if (uuid!= null) {
            builder.setUuid(uuid);
        }
        if (friendlyname!= null) {
            builder.setFriendlyname(friendlyname);
        }
        if (Artifact.State_Artifact.Initialized == this.getState(null)) {
            builder.setStateInitialized(__stateInitialized.archive());
        }
        if (Artifact.State_Artifact.Stored == this.getState(null)) {
            builder.setStateStored(__stateStored.archive());
        }
        return builder.build();
    }

    public void initFromArchive(Object archiveIn, SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact archive = ((org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact) archiveIn);
        __guid = archive.getGuid();
        if (archive.getStateCase().equals((org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.StateCase.STATEINITIALIZED))) {
            __state = Artifact.State_Artifact.Initialized;
        }
        if (archive.getStateCase().equals((org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.StateCase.STATESTORED))) {
            __state = Artifact.State_Artifact.Stored;
        }
        if (__upstreamArtifactIsInScope()) {
            if (!archive.getUpstreamArtifact().isEmpty()) {
                upstreamArtifact = archive.getUpstreamArtifact();
            }
        }
        if (__ipfsPathIsInScope()) {
            if (!archive.getIpfsPath().isEmpty()) {
                ipfsPath = archive.getIpfsPath();
            }
        }
        if (__uuidIsInScope()) {
            if (!archive.getUuid().isEmpty()) {
                uuid = archive.getUuid();
            }
        }
        if (__friendlynameIsInScope()) {
            if (!archive.getFriendlyname().isEmpty()) {
                friendlyname = archive.getFriendlyname();
            }
        }
        __loaded = true;
    }

    public Artifact __initFromArchiveBytes(byte[] archiveBytes, SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact archive = org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.parseFrom(archiveBytes);
        initFromArchive(archive, __st);
        __loaded = true;
        return this;
    }

    @java.lang.Override
    public byte[] init(SerializationState __st, byte[][] args)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        if (args.length!= 2) {
            throw new com.google.protobuf.InvalidProtocolBufferException("Incorrect number of arguments to constructor.");
        }
        new_Artifact(new java.lang.String(args[ 0 ], StandardCharsets.UTF_8), new java.lang.String(args[ 1 ], StandardCharsets.UTF_8), __st);
        return new byte[ 0 ] ;
    }

    public enum State_Artifact {
        Initialized,
        Stored;
    }

    public class State_Initialized {

        public void initFromArchive(org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Initialized archive) {
        }

        public Artifact.State_Initialized __initFromArchiveBytes(byte[] archiveBytes)
            throws com.google.protobuf.InvalidProtocolBufferException
        {
            org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Initialized archive = org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Initialized.parseFrom(archiveBytes);
            initFromArchive(archive);
            return this;
        }

        public org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Initialized archive()
            throws com.google.protobuf.InvalidProtocolBufferException
        {
            org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Initialized.Builder builder = org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Initialized.newBuilder();
            return builder.build();
        }
    }

    public class State_Stored {

        public void initFromArchive(org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Stored archive) {
        }

        public Artifact.State_Stored __initFromArchiveBytes(byte[] archiveBytes)
            throws com.google.protobuf.InvalidProtocolBufferException
        {
            org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Stored archive = org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Stored.parseFrom(archiveBytes);
            initFromArchive(archive);
            return this;
        }

        public org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Stored archive()
            throws com.google.protobuf.InvalidProtocolBufferException
        {
            org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Stored.Builder builder = org.hyperledger.fabric.example.ArtifactsOuterClass.Artifact.Stored.newBuilder();
            return builder.build();
        }
    }
}
