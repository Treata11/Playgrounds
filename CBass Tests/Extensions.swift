/*
 Extensions.swift

 Created by Treata Norouzi on 6/6/24.
*/

// TODO: Be sure about their correctness

// MARK: - BinaryInteger Extensions

extension BinaryInteger {
    /// Returns the high byte of the integer.
    var highByte: Self {
        return Self((self >> 8) & 0xFF)
    }

    /// Returns the low byte of the integer.
    var lowByte: Self {
        return Self(self & 0xFF)
    }
}

import SwiftUI

struct BinaryIntTests: View {
    let myUint32: UInt32 = 0xAB93
    
    var body: some View {
        Text(String(format: "%04X", myUint32))
            .onAppear {
                let hexString = String(format: "%04X", myUint32) // "AB93"
                let highByte = myUint32.highByte
                let lowbyte = myUint32.lowByte
                
                print("My UInt32: \(myUint32), with hex string: \(hexString)\n    lowbyte: \(lowbyte) and highbyte: \(highByte)")
                print("hex HighByte: \(String(format: "%04X", highByte)), hex LowByte: \(String(format: "%04X", lowbyte))")
            }
    }
}

#Preview("BinaryIntTests") { BinaryIntTests() }

//extension BinaryInteger {
//    /// Extract the low-byte using a bitwise AND operation with 0xFF
//    ///
//    /// > Works for both `Singed` and `Unsigned` integers.
//    var lowByte: Self {
//        return self & Self(0xFF)
//    }
//    
//    
//    
////    var highWord: Self {
////        let bitWidth = self.bitWidth
////        let upperMask: Self = (1 << (bitWidth / 2)) - 1
////        return (self >> (bitWidth / 2)) & upperMask
////    }
//}
