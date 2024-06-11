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
            Text("Duration: \(Int(model.duration))")
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
        
        Button("Get All Notes") {
            model.getAllNoteEvents()
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
                    Text("Duration: \(Int(model.duration))")
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
                
                Divider()
                
                Text("Useful for visualization purposes")
//                Button("Get All Notes") {
//                    model.getAllNoteEvents()
//                    print("note count: \(model.notesCount)")
//                    
//                    for i in 0...5 {
//                        let note = model.noteEvents[i]
//                        
//                        let refinedPosition = note.pos / 120
//                        let parameter: UInt32 = note.param
//                        
//                        // LOBYTE = key number (0-127, 60=middle C)
//                        let keyNumber = parameter.lowByte
//
//                        // HIBYTE = velocity (0=release, 1-127=press, 255=stop)
//                        let velocity = parameter.highByte
//                        
//                        print("""
//                            \(i+1)th Note: \(note) ->
//                                keyNumber: \(keyNumber)
//                                velocity: \(velocity)
//                                note position: \(refinedPosition)
//                            """)
//                    }
//                }
                
                Button("Get Note-On Events") {
                    model.getAllNoteEvents()
                    model.getSeperatedNoteEvents()
                    print("""
                        entire note events count: \(model.noteEvents.count)
                        The following counts should be equal:
                            note-on events count: \(model.noteOnEvents.count)
                            note-off events count: \(model.noteOffEvents.count)
                        """)
                    
                    for i in 0...5 {
                        let note = model.noteOnEvents[i]
                        
                        let refinedPosition = note.pos / 120
                        let parameter: UInt32 = note.param
                        
                        // LOBYTE = key number (0-127, 60=middle C)
                        let keyNumber = parameter.lowByte

                        // HIBYTE = velocity (0=release, 1-127=press, 255=stop)
                        let velocity = parameter.highByte
                        
                        print("""
                            \(i+1)th Note: \(note) ->
                                keyNumber: \(keyNumber)
                                velocity: \(velocity)
                                note position: \(refinedPosition)
                            """)
                    }
                }
                
                Button("set a sync on MIDI_EVENT_NOTE events") {
                    model.setSync()
                }

                Divider()
                
                NotePalette()
            }
        }
    }
}

#Preview("FileChooserView") {
    MidiChooserView()
        .environment(SimpleModel())
}
