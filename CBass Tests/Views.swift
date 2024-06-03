//
//  Views.swift
//  CBass Tests
//
//  Created by Treata Norouzi on 5/31/24.
//

import SwiftUI

struct SimpleModelView: View {
    @Environment(SimpleModel.self) private var model
    
    @State private var playbackPosition: Double = .zero
    /// Modify the tempo
    @State var playbackSpeed: Float = .zero
    
    var body: some View {
        Text("A Default MIDI file has been chosen for playback!").bold()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.618) {
                    model.setupMIDI(withPath: lisztPath)
                    // Play the track
                    model.play()
                }
            }
        
        Group {
            Text("Length: \(Int(model.length))")
            Text("Real Duration: \(Int(model.affectedDuration))")
            if model.speed != 1 {
                Text("\(model.speed)")
            }
        }
        .onChange(of: model.stream) {
            model.getLength()
        }
        
        Group {
            Text("Tempo: \(Int(model.tempo))")
            Text("Position In Ticks: \(Int(model.posInTicks))")
        }
        .onChange(of: model.stream) {
            model.timeProc()
        }
        
        Slider(value: $playbackSpeed, in: -10...10)
            .onChange(of: playbackSpeed) {
                model.changeTempo(by: playbackSpeed)
            }
        
        Divider()

        Button(action: {
            model.togglePlayback()
        }, label: {
            model.isPlaying ? Image(systemName: "pause.fill") : Image(systemName: "play.fill")
        })
        // This Button should definitely be disabled when there are no tracks loaded
        .disabled(model.isUnloaded)
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
    /// Modify the tempo
    @State var playbackSpeed: Float = .zero

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
                
                Group {
                    Text("Length: \(Int(model.length))")
                    Text("Real Duration: \(Int(model.affectedDuration))")
                    if model.speed != 1 {
                        Text("\(model.speed)")
                    }
                }
                .onChange(of: model.stream) {
                    model.getLength()
                }
                
                Group {
                    Text("Tempo: \(Int(model.tempo))")
                    Text("Position In Ticks: \(Int(model.posInTicks))")
                }
                .onChange(of: model.stream) {
                    model.timeProc()
                }
                
                Slider(value: $playbackSpeed, in: -10...10)
                    .onChange(of: playbackSpeed) {
                        model.changeTempo(by: playbackSpeed)
                    }
                
                Divider()
                
                Button("Free Stream") {
                    model.streamFree()
                }
                
                Button("Debug") {
                    print("""
                            model.isUnloaded: \(model.isUnloaded)
                        """)
                }
                
                Button("Read Notes") {
                    model.readNotes()
                }
                
//                Group {
//                    Text("Current NoteEvent: \(model.noteEvent)").bold()
//                    Text("Current KeyPressEvent: \(model.keyPressEvent)").bold()
//                    Text("Current ScaleTuneEvent: \(model.scaleTuneEvent)").bold()
//                    Text("Bruh: \(model.bruh)")
//                    Text("Current Drum Event: \(model.drumEvent)")
//                    Text("Current All Note Events: \(model.allNoteEvents)")
//                    Text("Current Special Note Events: \(model.specialNoteEvents)")
//                }
//                .onTapGesture {
//                    model.getNoteEvent()
//                }
//                
//                Divider()
//                
//                Text("All Events count: \(model.eventsCount)")
//                    .onTapGesture {
//                        model.getAllEvents()
//                    }
            }
        }
    }
}

#Preview("FileChooserView") {
    MidiChooserView()
        .environment(SimpleModel())
}
