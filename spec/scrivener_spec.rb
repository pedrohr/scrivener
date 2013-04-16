require 'test/unit'
require './src/scrivener.rb'

class ScrivenerTest < Test::Unit::TestCase
  def setup
    @wikipedia_dump = './spec/mock/wikipedia_dump_sample.xml'
    @scrivener = Scrivener.new(@wikipedia_dump)
  end

  def test_should_open_wikimedia_dump_file
    file = File.open(@wikipedia_dump, 'r')
    assert(File.identical?(@scrivener.wikipedia_dump_file, file))
  end
end
