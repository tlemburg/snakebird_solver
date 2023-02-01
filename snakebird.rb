require_relative './language'
require_relative './file_reader'
require_relative './point'
require_relative './state'

# TODO: Multi-bird: Need to be able to PUSH the other birds.
# TODO: Make it so that all birds fall on a move, not just the one moving.
# TODO: Implement Level 7 and 13. Level 42.

lines = FileReader.read_file(ARGV[0])

first_state = State.new(
  level: {},
  birds: {},
  move_history: []
)

lines = lines.split('')

lines.first.each_with_index do |line, i|
  if line.chars.uniq == ['-']
    first_state.bottom_y = i
  else
    line.chars.each_with_index do |char, j|
      first_state.level[Point.new(j, i)] = char if char != '.'
    end
  end
end

lines.last.each_with_index do |line, i|
  coords_arr = line.split(',').map(&:to_i)
  bird = []
  until coords_arr.empty?
    bird << Point.new(coords_arr.shift, coords_arr.shift)
  end
  first_state.birds[i] = bird
end

states = [first_state]
evaluated_states = []

MAX_DEPTH = nil

# BFS
until states.empty?
  current_state = states.shift

  next if MAX_DEPTH && current_state.move_history.count > MAX_DEPTH

  next if evaluated_states.include?(current_state.comparison_hash)
  evaluated_states << current_state.comparison_hash

  # Debug
  puts current_state.move_history.count
  puts current_state.inspect

  # Check each direction of possible move, for each bird
  current_state.birds.each do |i, bird|
    %w(U L D R).each do |move|
      if current_state.can_bird_move?(bird_index: i, move: move)
        new_state = current_state.dup
        new_state.execute_move(bird_index: i, move: move)

        if new_state.win?
          puts new_state.move_history.join(' ')
          exit
        end

        unless new_state.death?
          states << new_state
        end
      end
    end
  end
end