# -*- coding: utf-8 -*-
require 'nokogiri'
require 'punkt-segmenter'

class Scrivener
  attr_reader :raw_wikipedia_dump_file, :processed_wikipedia_dump, :articles

  def initialize(filename)
    @raw_wikipedia_dump_file = File.open(filename, 'r')

    unless @raw_wikipedia_dump_file.nil?
      print "\rLoading XML file..."
      @processed_wikipedia_dump = Nokogiri::XML(@raw_wikipedia_dump_file.read, nil, 'UTF-8') do |config|
        config.strict
      end
    end
  end

  def read_pages
    @raw_wikipedia_dump_file = nil

    pages = @processed_wikipedia_dump.search("page")

    @articles = []
    pages.each do |page|
      @articles.push([page.search("title").children.first.to_s, page.search("text").children.first.to_s] ) unless page.search("text").nil?
    end

    @processed_wikipedia_dump = nil
  end

  def parse_pages
    read_pages
    @articles.each do |art|
      art[1] = parse_text(art[0], art[1])
    end
  end

  def clear_inside_brackets(text)
    text = text[2..text.size-3]

    # check if its a File inside a bracket
    if text.include?("File:")
      params = text.split(",")
      params[0] = "<http://dbpedia@@@org/resource/" + params[0].match(/\[\[(.+)\]\]/)[1].gsub(" ", "_") + ">"
      text = params.join(",")
    else
      text = "<http://dbpedia@@@org/resource/" + text.gsub(' ', '_') + ">"
    end

    # replacing . for @@@ in links in order to avoid future misspliting in sentences
    return text
  end

  def clear_text(title, text)
    text.gsub!(/\[\[(.+)\]\]/) {|block| clear_inside_brackets(block)}

    text.gsub!(Regexp.new(title, true), "<http://dbpedia@@@org/resource/" + title.gsub(' ', '_') + ">")
    
    [/\&lt\;!--(.+)--\&gt\;/].each do |pt|
      text.gsub!(pt, '\1')
    end
    
    [/\&lt\;ref(.+)\/\&gt\;/, "\"", "&quot;",/\{\{(.+)\}\}/, /==(.+)==/, "*", "----", "#", /''+/].each do |pt|
      text.gsub!(pt, "")
    end
  end

  def parse_text(title, text)
    sentences = []

    # resolve links and remove quotes and references
    clear_text(title, text)

    text.each_line do |paragraph|
      prospective = paragraph.split(".")
      
      open = 0
      aggregator = ""

      prospective.each do |sentence|
        sentence.strip!
        aggregated = false

        left = sentence.include?("[[")
        right = sentence.include?("]]")

        if left
          open += 1

          aggregator += sentence + "."
          aggregated = true
        end

        if right
          open -= 1

          unless aggregated
            aggregator += (sentence + ".")
          end

          if open == 0
            if aggregator.split(" ").size > 1
              aggregator.gsub!('@@@', '.')
              sentences.push(aggregator)
            end
            aggregator = ""
          end
        end

        unless left and right
          if sentence.split(" ").size > 1
            sentence.gsub!('@@@', '.')
            sentences.push(sentence + ".")
          end
        end
      end
    end

    return sentences
  end
end
