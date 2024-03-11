puts __dir__
run_file "~/Documents/projects/web/vampi-weekend/looper.rb"

set :bpm, 120
set_link_bpm! 120
set :beatsPerMeasure, 4

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
live_loop :midi_up do noteup_input "/midi:mpkmini2:1/note_off", [44, 45] end
live_loop :midi_down do notedown_input "/midi:mpkmini2:1/note_on", [44, 45] end
live_loop :heartbeat do heartbeat end
