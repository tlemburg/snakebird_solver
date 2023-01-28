class Point
  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def px
    self.class.new(x+1, y)
  end

  def py
    self.class.new(x, y+1)
  end

  def mx
    self.class.new(x-1, y)
  end

  def my
    self.class.new(x, y-1)
  end

  def eql?(other)
    @x == other.x && @y == other.y
  end

  def hash
    "#{@x},#{@y}".hash
  end

  def to_s
    "<#{@x},#{@y}>"
  end

  def inspect
    to_s
  end

  def ==(other)
    self.x == other.x && self.y == other.y
  end
end