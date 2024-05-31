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
    private(set) var stream: HSTREAM = .zero {
        willSet {
            if newValue != 0 {
                if isUnloaded {
                    isUnloaded = false
                }
            }
        }
    }
    /**
     The `soundfond` which the model uses to play MIDIs
     If empty, no sound would be emmited!
     
     > Set it via the `setupSoundfont()` method.
     */
    private(set) var soundfont: HSOUNDFONT = .init()
    
    var midiPath: String? = nil
    
    /// Indicates whether if the **loaded-stream** is playing or not.
    var isPlaying: Bool = true
    /// `True` if the sample stream's resources (`var stream`) is free.
    var isUnloaded: Bool = true
    
    init(soundfontPath: String? = soundfontPath, midiPath: String? = nil) {
        setupSoundfont(withPath: soundfontPath)
    }
    
    // MARK: - Instance Methods
    
    @MainActor
    func setupMIDI(withPath: String?) {
        streamFree()
        
        // TODO: Should be kept here or should it be in its own method?
        BASS_Init(-1, 44100, 0, .none, .none)
        
        let chan: HSTREAM = BASS_MIDI_StreamCreateFile(.false, withPath, 0, 0, 0, 1)
        self.stream = chan
        // If the channel isn't empty!
        if chan != 0 { self.isUnloaded = false; print("-- LOADED --") } else {
            // FIXME: Raise an error instead of crashing :)
            fatalError("Not a MIDI")
        }
        
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
    
    // MARK: Playback Intents
    
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
        if !isUnloaded {
            BASS_Pause()
            isPlaying = false
        }
    }
    
    @MainActor
    func togglePlayback() {
        isPlaying ? pause() : resume()
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
}

// MARK: - Extensions

extension BOOL32 {
    static let `false` = BOOL32(truncating: false)
    static let `true` = BOOL32(truncating: true)
}

