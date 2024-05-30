//
//  ContentView.swift
//  CBass Tests
//
//  Created by Treata Norouzi on 5/21/24.
//

import SwiftUI

struct ContentView: View {
    @Bindable private var manager = BassMIDIManager()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        
        .onAppear() {
            manager.openFont()
            manager.play()
        }
        .onTapGesture {
            print("maxPositionSlider: \(manager.maxPositionSlider)")
            print("manager.infoText: \(manager.infoText)")
            print("manager.chan: \(manager.chan)")
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - CBass

let midiPath = Bundle.main.path(forResource: "JoyToTheWorld", ofType: "mid")
let midiPath2 = Bundle.main.path(forResource: "Strauss Persian March", ofType: "mid")

/// Would not work
//let emptySoundfontURL = Bundle.main.url(forResource: "YDP-GrandPiano_empty", withExtension: "sf2")
let soundfontPath = Bundle.main.path(forResource: "YDP-GrandPiano", ofType: "sf2")

import Bass
import BassMIDI

@Observable
class BassMIDIManager {
    /// channel handle
    var chan: HSTREAM = 0
    /// soundfont
    var font: HSOUNDFONT = 0
    /// lyrics buffer
    var lyrics: [String] = []
    
    var fxSwitch: Bool = false
    var infoText: String = ""
    
    var maxPositionSlider: UInt64 = 0
    
    //    init() {
    //        play()
    //    }
    
    // MARK: - Instance Methods
    
    func play() {
        BASS_StreamFree(chan); // free old stream before opening new
        
        // Creates a sample stream from a MIDI file.
        // BASS_MIDI_StreamCreateFile(<#T##mem: BOOL32##BOOL32#>, <#T##file: UnsafeRawPointer!##UnsafeRawPointer!#>, <#T##offset: QWORD##QWORD#>, <#T##length: QWORD##QWORD#>, <#T##flags: DWORD##DWORD#>, <#T##freq: DWORD##DWORD#>)
        
        //        let newChan = BASS_MIDI_StreamCreateFile(false, midiPath, 0, 0, BASS_SAMPLE_FLOAT|BASS_SAMPLE_LOOP|BASS_MIDI_DECAYSEEK|(self.fxSwitch.state?0:BASS_MIDI_NOFX),1)
        
        let newChan = BASS_MIDI_StreamCreateFile(0, midiPath, 0, 0, DWORD(BASS_SAMPLE_FLOAT | BASS_SAMPLE_LOOP | BASS_MIDI_DECAYSEEK | BASS_MIDI_NOFX), 1)
        print("BassMIDIManager; play(); newChan: \(newChan)")
        self.chan = newChan
        
        // set the title (track name of first track)
        var mark: BASS_MIDI_MARK = .init()
        if ((BASS_MIDI_StreamGetMark(newChan, DWORD(BASS_MIDI_MARK_TRACK), 0, &mark) != 0) && (mark.track == 0)) {
            self.infoText = mark.text.debugDescription
        } else {
            self.infoText = "Bruh"
        }
        // update pos scroller range (using tick length)
        self.maxPositionSlider = BASS_ChannelGetLength(newChan, DWORD(BASS_POS_MIDI_TICK)) / 120
        
        print("BassMIDIManager Is Playing")
        
        openFont()
        
        //        Task { // get default soundfont in case of matching soundfont being used
        //            var sf: BASS_MIDI_FONT = .init();
        //            BASS_MIDI_StreamGetFonts(newChan, &sf, 1);
        //            font = sf.font;
        //        }
        
        BASS_ChannelPlay(newChan, 0); // start playing
    }
    
    func openFont() {
        let newFont: HSOUNDFONT = BASS_MIDI_FontInit(soundfontPath, 0)
        
        //        if (newFont != 0) {
        var sf: BASS_MIDI_FONT = .init()
        
        sf.font = newFont;
        sf.preset = -1; // use all presets
        sf.bank=0; // use default bank(s)
        
        BASS_MIDI_StreamSetFonts(0, &sf, 1); // set default soundfont
        BASS_MIDI_StreamSetFonts(chan, &sf, 1); // set for current stream too
        BASS_MIDI_FontFree(font); // free old soundfont
        font = newFont;
        //        }
    }
    
    func timeProc() {
        
    }
    
    func loadMIDI() {
        BASS_StreamFree(chan) // Free old stream before opening new
    }
    
    func setSoundfont() {
        // TODO: Implement; Done
        /**
         Soundfonts provide the sounds that are used to render a MIDI stream.
         A default soundfont configuration is applied initially to the new MIDI stream, which can subsequently be overridden using `BASS_MIDI_StreamSetFonts`.
         */
    }
    
    func setInterpolation() {
        // TODO: Implement
        
        /**
         By default, linear interpolation will be used in playing the samples from the soundfonts.
         Sinc interpolation is also available via the BASS_ATTRIB_MIDI_SRC attribute, which increases the sound quality but also uses more CPU.
         */
    }
    
    // MARK: - Useful APIs
    
    /**
     `BASS_ChannelPlay (restart = TRUE)`
     `BASS_ChannelSetPosition (pos = 0)`
     */
}
