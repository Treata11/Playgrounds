/*
 Extensions.swift

 Created by Treata Norouzi on 6/6/24.
*/

// TODO: Be sure about their correctness

// MARK: - BinaryInteger Extensions

extension BinaryInteger {
    /// Extract the low-byte using a bitwise AND operation with 0xFF
    ///
    /// > Works for both `Singed` and `Unsigned` integers.
    var lowByte: Self {
        return self & Self(0xFF)
    }
    
    var highWord: Self {
        let bitWidth = self.bitWidth
        let upperMask: Self = (1 << (bitWidth / 2)) - 1
        return (self >> (bitWidth / 2)) & upperMask
    }
}

// FIXME: The following:

extension SignedInteger {
    var highByte: Self {
//        return self >> (self.bitWidth - 8)
        return self >> 8
    }
}

extension UnsignedInteger {
    /// Shift the parameter right by 8 bits and then mask with 0xFF to extract the high byte
    var highByte: Self {
//        return (self >> (self.bitWidth - 8)) & 0xFF
        return (self >> 8) & 0xFF
    }
}
