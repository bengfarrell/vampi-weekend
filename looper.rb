# when describing a recording track (setting which one)
# the recording track is not 0 indexed like array access
sequence = [
               { notebuffer: [], playbackIndex: 0, startTime: 0, endTime: 0 }, #track 1
               { notebuffer: [], playbackIndex: 0, startTime: 0, endTime: 0 }, #track 2
               { notebuffer: [], playbackIndex: 0, startTime: 0, endTime: 0 }  #track 3
];

# current recording session holds times and which track is being recorded
recordingSession = {
  sessionStart: -1,
  sessionEnd: -1,
  track: -1,
  measureStart: -1,
  measureDuration: -1
};

define :recordingTriggerListener do |midipath, tracktriggers|
  note, velocity = sync midipath
  recordingTrack = tracktriggers.index note
    if recordingTrack != nil && recordingSession[:track] == -1
      recordingSession[:track] = tracktriggers[1] - note + 1
      puts "start recording track #", recordingSession[:track]
    else
      puts "stop recording track #", recordingSession[:track]
      recordingSession[:track] = -1
    end
end

define :noteUpListener do |midipath|
  use_real_time
  noteoff, velocityoff = sync midipath

  if recordingSession[:track] != -1
    recordTrackIndex = recordingSession[:track] - 1
    sequence[recordTrackIndex][:notebuffer].reverse.each do |i|
      if noteoff == i[:note] && i[:uptime] == -1
        i[:uptime] = (vt - recordingSession[:sessionStart]).round(1)
        # keep upping the stop time until we stop recording
        recordingSession[:sessionEnd] = vt
        sequence[recordTrackIndex][:endTime] = i[:downtime]
        break
      end
    end
  end
end

define :noteDownListener do |midipath|
    use_real_time
    note, velocity = sync midipath
    use_synth :piano
    play note, amp: velocity/127.0

    recordTrackIndex = recordingSession[:track] - 1
    if recordingSession[:track] != -1
      if sequence[recordTrackIndex][:notebuffer].length == 0
        # first note down marks beginning of the recording session
        # however the space between now and the start of the measure
        # is taken into account when playing back
        recordingSession[:sessionStart] = recordingSession[:measureStart]
        measureStartOffset = (vt - recordingSession[:measureStart]).round(1)
        sequence[recordTrackIndex][:startTime] = measureStartOffset
      end
      notetime = (vt - recordingSession[:sessionStart]).round(1)
      sequence[recordTrackIndex][:notebuffer].push({
       note: note,
       velocity: velocity,
       downtime: notetime,
       uptime: -1
      })
    end
end

define :playTrack do |trackNum|
  beatsPerMeasure = get(:beatsPerMeasure)
  bpmScaledMeasureDuration = beatsPerMeasure * (60 / get(:bpm).to_f)
  trackIndex = trackNum - 1
  track = sequence[trackIndex]
  notes = track[:notebuffer]
  if notes.length > 0 && trackNum != recordingSession[:track]
    use_synth :piano
    i = sequence[trackIndex][:playbackIndex]
    currNote = notes.ring[i]
    sequence[trackIndex][:playbackIndex] += 1
    play currNote[:note], sustain: (currNote[:uptime] - currNote[:downtime]).round(1), amp: (currNote[:velocity]/127.0)
    sleeptime = (notes.ring[i+1][:downtime] - currNote[:downtime]).round(1)
    if sleeptime < 0
      # looping around to beginning of buffer, get remaining time
      # in measure to sleep before resuming buffer again
      numMeasures = (track[:endTime] / bpmScaledMeasureDuration).to_i + 1
      sleeptime = (bpmScaledMeasureDuration * numMeasures - track[:endTime] - track[:startTime]).round(1)
    end
    sleep (sleeptime * (get(:bpm) / 60))
  else
    sleep bpmScaledMeasureDuration
  end
end

define :heartbeat do
  use_real_time
  beatsPerMeasure = get(:beatsPerMeasure)
  recordingSession[:measureStart] = vt
  sleep beatsPerMeasure
  recordingSession[:measureDuration] = vt - recordingSession[:measureStart]
end
