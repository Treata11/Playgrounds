/*
 NotePalette.swift
 
 Created by Treata Norouzi on 6/9/24.
*/

import SwiftUI

// BASS_MIDI_EVENT(event: 1, param: 27709, chan: 0, tick: 240, pos: 102856)

struct NotePalette: View {
    @Environment(SimpleModel.self) private var model
    
    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true, renderer: { context, size in
            let width = size.width
            let height = size.height
            
            model.notes.forEach { note in
                // MARK: Parameters
                let parameter = note.param

                // LOBYTE = key number (0-127, 60=middle C)
                let keyNumber = parameter.lowByte
                // HIBYTE = velocity (0=release, 1-127=press, 255=stop)
                let velocity = parameter.highByte
                /// Position of the note
                let refinedPosition = note.pos / 120
                
                // MARK: Draw
                context.fill(
                    // FIXME: The height of the notes isn't relative to the length of the track
                    Path(CGRect(
                        x: CGFloat(keyNumber) * width / 128,
                        y: CGFloat(refinedPosition) / height,
                        width: width * 0.9 / 128,
                        // DELETE The * 4
                        height: CGFloat(velocity) * 4 / height)
                    ),
                    with: .color(.red)
                )
            }
        }, symbols: {
            
        })
    }
}

#Preview("NotePalette") {
    VStack {
        Text("It's not going to draw anything unless a midi file is selected and the notes are read!").bold()
        
        NotePalette()
            .environment(SimpleModel())
    }
}
