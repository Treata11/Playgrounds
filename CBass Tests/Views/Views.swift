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
                Button("Get Notes") {
                    model.getNotes()
                    let thirdNote = model.notes[2]
                    let lastNote = model.notes.last!
                    
                    let refinedPosition = thirdNote.pos / 120
                    let parameter: UInt32 = thirdNote.param
                    
                    // LOBYTE = key number (0-127, 60=middle C)
                    // FIXME: The LOBYTE operation below is wrong
//                    let keyNumber = parameter & 0xFF 
                    let keyNumber = parameter.lowByte

                    // HIBYTE = velocity (0=release, 1-127=press, 255=stop)
//                    let velocity = (parameter >> 8) & 0xFF 
                    let velocity = parameter.highByte

                    
                    print("""
                        event count: \(model.eventsCount)
                        
                        third Note: \(thirdNote) ->
                            parameter: \(parameter)
                            keyNumber: \(keyNumber)
                            velocity: \(velocity)
                            note position: \(refinedPosition)
                        -------------------------------------------------------
                        length of the track in ticks: \(Int(model.lengthInTicks))
                        last Note: \(lastNote) ->
                            note position: \(lastNote.pos / 120)
                            
                        """)
                }
                
                Button("set a sync on MIDI_EVENT_NOTE events") {
                    model.setSync()
                }
                
                Spacer()
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
