//
//  Views.swift
//  CBass Tests
//
//  Created by Treata Norouzi on 5/31/24.
//

import SwiftUI

struct SimpleModelView: View {
    @Environment(SimpleModel.self) private var model
    
    var body: some View {
        Text("A Default MIDI file has been chosen for playback!").bold()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.618) {
                    model.setupMIDI(withPath: lisztPath)
                    // Play the track
                    model.play()
                }
            }
        

        Button(action: {
            model.togglePlayback()
        }, label: {
            model.isPlaying ? Image(systemName: "pause.fill") : Image(systemName: "play.fill")
        })
        // This Button should definitely be disabled when there are no tracks loaded
        .disabled(model.isUnloaded)
        
        Button("Stream Free") {
            model.streamFree()
        }
    }
}

#Preview("SimpleModelView") {
    SimpleModelView()
        .environment(SimpleModel())
}

// MARK: - From file system

struct MidiChooserView: View {
    @Environment(SimpleModel.self) private var model
    
    @State private var midiURL: URL? = nil

    var body: some View {
        VStack {
            Button("Choose MIDI File") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.midi]

                if panel.runModal() == .OK {
                    self.midiURL = panel.url
                }
            }

            if let url = midiURL {
                Text("Selected MIDI File: \(url.lastPathComponent)")
                    .onAppear {
                        let midiPath = url.path.removingPercentEncoding
                        model.setupMIDI(withPath: midiPath)
                    }
                    .onChange(of: midiURL) {
                        print("     MidiChooserView; midiURL has changed")
                        let midiPath = url.path.removingPercentEncoding
                        model.setupMIDI(withPath: midiPath)
                    }
            }
            
            if midiURL != nil {
                Button(action: {
                    model.togglePlayback()
                }, label: {
                    model.isPlaying ? Image(systemName: "pause.fill") : Image(systemName: "play.fill")
                })
                // This Button should definitely be disabled when there are no tracks loaded
                .disabled(model.isUnloaded)
                
                Button("Free Stream") {
                    model.streamFree()
                }
                
                Button("Debug") {
                    print("""
                            model.isUnloaded: \(model.isUnloaded)
                        """)
                }
            }
        }
    }
}

#Preview("FileChooserView") {
    MidiChooserView()
        .environment(SimpleModel())
}
