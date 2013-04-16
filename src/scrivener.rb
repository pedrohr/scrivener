class Scrivener
  attr_reader :wikipedia_dump_file

  def initialize(filename)
    @wikipedia_dump_file = File.open(filename, 'r')
  end
end
