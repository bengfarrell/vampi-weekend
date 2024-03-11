puts __dir__
run_file "~/Documents/projects/web/vampi-weekend/playalong.rb"

set :bpm, 120
set_link_bpm! 120
set :beatsPerMeasure, 4

#live_loop :activatePlayalongListener do activatePlayalongListener :C3, "/midi:juno-ds:1/note_on" end
#live_loop :suspendPlayalongListener do suspendPlayalongListener "/midi:juno-ds:1/note_on" end

live_loop :togglePlayalong do togglePlayalong "/midi:juno-ds:10/note_on", :C, 36, 38 end
live_loop :setPlayalongRootListener do setPlayalongRootListener "/midi:juno-ds:1/note_on" end

live_loop :bassline do
  use_synth :fm
  playalong [:C]
  sleep 1
  playalong [:E]
  sleep 1
  playalong [:G]
  sleep 0.5
  playalong [:F]
  sleep 0.5
  playalong [:D]
  sleep 1
  playalong [:C]
end


live_loop :drums do
  samplalong :drum_heavy_kick
  sleep 1
  samplalong :drum_snare_hard
  sleep 1
  samplalong :drum_heavy_kick
  sleep 1
  samplalong :drum_snare_hard
  sleep 1
end

live_loop :hihat do
  samplalong :drum_cymbal_closed
  sleep 1
  samplalong :drum_cymbal_pedal
  sleep 1
end