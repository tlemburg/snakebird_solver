class Object
  def in?(array)
    array.include?(self)
  end
end

class Array
  def split(value = nil)
    arr = dup
    result = []
    if block_given?
      while (idx = arr.index { |i| yield i })
        result << arr.shift(idx)
        arr.shift
      end
    else
      while (idx = arr.index(value))
        result << arr.shift(idx)
        arr.shift
      end
    end
    result << arr
  end
end