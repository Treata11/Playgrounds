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
            
            let heightCoefficient = height / CGFloat(model.lengthInTicks * 120)
            
            model.noteEvents.forEach { note in
                // MARK: Parameters
                let parameter = note.param

                // LOBYTE = key number (0-127, 60=middle C)
                let keyNumber = parameter.lowByte
                // HIBYTE = velocity (0=release, 1-127=press, 255=stop)
                let velocity = parameter.highByte
                /// The position of the note **in ticks**
                let tick = CGFloat(note.tick)
                /// Position of the note **in bytes**
                let position = note.pos
                
                // MARK: Draw
                context.fill(
                    Path(CGRect(
                        x: CGFloat(keyNumber) * width / 128,
                        y: CGFloat(position) / height,
//                        y: CGFloat(refinedPosition) * heightCoefficient,
                        width: width * 0.9 / 128,
                        // The sum of all the notes' heights should be the the height of the canvas
                        height: CGFloat(tick) / height)
//                        height: CGFloat(tick) * heightCoefficient)
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
        Text("It's not going to draw anything unless a midi file is selected and the notes are read! \nTap on the Get Notes button").bold()
        Group {
            SimpleModelView()
            NotePalette()
        }
            .environment(SimpleModel())
    }
}
