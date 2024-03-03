# when describing a recording track (setting which one)
# the recording track is not 0 indexed like array access
sequence = [   { notebuffer: [], playbackIndex: 0, startTime: 0, endTime: 0, numMeasures: 0, measureDuration: 0 }, #track 1
               { notebuffer: [], playbackIndex: 0, startTime: 0, endTime: 0, numMeasures: 0, measureDuration: 0 }, #track 2
               { notebuffer: [], playbackIndex: 0, startTime: 0, endTime: 0, numMeasures: 0, measureDuration: 0 }  #track 3
];

# current recording session holds times and which track is being recorded
recordingSession = { 
  sessionStart: -1,
  sessionEnd: -1,
  track: -1,
  measureStart: -1,
  measureDuration: -1
};

set :bpm, 120
set_link_bpm! 120


live_loop :control_input do
  use_real_time
  channel, value = sync "/midi:mpkmini2:1/control_change"
  set_link_bpm! value * 2
  set :bpm, value * 2
end

live_loop :noteup_input do
  use_real_time
  noteoff, velocityoff = sync "/midi:mpkmini2:1/note_off"

  if (noteoff != 44 || noteoff != 45) && recordingSession[:track] != -1
    recordTrackIndex = recordingSession[:track] - 1
    sequence[recordTrackIndex][:notebuffer].reverse.each do |i|
      if noteoff == i[:note] && i[:uptime] == -1
        i[:uptime] = vt - recordingSession[:sessionStart]
        # keep upping the stop time until we stop recording
        sequence[recordTrackIndex][:stopTime] = i[:uptime]
        sequence[recordTrackIndex][:numMeasures] = (i[:uptime] / recordingSession[:measureDuration]).to_i
        sequence[recordTrackIndex][:measureDuration] = recordingSession[:measureDuration]
        break
      end
    end
  end
end

live_loop :notedown_input do
  use_real_time
  note, velocity = sync "/midi:mpkmini2:1/note_on"
  if (note == 44 || note == 45)
    if recordingSession[:track] == -1
      recordingSession[:track] = 45 - note + 1
      puts "start recording track #", recordingSession[:track]
    else
      puts "stop recording track #", recordingSession[:track]
      recordingSession[:track] = -1
    end
  else
    use_synth :piano
    play note, amp: velocity/127.0
    
    recordTrackIndex = recordingSession[:track] - 1
    if recordingSession[:track] != -1
      if sequence[recordTrackIndex][:notebuffer].length == 0
        recordingSession[:sessionStart] = recordingSession[:measureStart]
        measureStartOffset = vt - recordingSession[:measureStart]
        sequence[recordTrackIndex][:startTime] = measureStartOffset
      end
      notetime = vt - recordingSession[:sessionStart]
      sequence[recordTrackIndex][:notebuffer].push({ 
       note: note,
       velocity: velocity,
       downtime: notetime,
       uptime: -1
      })
    end
  end
end

live_loop :drums do
  sample :drum_heavy_kick
  sample :drum_cowbell
  sleep 1
  sample :drum_snare_hard
  sleep 1
  sample :drum_heavy_kick
  sleep 1
  sample :drum_snare_hard
  sleep 1
end

live_loop :hihat do
  sample :drum_cymbal_closed
  sleep 0.5
  sample :drum_cymbal_pedal
  sleep 0.5
end

live_loop :track1 do trackplay 1 end
live_loop :track2 do trackplay 2 end
live_loop :heartbeat do heartbeat 4 end

define :trackplay do |trackNum|
  trackIndex = trackNum - 1
  track = sequence[trackIndex]
  notes = track[:notebuffer]
  if notes.length > 0 && trackNum != recordingSession[:track]
    use_synth :piano
    i = sequence[trackIndex][:playbackIndex]
    currNote = notes.ring[i]
    sequence[trackIndex][:playbackIndex] += 1
    play currNote[:note], sustain: currNote[:uptime] - currNote[:downtime], amp: (currNote[:velocity]/127.0)
    sleeptime = notes.ring[i+1][:downtime] - currNote[:downtime]
    if sleeptime < 0
      # looping around to beginning of buffer, get remaining time
      # in measure to sleep before resuming buffer again
      puts track[:numMeasures], track[:measureDuration]
      sleeptime = track[:numMeasures] * track[:measureDuration] - track[:endTime]
    end
    sleep sleeptime * (get(:bpm) / 60)
  else
    sleep 4
  end
end

define :heartbeat do |beatsPerMeasure|
  use_real_time
  recordingSession[:measureStart] = vt
  #if measureDuration != -1
    # realtimeOffset = vt % measureDuration (do we need this?)
  #end
  sleep beatsPerMeasure
  recordingSession[:measureDuration] = vt - recordingSession[:measureStart]
end

