use_real_time

downkeys = [];
lastNote = 0;
lastVelocity = 0;

live_loop :midi_piano do
  note, velocity = sync "/midi:mpkmini2:1/note_on"
  use_synth :piano
  play note, amp: lastVelocity/127.0
end

live_loop :startcue do
  note, velocity = sync "/midi:mpkmini2:1/note_on"
  downkeys.push(note)
  lastNote = downkeys.min()
  lastVelocity = velocity
end


live_loop :stopcue do
  note, velocity = sync "/midi:mpkmini2:1/note_off"
  downkeys.delete(note)
  lastNote = downkeys.min()
  if lastNote == nil
    lastNote = 0
  end
end


live_loop :bassline do
  use_synth :chipbass
  play [lastNote, lastNote+4], amp: lastVelocity/127.0 if downkeys.length > 0
  sleep 0.5
  play [lastNote+7, lastNote], amp: lastVelocity/127.0 if downkeys.length > 0
  sleep 0.5
  play [lastNote], amp: lastVelocity/127.0 if downkeys.length > 0
  sleep 0.25
  play [lastNote+2], amp: lastVelocity/127.0 if downkeys.length > 0
  sleep 0.25
  play [lastNote+3], amp: lastVelocity/127.0 if downkeys.length > 0
  sleep 0.5
  play [lastNote, lastNote+4], amp: lastVelocity/127.0 if downkeys.length > 0
end


live_loop :drums do
  sample :drum_heavy_kick if downkeys.length > 0
  sleep 1
  sample :drum_snare_hard if downkeys.length > 0
  sleep 1
  sample :drum_heavy_kick if downkeys.length > 0
  sleep 1
  sample :drum_snare_hard if downkeys.length > 0
  sleep 1
end

live_loop :hihat do
  sample :drum_cymbal_closed if downkeys.length > 0
  sleep 0.5
  sample :drum_cymbal_pedal if downkeys.length > 0
  sleep 0.5
end

define :play_timed do |notes, times, **args|
  ts = times.ring
  notes.each_with_index do |note, i|
    use_synth :bass_foundation
    play note, **args if downkeys > 0
    sleep ts[i]
  end
end

