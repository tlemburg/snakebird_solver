class FileReader

  def self.read_file(filename)
    lines = []

    File.readlines(filename).each do |line|
      lines << line.chomp
    end

    lines
  end
end