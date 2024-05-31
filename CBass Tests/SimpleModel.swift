//
//  SimpleModel.swift
//  CBass Tests
//
//  Created by Treata Norouzi on 5/30/24.
//

import Foundation
import BassMIDI

let lisztPath = Bundle.main.path(forResource: "Liszt_-_Hungarian_Rhapsody_No._2", ofType: "mid")

@Observable
class SimpleModel {
    var stream: HSTREAM = .zero
    /**
     The `soundfond` which the model uses to play MIDIs
     If empty, no sound would be emmited!
     
     > Set it via the `setupSoundfont()` method.
     */
    private(set) var soundfont: HSOUNDFONT = .init()
    
    @MainActor
    var midiPath: String? = nil
    
    /// Indicates whether if the **loaded-stream** is playing or not.
    var isPlaying: Bool = true
    /// `True` if the sample stream's resources (`var stream`) is free.
    var isUnloaded: Bool = true
    
    // MARK: - Instance Methods
    
    // TODO: DELETE
    @MainActor
    func setup() {
        streamFree()
        
        BASS_Init(-1, 44100, 0, .none, .none)
        
        // Convert the Swift string to a C-style string
//        let cMidiPath = midiPath?.cString(using: .utf8)

        let chan: HSTREAM = BASS_MIDI_StreamCreateFile(BOOL32(truncating: false), lisztPath, 0, 0, 0, 1)
        self.stream = chan

        print("chan: \(chan); Note that it must not be zero")
        
        // MARK: - openFont
        
        let newfont: HSOUNDFONT = BASS_MIDI_FontInit(soundfontPath, 0)
        
        if ((newfont) != 0) {
            var sf: BASS_MIDI_FONT = .init()
            
            sf.font = newfont
            sf.preset = -1 // use all presets
            sf.bank = 0 // use default bank(s)
            
            BASS_MIDI_StreamSetFonts(0, &sf,1); // set default soundfont
            BASS_MIDI_StreamSetFonts(chan, &sf, 1); // set for current stream too
            print("sf: \(sf)")
        }
        print("font: \(newfont)")
    
        // MARK: Play
        
        BASS_ChannelPlay(chan, BOOL32(truncating: false)); // start playing
        
        let error = BASS_ErrorGetCode()
        print("error: \(error)")
    }
    
    @MainActor
    func setupMIDI(withPath: String?) {
        streamFree()
        
        BASS_Init(-1, 44100, 0, .none, .none)
        
        let chan: HSTREAM = BASS_MIDI_StreamCreateFile(.false, withPath, 0, 0, 0, 1)
        self.stream = chan
        
        let error = BASS_ErrorGetCode()
        print("error: \(error)")
    }
    
    /**
     
     > openFont;
     */
    func setupSoundfont(withPath: String? = soundfontPath) {
        let newfont: HSOUNDFONT = BASS_MIDI_FontInit(withPath, 0)
        
        if ((newfont) != 0) {
            var soundfont: BASS_MIDI_FONT = .init()
            
            soundfont.font = newfont
            // use all presets
            soundfont.preset = -1
            // use default bank(s)
            soundfont.bank = 0
            
            // set default soundfont
            BASS_MIDI_StreamSetFonts(0, &soundfont,1);
            // set for current stream too
            BASS_MIDI_StreamSetFonts(self.stream, &soundfont, 1);
            print("setupSoundfont(); soundfont: \(soundfont)")
        } else {
            // FIXME: Raise an error instead of crashing :)
            fatalError("Not a compatible soundfont")
        }
        
        self.soundfont = newfont
        print("setupSoundfont(); font: \(newfont)")
    }
    
    @MainActor
    /// start playing
    func play() {
        BASS_ChannelPlay(self.stream, .false)
        isPlaying = true
    }
    
    /// Use `BASS_Start` to resume the output and paused channels.
    @MainActor
    func resume() {
        if !isUnloaded {
            BASS_Start()
            isPlaying = true
        }
    }
    
    /// Stops the output, pausing all musics/samples/streams on it.
    @MainActor
    func pause() {
        BASS_Pause()
        isPlaying = false
    }
    
    /**
     Frees a sample stream's resources, including any `sync/DSP/FX` it has.
     
     > free old stream before opening new
     */
    @MainActor
    func streamFree() {
        self.isUnloaded = (BASS_StreamFree(self.stream) == 0)
        isPlaying = false
    }
    
    /** 
     Frees a channel, including any `sync/DSP/FX` it has.
     
     - Remark
     This function can be used to free all types of channel, instead of using either BASS_StreamFree or BASS_MusicFree or BASS_ChannelStop depending on the channel type.
     */
    @MainActor
    private func channelFree() {
        self.isUnloaded = (BASS_ChannelFree(self.stream) == 0)
        isPlaying = false
    }
    
    // TODO: DELETE
    func play2() {
        DispatchQueue.main.async {
            if let midiPath = self.midiPath {
                let cMidiPath = midiPath.cString(using: .utf8)
                let chan = BASS_MIDI_StreamCreateFile(BOOL32(truncating: false), cMidiPath, 0, 0, 0, 1)
                
                print("chan: \(chan); Note that it must not be zero")
                
                // MARK: openFont
                
                let newfont: HSOUNDFONT = BASS_MIDI_FontInit(soundfontPath, 0);
                if ((newfont) != 0) {
                    var sf: BASS_MIDI_FONT = .init()
                    
                    sf.font = newfont
                    sf.preset = -1 // use all presets
                    sf.bank = 0 // use default bank(s)
                    
                    BASS_MIDI_StreamSetFonts(0, &sf,1); // set default soundfont
                    BASS_MIDI_StreamSetFonts(chan, &sf, 1); // set for current stream too
                    print("sf: \(sf)")
                }
                print("font: \(newfont)")
            
                // MARK: Play
                
                BASS_ChannelPlay(chan, BOOL32(truncating: false)); // start playing
            }
        }
    }
}

import SwiftUI

struct SimpleModelView: View {
    @Bindable private var model = SimpleModel()
    
    var body: some View {
        Button("SetupPlay") {
            model.setup()
        }
        
        Button("Resume") {
            model.resume()
        }
        
        Button("Pause") {
            model.pause()
        }
    }
}

#Preview {
    SimpleModelView()
}

// MARK: - Extensions

extension BOOL32 {
    static let `false` = BOOL32(truncating: false)
    static let `true` = BOOL32(truncating: true)
}



// MARK: - From file system

struct FileChooserView: View {
    @State private var midiPath: URL?

    var body: some View {
        VStack {
            Button("Choose MIDI File") {
                let panel = NSOpenPanel()
                panel.allowedFileTypes = ["mid", "kar"]

                if panel.runModal() == .OK {
                    self.midiPath = panel.url
                }
            }

            if let midiPath = midiPath {
                Text("Selected MIDI File: \(midiPath.lastPathComponent)")
            }
            
            if midiPath != nil {
                Button("Play") {
                    BASS_Init(-1, 44100, 0, .none, .none)
                    
                    let path = midiPath?.path()
                    let chan: HSTREAM = BASS_MIDI_StreamCreateFile(BOOL32(truncating: false), path, 0, 0, 0, 1)

                    print("chan: \(chan); Note that it must not be zero")
                    
                    // MARK: openFont
                    
                    let newfont: HSOUNDFONT = BASS_MIDI_FontInit(soundfontPath, 0);
                    if ((newfont) != 0) {
                        var sf: BASS_MIDI_FONT = .init()
                        
                        sf.font = newfont
                        sf.preset = -1 // use all presets
                        sf.bank = 0 // use default bank(s)
                        
                        BASS_MIDI_StreamSetFonts(0, &sf,1); // set default soundfont
                        BASS_MIDI_StreamSetFonts(chan, &sf, 1); // set for current stream too
                        print("sf: \(sf)")
                    }
                    print("font: \(newfont)")
                
                    // MARK: Play
                    
                    BASS_ChannelPlay(chan, BOOL32(truncating: false)); // start playing
                    
                    let error = BASS_ErrorGetCode()
                    print("error: \(error)")
                }
            }
        }
    }
}

#Preview("FileChooserView") {
    FileChooserView()
}
