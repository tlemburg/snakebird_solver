class State
  attr_accessor :birds, :blocks, :level, :move_history, :bottom_y

  DIRECTION_MAP = {
    'U' => :my,
    'D' => :py,
    'L' => :mx,
    'R' => :px
  }

  def initialize(level:, birds:, move_history: [], bottom_y: 0)
    @level = level
    @birds = birds
    @move_history = move_history

    @death = false
    @bottom_y = bottom_y
  end

  def win?
    @birds.count == 0
  end

  def death?
    @death
  end

  def wall_points
    @level.select do |key, value|
      value.in?(['#', 'N'])
    end.keys
  end

  def spike_points
    @level.select do |key, value|
      value == 'x'
    end.keys
  end

  def fruit_points
    @level.select do |key, value|
      value == 'F'
    end.keys
  end

  def dup
    raise 'Cannot dup dead state' if death?

    self.class.new(
      level: self.level.dup,
      birds: self.birds.dup.transform_values {|bird| bird.map(&:dup)},
      move_history: self.move_history.dup,
      bottom_y: @bottom_y
    )
  end

  def fruit_count
    level.select do |key, value|
      value == 'F'
    end.count
  end

  def can_bird_move?(bird_index:, move:)
    bird_head = @birds[bird_index].first
    new_point = bird_head.send(DIRECTION_MAP[move])

    # Can always move the head into a fruit, but afterward, for pushing,
    # a fruit is like a wall.
    return true if new_point.in?(fruit_points)

    stop_points = wall_points + spike_points + fruit_points + @birds[bird_index]
    moving_into_points = [new_point]
    pushing_birds = []

    until moving_into_points.empty?
      moving_into_point = moving_into_points.shift

      # Can never move into a stop point.
      return false if stop_points.include?(moving_into_point)

      # Is new point a pushable object? (i.e. a bird)
      @birds.each do |i, bird|
        next if bird_index == i || pushing_birds.include?(i)
        if bird.include?(moving_into_point)
          # This bird is being pushed. Add it to pushing_birds, and mark it's
          # points as we're moving into those too.
          pushing_birds << i
          moving_into_points.concat(bird.map{|point| point.send(DIRECTION_MAP[move])})
        end
      end

      # If moving_into_point is not a stop point or a pushable object,
      # it is fine. Move on.
    end

    true
  end

  def execute_move(bird_index:, move:)
    # Add to move history
    @move_history << "#{bird_index}-#{move}"

    bird_head = @birds[bird_index].first
    new_point = bird_head.send(DIRECTION_MAP[move])

    # Add to bird/sub from fruit if eating fruit (clear fruit)
    if @level[new_point] == 'F'
      @level.delete(new_point)
      @birds[bird_index].unshift(new_point)
    else
      # Pop end of bird, add new spot to bird
      @birds[bird_index].unshift(new_point)
      @birds[bird_index].pop
    end

    # Was anything pushed?
    pushing_birds = []
    moving_into_points = [new_point]
    until moving_into_points.empty?
      moving_into_point = moving_into_points.shift

      @birds.each do |i, bird|
        next if bird_index == i || pushing_birds.include?(i)
        if bird.include?(moving_into_point)
          # This bird is being pushed. Add it to pushing_birds, and mark it's
          # points as we're moving into those too.
          pushing_birds << i
          moving_into_points.concat(bird.map{|point| point.send(DIRECTION_MAP[move])})
        end
      end
    end
    # For each pushing bird, move it one step in the direction
    pushing_birds.each do |i|
      @birds[i].each_index do |j|
        @birds[i][j] = @birds[i][j].send(DIRECTION_MAP[move])
      end
    end

    # Check if any bird is leaving level
    @birds.each do |i, bird|
      if fruit_count == 0 && @level[bird[0]] == '*'
        @birds.delete(i)
      end
    end

    unless @birds.empty?
      # Now do falling for all birds.
      # We can "fall" one bird at a time.
      loop do
        # Each loop means, one bird falls one spot
        bird_fell = false

        @birds.each do |i, bird|
          # First check if we hit walls or fruit or another bird
          stop_falling = false
          @birds[i].each do |point|
            if ['F', 'N', '#'].include?(@level[point.py])
              stop_falling = true
              break
            end

            other_birds_points = @birds.values.flatten - @birds[i]

            if other_birds_points.include?(point.py)
              stop_falling = true
              break
            end
          end
          next if stop_falling

          # Check if we hit spikes. If so, we die and this new state is bad.
          hitting_x = false
          @birds[i].each do |point|
            if ['x'].include?(@level[point.py]) || point.py.y >= @bottom_y
              hitting_x = true
              break
            end
          end

          @death = true and return if hitting_x

          # This bird is falling!
          bird_fell = true

          # We now need to drop the bird one spot.
          @birds[i].each_with_index do |point, j|
            @birds[i][j] = point.py
          end

          # Don't check other birds, re-loop
          break
        end

        # Finish loop if no bird fell
        break unless bird_fell

      # End of loop, see if we fall again!
      end
    end

  end

  def comparison_hash
    "#{@level.to_s} #{@birds.to_s}".hash
  end


end