//
//  BassMIDIModel.swift
//  CBass Tests
//
//  Created by Treata Norouzi on 5/30/24.
//

import Foundation
import BassMIDI

var chan: HSTREAM = 0    // channel handle
var font: HSOUNDFONT = 0    // soundfont

var speed: Float = 1    // tempo adjustment
var lyrics: [String] = [] // lyrics buffer

// display error messages
func error() -> Int32 {
    return BASS_ErrorGetCode()
}

