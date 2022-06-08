package org.hyperledger.fabric.example;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Base64;
import java.util.HashSet;
import java.util.Set;
import com.google.protobuf.ByteString;
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
import org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitchOrGUID;

public class LightSwitch
    extends HyperledgerChaincodeBase
    implements ObsidianSerialized
{
    private LightSwitch.State_LightSwitch __state;
    private LightSwitch.State_On __stateOn;
    private LightSwitch.State_Off __stateOff;
    private String __guid;
    private boolean __modified;
    private boolean __loaded;
    private boolean __constructorReturnsOwned = false;
    public java.math.BigInteger brightness = java.math.BigInteger.valueOf(0);
    public java.math.BigInteger switchLocation = java.math.BigInteger.valueOf(0);
    static HashSet<java.lang.String> transactionsWithOwnedReceiversAtBeginning;
    static HashSet<java.lang.String> transactionsWithOwnedReceiversAtEnd;
    public boolean __isInsideInvocation = false;

    public LightSwitch(String __guid_) {
        __modified = false;
        __loaded = false;
        __guid = __guid_;
    }

    public LightSwitch(SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        new_LightSwitch(__st);
    }

    public LightSwitch() {
        __modified = true;
        __loaded = false;
    }

    public LightSwitch.State_LightSwitch getState(SerializationState __st)
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
        if (this.getState(null) == LightSwitch.State_LightSwitch.Off) {
            __stateOff = null;
        }
        if (this.getState(null) == LightSwitch.State_LightSwitch.On) {
            __stateOn = null;
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

    public boolean __brightnessIsInScope()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        return Arrays.asList(new String[] {"On"}).contains(this.getState(null).toString());
    }

    public boolean __switchLocationIsInScope()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        return Arrays.asList(new String[] {"On", "Off"}).contains(this.getState(null).toString());
    }

    public void __restoreObject(SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        __guid = "LightSwitch";
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

    private void new_LightSwitch(SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        __constructorReturnsOwned = true;
        __oldStateToNull();
        __stateOff = new LightSwitch.State_Off();
        __state = LightSwitch.State_LightSwitch.Off;
        __modified = true;
        __guid = "LightSwitch";
        __modified = true;
        __loaded = true;
        __st.putEntry(__guid, this);
        __st.mapReturnedObject(this, false);
    }

    @Override
    public boolean constructorReturnsOwnedReference() {
        return __constructorReturnsOwned;
    }

    public void foo(SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        __restoreObject(__st);
        try {
            if (__isInsideInvocation) {
                throw new ReentrancyException("simple/lightswitch.obs", 0);
            } else {
                __isInsideInvocation = true;
                LightSwitch s = new LightSwitch(__st);
                s.turnOn(java.math.BigInteger.valueOf(50), __st);
            }
        } finally {
            __isInsideInvocation = false;
        }
    }

    public void turnOn(java.math.BigInteger b, SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        __restoreObject(__st);
        if (this.getState(__st)!= org.hyperledger.fabric.example.LightSwitch.State_LightSwitch.Off) {
            throw new InvalidStateException(this, this.getState(__st).toString(), "turnOn");
        }
        try {
            if (__isInsideInvocation) {
                throw new ReentrancyException("simple/lightswitch.obs", 0);
            } else {
                __isInsideInvocation = true;
                java.math.BigInteger __On__init__brightness = b;
                __oldStateToNull();
                __stateOn = new LightSwitch.State_On();
                __state = LightSwitch.State_LightSwitch.On;
                __modified = true;
                this.brightness = __On__init__brightness;
            }
        } finally {
            __isInsideInvocation = false;
        }
    }

    public void turnOff(SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        __restoreObject(__st);
        if (this.getState(__st)!= org.hyperledger.fabric.example.LightSwitch.State_LightSwitch.On) {
            throw new InvalidStateException(this, this.getState(__st).toString(), "turnOff");
        }
        try {
            if (__isInsideInvocation) {
                throw new ReentrancyException("simple/lightswitch.obs", 0);
            } else {
                __isInsideInvocation = true;
                __oldStateToNull();
                __stateOff = new LightSwitch.State_Off();
                __state = LightSwitch.State_LightSwitch.Off;
                __modified = true;
            }
        } finally {
            __isInsideInvocation = false;
        }
    }

    @Override
    public boolean methodReceiverIsOwnedAtBeginning(java.lang.String methodName) {
        if (transactionsWithOwnedReceiversAtBeginning == null) {
            transactionsWithOwnedReceiversAtBeginning = new HashSet<java.lang.String>();
            transactionsWithOwnedReceiversAtBeginning.add("turnOn");
            transactionsWithOwnedReceiversAtBeginning.add("turnOff");
        }
        return transactionsWithOwnedReceiversAtBeginning.contains(methodName);
    }

    @Override
    public boolean methodReceiverIsOwnedAtEnd(java.lang.String methodName) {
        if (transactionsWithOwnedReceiversAtEnd == null) {
            transactionsWithOwnedReceiversAtEnd = new HashSet<java.lang.String>();
            transactionsWithOwnedReceiversAtBeginning.add("turnOn");
            transactionsWithOwnedReceiversAtBeginning.add("turnOff");
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
        LightSwitch instance = new LightSwitch("LightSwitch");
        instance.serializationState.putEntry(instance.__guid, instance);
        instance.delegatedMain(args);
    }

    public byte[] run(SerializationState __st, String transName, byte[][] args)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, NoSuchTransactionException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        __restoreObject(__st);
        __st.mapReturnedObject(this, false);
        byte[] returnBytes = new byte[ 0 ] ;
        if (transName.equals("turnOff")) {
            if (args.length == 0) {
                this.turnOff(__st);
            } else {
                System.err.println("Wrong number of arguments in invocation.");
                throw new WrongNumberOfArgumentsException("turnOff", args.length, 0);
            }
        } else {
            if (transName.equals("turnOn")) {
                if (args.length == 1) {
                    java.math.BigInteger unmarshalledInt0 = new java.math.BigInteger(new java.lang.String(args[ 0 ], StandardCharsets.UTF_8));
                    if (unmarshalledInt0 == null) {
                        throw new BadArgumentException(new java.lang.String(args[ 0 ], StandardCharsets.UTF_8));
                    }
                    java.math.BigInteger b = unmarshalledInt0;
                    this.turnOn(b, __st);
                } else {
                    System.err.println("Wrong number of arguments in invocation.");
                    throw new WrongNumberOfArgumentsException("turnOn", args.length, 1);
                }
            } else {
                if (transName.equals("foo")) {
                    if (args.length == 0) {
                        this.foo(__st);
                    } else {
                        System.err.println("Wrong number of arguments in invocation.");
                        throw new WrongNumberOfArgumentsException("foo", args.length, 0);
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
        org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitchOrGUID.Builder builder = org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitchOrGUID.newBuilder();
        builder.setObj(this.archive());
        LightSwitchOrGUID wrappedObject = builder.build();
        return wrappedObject.toByteArray();
    }

    public org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch archive()
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.Builder builder = org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.newBuilder();
        builder.setGuid(__guid);
        if (brightness!= null) {
            builder.setBrightness(ByteString.copyFrom(brightness.toByteArray()));
        }
        if (switchLocation!= null) {
            builder.setSwitchLocation(ByteString.copyFrom(switchLocation.toByteArray()));
        }
        if (LightSwitch.State_LightSwitch.On == this.getState(null)) {
            builder.setStateOn(__stateOn.archive());
        }
        if (LightSwitch.State_LightSwitch.Off == this.getState(null)) {
            builder.setStateOff(__stateOff.archive());
        }
        return builder.build();
    }

    public void initFromArchive(Object archiveIn, SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch archive = ((org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch) archiveIn);
        __guid = archive.getGuid();
        if (archive.getStateCase().equals((org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.StateCase.STATEON))) {
            __state = LightSwitch.State_LightSwitch.On;
        }
        if (archive.getStateCase().equals((org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.StateCase.STATEOFF))) {
            __state = LightSwitch.State_LightSwitch.Off;
        }
        if (__brightnessIsInScope()) {
            if (!archive.getBrightness().isEmpty()) {
                brightness = new java.math.BigInteger(archive.getBrightness().toByteArray());
            }
        }
        if (__switchLocationIsInScope()) {
            if (!archive.getSwitchLocation().isEmpty()) {
                switchLocation = new java.math.BigInteger(archive.getSwitchLocation().toByteArray());
            }
        }
        __loaded = true;
    }

    public LightSwitch __initFromArchiveBytes(byte[] archiveBytes, SerializationState __st)
        throws com.google.protobuf.InvalidProtocolBufferException
    {
        org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch archive = org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.parseFrom(archiveBytes);
        initFromArchive(archive, __st);
        __loaded = true;
        return this;
    }

    @java.lang.Override
    public byte[] init(SerializationState __st, byte[][] args)
        throws com.google.protobuf.InvalidProtocolBufferException, BadArgumentException, BadTransactionException, IllegalOwnershipConsumptionException, InvalidStateException, ObsidianRevertException, ReentrancyException, StateLockException, WrongNumberOfArgumentsException
    {
        if (args.length!= 0) {
            throw new com.google.protobuf.InvalidProtocolBufferException("Incorrect number of arguments to constructor.");
        }
        new_LightSwitch(__st);
        return new byte[ 0 ] ;
    }

    public enum State_LightSwitch {
        On,
        Off;
    }

    public class State_Off {

        public void initFromArchive(org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.Off archive) {
        }

        public LightSwitch.State_Off __initFromArchiveBytes(byte[] archiveBytes)
            throws com.google.protobuf.InvalidProtocolBufferException
        {
            org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.Off archive = org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.Off.parseFrom(archiveBytes);
            initFromArchive(archive);
            return this;
        }

        public org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.Off archive()
            throws com.google.protobuf.InvalidProtocolBufferException
        {
            org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.Off.Builder builder = org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.Off.newBuilder();
            return builder.build();
        }
    }

    public class State_On {

        public void initFromArchive(org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.On archive) {
        }

        public LightSwitch.State_On __initFromArchiveBytes(byte[] archiveBytes)
            throws com.google.protobuf.InvalidProtocolBufferException
        {
            org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.On archive = org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.On.parseFrom(archiveBytes);
            initFromArchive(archive);
            return this;
        }

        public org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.On archive()
            throws com.google.protobuf.InvalidProtocolBufferException
        {
            org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.On.Builder builder = org.hyperledger.fabric.example.LightswitchOuterClass.LightSwitch.On.newBuilder();
            return builder.build();
        }
    }
}
