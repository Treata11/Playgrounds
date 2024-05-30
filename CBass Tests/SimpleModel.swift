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
    func play() {
        BASS_Init(-1, 44100, 0, .none, .none)
        
        // Convert the Swift string to a C-style string
//        let cMidiPath = midiPath?.cString(using: .utf8)

        let chan: HSTREAM = BASS_MIDI_StreamCreateFile(BOOL32(truncating: false), lisztPath, 0, 0, 0, 1)

        print("chan: \(chan); Note that it must not be zero")
        
        // MARK: - openFont
        
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
    
    //
    func play2() {
        DispatchQueue.main.async {
            if let midiPath = midiPath {
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
        Button("Play") {
            model.play()
        }
    }
}

#Preview {
    SimpleModelView()
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
