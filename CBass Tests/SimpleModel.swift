//
//  SimpleModel.swift
//  CBass Tests
//
//  Created by Treata Norouzi on 5/30/24.
//

import Foundation
import BassMIDI
import Bass

// load optional plugins for packed soundfonts (others may be used too)
//import BassFLAC
//import BassWV
//import BassOpus

let lisztPath = Bundle.main.path(forResource: "Liszt_-_Hungarian_Rhapsody_No._2", ofType: "mid")

@Observable
class SimpleModel {
    private(set) var stream: HSTREAM = .zero {
        didSet {
            if oldValue != 0 {
                getLength()
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
    
    /**
     A variable that sets the **state** of the model.
     Whether the audio-engine should play a newly added midi right away or not.
     if not, the user has to manuallly play the midi when a new midi is selected.
     */
    var modelIsPaused = false
    
    /// Indicates whether if a **loaded-stream** is playing or not.
    private(set) var isPlaying: Bool = true {
        willSet {
            if !newValue {
                disableTimer()
            } else {
                timeProc()
            }
        }
    }
    /// `True` if the sample stream's resources (`var stream`) is free.
    private(set) var isUnloaded: Bool = true {
        didSet {
            if oldValue {
                disableTimer()
            }
        }
    }
    /// Length of the MIDI **in seconds**
    private(set) var duration: Double = .zero
    /// Length of the MIDI **in seconds** which will be affected by the changes of `tempo` initiated by the user
    private(set) var affectedDuration: Double = .zero
    /// Length of the MIDI **in ticks**
    private(set) var lengthInTicks: QWORD = .zero
    /// tempo adjustment
    private(set) var speed: Float = 1
    
    init(soundfontPath: String? = soundfontPath) {
        print("------ SimpleModel Initiated ------")
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
        if chan != 0 { self.isUnloaded = false; print("-- is UNLOADED?: \(self.isUnloaded) --") } else {
            // FIXME: Raise an error instead of crashing :)
            fatalError("Not a MIDI")
        }
        
//        #if DEBUG
//            let error = BASS_ErrorGetCode()
//            print("error: \(error)")
//        #endif
        
        // Play the file right-away
        if !modelIsPaused {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("Model Set to play the midi")
                self.play()
            }
        }
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
    
    // MARK: - Intents
    
    /**
     Retrieves the length of a channel.
     If successful, then the channel's length is returned, else -1 is returned.
     */
    func getLength() {
        if !isUnloaded {
            // the length in bytes
            let bytes: QWORD = BASS_ChannelGetLength(self.stream, DWORD(BASS_POS_BYTE))
            // the length in Seconds
            let time = BASS_ChannelBytes2Seconds(self.stream, bytes)
            self.duration = time
            self.affectedDuration = time
            
            // TODO: Question: Why the ticks are divided by 120?
            // the length in Ticks
            let length: QWORD = BASS_ChannelGetLength(self.stream, DWORD(BASS_POS_MIDI_TICK))
            self.lengthInTicks = length / 120
        }
    }
    
    // MARK: Timer Processes
    
    /// in Ticks
    private(set) var posInTicks: Double = .zero
    private(set) var tempo: Double = 0.0
    
    private var voices: Float = 0
    private var fontInfo = ""
    
    // FIXME: The timer doesn't go to sleep when the stream finishes
    private var timer: Timer?
    
    func disableTimer() {
        // disable the `timeProc` timer to avoid unnecessary CPU time
        timer?.invalidate()
        timer = nil
    }

    // !!!: WIP
//    @MainActor
    func timeProc() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [self] timer in
            if !isUnloaded {
                // get position in ticks
                let tick: QWORD = BASS_ChannelGetPosition(self.stream, DWORD(BASS_POS_MIDI_TICK))
                // TODO: Question: Why the ticks are divided by 120?
                posInTicks = Double(tick) / 120
                
                // get the file's tempo
                let tempo = BASS_MIDI_StreamGetEvent(self.stream, 0, DWORD(MIDI_EVENT_TEMPO))
                // TODO: Question: Where did the `60000000.0` come from?
                self.tempo = Double(speed * 60000000.0 / Float(tempo))
                BASS_ChannelGetAttribute(stream, DWORD(BASS_ATTRIB_MIDI_VOICES_ACTIVE), &self.voices)
            }
            
            let updateFont = true
            if updateFont {
                let text = "no soundfont"
                var info = BASS_MIDI_FONTINFO()
                // if (BASS_MIDI_FontGetInfo(self.soundfont, &info) != 0) { }
                self.fontInfo = text
            }
        }
    }
    
    // MARK: Playback Intents
 
    /// start playing
    @MainActor
    func play() {
        BASS_ChannelPlay(self.stream, .false)
        isPlaying = true
        // !!!: Redundant
        isUnloaded = false
    }
    
    /// Use `BASS_Start` to resume the output and paused channels.
    @MainActor
    func resume() {
        if !isUnloaded {
            BASS_Start()
            isPlaying = true
        } else if modelIsPaused {
            play()
        }
    }
    
    /// Stops the output, pausing all `musics/samples/streams` on it.
    @MainActor
    func pause() {
        if !isUnloaded {
            BASS_Pause()
            isPlaying = false
        }
    }
    
    @MainActor
    func stop() {
        if !isUnloaded {
            BASS_Stop()
            isPlaying = false
        }
    }
    
    @MainActor
    func togglePlayback() {
        isPlaying ? pause() : resume()
    }
    
    /**
     Seek to an arbitrary position of the playback
     */
    @MainActor
    func seek(to time: TimeInterval) {
        if !isUnloaded {
            // TODO: Make sure the requested seeking pos doesn't exceed the length
            let p = QWORD(time * 120)
            BASS_ChannelSetPosition(self.stream, p, DWORD(BASS_POS_MIDI_TICK))
        }
    }
    
    /**
     Changes the speed of playback which affects the playtime and tempo of the `stream`
     */
    @MainActor
    func changeTempo(by value: Float) {
        if !isUnloaded {
            let speed = (20 + value) / 20 // up to +/- 50% bpm
            self.speed = speed
            // apply tempo adjustment
            BASS_ChannelSetAttribute(self.stream, DWORD(BASS_ATTRIB_MIDI_SPEED), speed)
            // Changes in tempo affects the duration of the playback
            self.affectedDuration = self.duration / Double(speed)
        }
    }
    
    /**
     Frees a sample stream's resources, including any `sync/DSP/FX` it has.
     
     > free old stream before opening new
     */
    @MainActor
    func streamFree() {
        BASS_StreamFree(stream)

        self.isUnloaded = true
        
        isPlaying = false
        self.stream = .zero
        self.midiPath = nil
    }
    
    /** 
     Frees a channel, including any `sync/DSP/FX` it has.
     
     - Remark
     This function can be used to free all types of channel, instead of using either BASS_StreamFree or BASS_MusicFree or BASS_ChannelStop depending on the channel type.
     
     > Similar to `streamFree()` method.
     */
    @MainActor
    func channelFree() {
        self.isUnloaded = (BASS_ChannelFree(self.stream) == 0)
        isPlaying = false
    }
    
    // MARK: MIDI Events
    
    /// Includes both `note-on` & `note-off` events.
    private(set) var noteEvents: [BASS_MIDI_EVENT] = []
    private(set) var notesCount: UInt32 = .zero
    private(set) var eventsCount: DWORD = .zero
    
    /**
     Retrieves the entire Note-Events (both `note-on` & `note-off`) of the current `stream`.
     
     > Usefull for visualization purposes
     */
    @MainActor
    func getAllNoteEvents() {
        // Determine the number of events
        let noteEventsCount = BASS_MIDI_StreamGetEvents(self.stream, -1, DWORD(MIDI_EVENT_NOTE), nil)
        // Divided by two, since every note has been counted twice (note-on, note-off)
        self.notesCount = noteEventsCount / 2
        // Allocate memory for the events
        self.noteEvents = [BASS_MIDI_EVENT](repeating: BASS_MIDI_EVENT(), count: Int(noteEventsCount))
        
        // Retrieve the events
        /// If successful, the number of events is returned, else -1 is returned.
        self.eventsCount = BASS_MIDI_StreamGetEvents(self.stream, -1, DWORD(MIDI_EVENT_NOTE), &noteEvents)
    }
    
    /// `MIDI_EVENT_NOTE` events with a **non-0 velocity**
    private(set) var noteOnEvents: [BASS_MIDI_EVENT] = []
    /// `MIDI_EVENT_NOTE` events with a **0 velocity**
    private(set) var noteOffEvents: [BASS_MIDI_EVENT] = []
    
    /**
     
     */
    @MainActor
    func getSeperatedNoteEvents() {
        // Determine the number of note-on events
        let noteOnEventsCount = BASS_MIDI_StreamGetEvents(self.stream, -1, DWORD(MIDI_EVENT_NOTES), nil)
        self.noteOnEvents = [BASS_MIDI_EVENT](repeating: BASS_MIDI_EVENT(), count: Int(noteOnEventsCount))
        
        BASS_MIDI_StreamGetEvents(self.stream, -1, DWORD(MIDI_EVENT_NOTES), &noteOnEvents)
        
        // Filter note-off events from the noteEvents array
        self.noteOffEvents = noteEvents.filter { $0.param.highByte == 0 }
    }
    
    @MainActor
    private func findNoteOffPair(of noteOn: BASS_MIDI_EVENT) -> BASS_MIDI_EVENT? {
        // Extract the key number and tick value from the specific note-on event
        let keyNumber = noteOn.param.lowByte
        let tickValue = noteOn.tick

        // Search for the corresponding note-off event based on key number and tick value
        // TODO: Remove the found element from the `noteOffEvents`
        if let matchingNoteOffEvent = noteOffEvents.first(where: { $0.param.lowByte == keyNumber && $0.tick >= tickValue }) {
            // Found a matching note-off event
            #if DEBUG
//                print("Found matching note-off event: \(matchingNoteOffEvent)")
            #endif
            return matchingNoteOffEvent
        } else {
            // No matching note-off event found
            print("No matching note-off event found for the specified note-on event.")
            return nil
        }
    }
    
    // TODO: Optimization required
    /**
     Returns the length of a specified note (a `note-on` event) **in ticks**
     */
    @MainActor
    func getLength(of note: BASS_MIDI_EVENT) -> UInt32? {
        if let noteOff = findNoteOffPair(of: note) {
            return noteOff.tick - note.tick
        }
        
        return nil
    }
    
    // MARK: - Experimental
    // syncing APIs
    
    var syncHandle: HSYNC = .zero
    
//    var currentChannel: DWORD = .zero
//    var currentKeynote: DWORD = .zero
    
    /**
     set a sync on MIDI_EVENT_NOTE events
     
     https://www.un4seen.com/forum/?topic=16562.msg115838;topicseen#msg115838
     */
    func setSync() {
        // Set a sync on MIDI_EVENT_NOTE events
        self.syncHandle = BASS_ChannelSetSync(
            self.stream,
            DWORD(BASS_SYNC_MIDI_EVENT),
            QWORD(MIDI_EVENT_NOTE),
            noteSyncProc, 
            .none
        )
        print(self.syncHandle)
    }
}

/// used in `SimpleModel.setSync()`.
private func noteSyncProc(handle: HSYNC, channel: DWORD, data: DWORD, user: UnsafeMutableRawPointer?) {
    /*
    // MIDI channel
    let midiChannel = (data >> 16) & 0xFF // Extract MIDI channel from the upper 8 bits of data
    // key number
    let note = (data >> 8) & 0xFF // Extract note from the middle 8 bits of data
    // key velocity (0=release)
    let velocity = data & 0xFF // Extract velocity from the lower 8 bits of data

    // Do something with the MIDI event data...
    // There's literally nothing to be done...
    print("""
            noteSyncProc; 
                midiChannel: \(midiChannel)
                keynote: \(note)
                velocity: \(velocity)
        """)
     */
}

// MARK: - Extensions

extension BOOL32 {
    static let `false` = BOOL32(truncating: false)
    static let `true` = BOOL32(truncating: true)
}

