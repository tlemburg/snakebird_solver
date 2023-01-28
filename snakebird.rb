require_relative './file_reader'
require_relative './point'

def deep_dup(obj)
  Marshal.load(Marshal.dump(obj))
end

lines = FileReader.read_file(ARGV[0])

first_state = {
  move_history: '',
  fruit_count: 0,
  bird: []
}

lines.each_with_index do |line, i|
  line.chars.each_with_index do |char, j|
    first_state[Point.new(j, i)] = char if char != '.' && !char.match?(/\d/)

    if char.match?(/\d/)
      first_state[:bird][char.to_i - 1] = Point.new(j, i)
    end
    first_state[:fruit_count] += 1 if char == 'F'
  end
end

$max_x = lines.first.length - 1
$max_y = lines.count - 1

$states = [first_state]
evaluated_states = []

def try_for_next(state, new_point, move)
  moved_to_star = state[new_point] == '*'
  # Add to move history
  state[:move_history] << move

  # Add to bird/sub from fruit if eating fruit (clear fruit)
  if state[new_point] == 'F'
    state[:fruit_count] -= 1
    state.delete(new_point)
    state[:bird].unshift(new_point)
  else
    # Pop end of bird, add new spot to bird
    state[:bird].unshift(new_point)
    state[:bird].pop
  end

  # Check for win condition
  if state[:fruit_count] == 0 && moved_to_star
    puts state[:move_history]
    exit
  end
  # Now do falling if necessary.
  should_do_next_state = true
  loop do
    # Each loop means, we fall one spot
    # First check if we hit walls or fruit
    stop_falling = false
    state[:bird].each do |point|
      if ['F', 'N'].include?(state[point.py])
        stop_falling = true
        break
      end
    end
    break if stop_falling

    # Check if we hit spikes. If so, we die and this new state is bad.
    hitting_x = false
    state[:bird].each do |point|
      if ['x'].include?(state[point.py]) || point.py.y > 13
        hitting_x = true
        break
      end
    end

    if hitting_x
      should_do_next_state = false
      break
    end

    # We now need to drop the bird one spot.
    state[:bird].each_with_index do |point, x|
      state[:bird][x] = point.py
    end
    # loop complete, see if we will fall again!
  end

  if should_do_next_state
    $states << state
  end

end

# BFS
until $states.empty?
  current_state = $states.shift

  state_hash = deep_dup(current_state)
  state_hash.delete(:move_history)
  state_hash = state_hash.to_s.hash

  next if evaluated_states.include?(state_hash)
  evaluated_states << state_hash

  puts current_state[:move_history].length
  puts current_state.inspect

  # Check each direction of possible move
  # UP
  if [nil, 'F', '*'].include?(current_state[current_state[:bird][0].my]) &&
    !current_state[:bird].include?(current_state[:bird][0].my)

    try_for_next(deep_dup(current_state), current_state[:bird][0].my, 'U')
  end

  # DOWN
  if [nil, 'F', '*'].include?(current_state[current_state[:bird][0].py]) &&
    !current_state[:bird].include?(current_state[:bird][0].py)

    try_for_next(deep_dup(current_state), current_state[:bird][0].py, 'D')
  end

  # LEFT
  if [nil, 'F', '*'].include?(current_state[current_state[:bird][0].mx]) &&
    !current_state[:bird].include?(current_state[:bird][0].mx)

    try_for_next(deep_dup(current_state), current_state[:bird][0].mx, 'L')
  end

  # RIGHT
  if [nil, 'F', '*'].include?(current_state[current_state[:bird][0].px]) &&
    !current_state[:bird].include?(current_state[:bird][0].px)

    try_for_next(deep_dup(current_state), current_state[:bird][0].px, 'R')
  end

end