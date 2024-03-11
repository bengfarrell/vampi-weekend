playalong_downkeys = [];
rootDelta = 0;
_originalRoot = 0;
_originalOctave = 0;
nextInputIsRoot = true
isPlaying = false;

define :playalong do |notes, velocity=127.0|
    notes.each do |note|
        play note + rootDelta, amp: velocity/127.0 if isPlaying
    end
end

define :samplalong do |samp|
    sample samp if isPlaying
end

define :togglePlayalong do |ctrlmidipath, originalRoot, toggleCmd, setRootCmd|
  use_real_time
  note, velocity = sync ctrlmidipath

  _originalRoot = originalRoot - 0
  _originalOctave = (_originalRoot / 12).to_i()
  updateDelta (note - 0)

  if note == toggleCmd
    isPlaying = !isPlaying
  end

  if note == setRootCmd
    nextInputIsRoot = true
  end
end

define :setPlayalongRootListener do |keysmidipath|
    use_real_time
    note, velocity = sync keysmidipath
    if nextInputIsRoot
      newroot = note % 12 + _originalOctave * 12
      rootDelta = newroot - _originalRoot
      nextInputIsRoot = false
    end
end

define :activatePlayalongListener do |originalRoot, midipath|
  use_real_time
  note, velocity = sync midipath
  _originalRoot = originalRoot - 0
  _originalOctave = (_originalRoot / 12).to_i()
  playalong_downkeys.push(note)
  isPlaying = playalong_downkeys.length > 0
  updateDelta note
end


define :suspendPlayalongListener do |midipath|
  use_real_time
  note, velocity = sync midipath
  playalong_downkeys.delete(note)
  isPlaying = playalong_downkeys.length > 0
  updateDelta note
end

define :updateDelta do |note|
  if playalong_downkeys.length != 0
      newroot = playalong_downkeys.min() % 12 + _originalOctave * 12
      rootDelta = newroot - _originalRoot
  end
end