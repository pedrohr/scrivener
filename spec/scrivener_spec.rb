# -*- coding: utf-8 -*-
require 'nokogiri'
require 'test/unit'
require './src/scrivener.rb'

class ScrivenerTest < Test::Unit::TestCase
  def setup
    @wikipedia_dump = './spec/mock/wikipedia_dump_sample.xml'
    @invalid_xml_file = './spec/mock/invalid_xml_file.xml'

    @example_text = "==Etymology and terminology==
      {{Redirect|Anarchist|the fictional character|Anarchist (comics)}}
      {{Redirect|Anarchists}}
      {{pp-move-indef}}{{Use dmy dates|date=July 2012}}
      {{Anarchism sidebar}}

      [[File:WilliamGodwin.jpg|left|thumb|[[William Godwin]], &quot;the first to formulate the political and economical conceptions of anarchism, even though he did not give that name to the ideas developed in his work&quot;.&lt;ref name=&quot;EB1910&quot; /&gt;]]
      &lt;!--Anarcho-communist Joseph Déjacque, the first person to use the term &quot;libertarian&quot; in a political sense and self-proclaimed advocate of libertarianism, needs to be added here. His work and stances on anarchism are very relevant to this particular section of the article. Additionally, his criticisms of Pierre-Joseph Proudhon's mutualism are very relevant here.--&gt;
      Honestly, [[William Godwin]] was a crazy man.
      * A silly link
"

    @scrivener = Scrivener.new(@wikipedia_dump)
  end

  def test_should_open_wikimedia_dump_file
    file = File.open(@wikipedia_dump, 'r')
    assert(File.identical?(@scrivener.raw_wikipedia_dump_file, file))
  end

  # I assume that the XML is correctly parsed by the Nokogiri library if no exception
  # is raised. Therefore, no unit test for this feature will be inserted here.

  def test_should_parser_valid_xml_file
    assert_nothing_raised do
      @scrivener = Scrivener.new(@wikipedia_dump)
    end

    assert_raise Nokogiri::XML::SyntaxError do
      Scrivener.new(@invalid_xml_file)
    end
  end

  def test_should_parse_raw_file
    assert_equal(@scrivener.processed_wikipedia_dump.nil?, false)
  end

  def test_should_detect_articles
    @scrivener.parse_pages

    assert_equal(@scrivener.articles.size, 2)

    assert_equal(@scrivener.articles.first, ['AccessibleComputing', '#REDIRECT [[Computer accessibility]] {{R from CamelCase}}'])
  end

  def test_should_break_text_into_lines_and_resolve_links
    @scrivener.parse_pages
    assert_equal(@scrivener.parse_text(@example_text), 
                 ["<http://dbpedia.org/resource/William_Godwin>, the first to formulate the political and economical conceptions of anarchism, even though he did not give that name to the ideas developed in his work.",
                  "Anarcho-communist Joseph Déjacque, the first person to use the term libertarian in a political sense and self-proclaimed advocate of libertarianism, needs to be added here.",
                  "His work and stances on anarchism are very relevant to this particular section of the article.",
                  "Additionally, his criticisms of Pierre-Joseph Proudhon's mutualism are very relevant here.",
                 "Honestly, <http://dbpedia.org/resource/William_Godwin> was a crazy man.",
                 "A silly link."])
  end

  def test_should_replace_title_names_by_links
    
  end
end
