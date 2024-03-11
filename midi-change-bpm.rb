live_loop :control_input do
  use_real_time
  channel, value = sync "/midi:mpkmini2:1/control_change"
  set_link_bpm! value * 2
  set :bpm, value * 2
end