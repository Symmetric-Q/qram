﻿namespace Qram{
    
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;

    // Notes:
    // Target Register might be better?
    // Can make target register with  loop over target qubits
    // spec for OnesAddress could be an address and value

    // TODO: Probably want LittleEndian for address, data can be whatever
    // External API exposed type for a QRAM
    newtype QRAM = (Lookup : ((Qubit[], Qubit[]) => Unit is Adj + Ctl), 
        AddressSize : Int,
        DataSize : Int);

    //Internal QRam type for a single QRAM Bit (is composed to form a full memory block)
    internal newtype SingleBitQRAM = (Lookup : ((Qubit[], Qubit) => Unit is Adj + Ctl), 
        AddressSize : Int);

    function ImplicitQRAMOracle(dataValues : Bool[][]) : QRAM {
        let onesAddresses = OnesAddressesFromData(dataValues);
        let qrams = Mapped(SingleImplicitQRAMOracle, onesAddresses); 
        return Default<QRAM>()
            w/ Lookup <- ApplyImplicitQRAMOracle(qrams, _, _)
            w/ AddressSize <- (Head(qrams))::AddressSize
            w/ DataSize <- Length(qrams);
    }

    internal operation ApplyImplicitQRAMOracle(
        Qrams: SingleBitQRAM[], 
        AddressRegister : Qubit[],
        TargetRegister : Qubit[]
    )
    : Unit is Adj + Ctl {
        for ((qram, target) in Zip(Qrams, TargetRegister)) {
            qram::Lookup(AddressRegister, target) ;
        }
            
    }

    internal function SingleImplicitQRAMOracle(OnesAddresses : Bool[][]) : SingleBitQRAM {
        let addressLength = Length(Head(OnesAddresses));
        //return QRAM(ApplySingleImplicitQRAMOracle(OnesAddresses, _, _),addressLength);
        return Default<SingleBitQRAM>()
            w/ Lookup <- ApplySingleImplicitQRAMOracle(OnesAddresses, _, _)
            w/ AddressSize <- addressLength;
    }

    internal operation ApplySingleImplicitQRAMOracle(
        OnesAddresses: Bool[][], 
        AddressRegister : Qubit[],
        Target : Qubit
    )
    : Unit is Adj + Ctl {
        for (address in OnesAddresses) {
            (ControlledOnBitString(address, X))(AddressRegister, Target); 
        }
    }

    // [5,0,2,8,7]
    // [[true, false, true], []]
    // Assume that if data is not power of 2, assume rest 0s
    internal function OnesAddressesFromData(dataArray : Bool[][]) : Bool[][][] {
        let numDataBits = Length(Head(dataArray));
        mutable onesAddresses = new Bool[][][numDataBits];
        
        for (idx in 0..numDataBits-1) {
            set onesAddresses w/=idx <- OnesAddressesFromDataValue(ElementsAt(dataArray, idx));
        }
        return onesAddresses;
    }


///////////////////////////////////////////////////////////////////////////
// UTILITY FUNCTIONS
///////////////////////////////////////////////////////////////////////////

    /// # Summary
    /// Takes the Boolean array representation of an Int and converts to the 
    /// list of ones addresses needed to represent that Int.
    /// # Input
    /// ## dataArray
    /// A data value in the form of a
    /// # Output
    /// 
    internal function OnesAddressesFromDataValue(dataArray : Bool[]) : Bool[][] {
        mutable onesAddresses = new Bool[][0];
        let nAddressBits = BitSizeI(Length(dataArray));
        for ((idx, bitValue) in Enumerated(dataArray)) {
            if (bitValue) {
                set onesAddresses += [IntAsBoolArray(idx, nAddressBits)];
            }
        }
        return onesAddresses;
    }

    internal function ElementsAt<'T>(dataArrayArray : 'T[][], n : Int) : 'T[] {
        return Mapped(ElementAt<'T>(_, n), dataArrayArray);
    }

    internal function ElementAt<'T>(array : 'T[], idx : Int) : 'T {
        return array[idx];
    }




    /// # Summary
    /// Generates an oracle representing a bucket brigade style qRAM with a 
    /// list of address locations that contain the value 1.
    ///
    /// # Input
    /// ## Address
    /// An array of strings that documents the addresses where the value in 
    /// in memory is 1.
    ///
    /// # Remarks
    /// ## Example
    /// ```Q#
    /// operation ReadoutSingleAddress(Memory : QRAM, Address : Bool[]) : Bool {
    ///     using ((addressQubits, target) = (Qubit[3], Qubit())) {
    ///         // prepare address value
    ///         ApplyPauliFromBitString (PauliX, true, Address, addressQubits);
    ///         QRAM(address, target);
    ///         return BoolFromResult(MResetZ(target));
    ///        }  
    ///     }
    /// ```
    ///
    /// # See Also
    /// - OperationName
    ///
    /// # References
    /// - [arXiv:0000.0000](https://arxiv.org/abs/0000.0000)

    /// BB has a register of hardware qubits - need to know which of those are
    /// set to 1; easiest way to do that is to send a string like "0011" to indicate that
    /// this register is in the state
    ///
    /// |0> ------   (qubit 0, address 00)
    /// |0> ------   (qubit 1, address 01)
    /// |1> ------   (qubit 2, address 10)
    /// |1> ------   (qubit 3, address 11)
    ///
    /// This is a 2-bit address; so QRAM(00) = 0, QRAM(01) = 0, QRAM(10) = 1, QRAM(11) = 1
    ///
    /// The black box has to perform this operation ^^ given the inputs, based on the contents
    /// of the hardware register it starts with
}