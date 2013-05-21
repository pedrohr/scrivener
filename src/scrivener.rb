# -*- coding: utf-8 -*-
require 'pp'
class Scrivener
  attr_reader :articles, :dbpedia_info

  def _load_object(filename)
    unless File.exists?(filename)
      return false
    end

    begin
      file = File.open(filename, 'r')
      obj = Marshal.load file.read
      file.close
      return obj
    rescue
      return false
    end
  end

  def initialize(wikipedia_articles_file, dbpedia_relations_file)
    if File.exists?(wikipedia_articles_file)
      print "\rLoading articles file..."
      
      @articles = []
      lines = File.readlines(wikipedia_articles_file)

      lines.each do |line|
        if (line[0..3] == '<doc')
          @articles.push([line.match(/title=\"(.+)\"/)[1], ''])
        elsif (line[0..3] != '</do')
          (@articles.last)[1] += line
        end
      end

      lines = nil
    end

    @dbpedia_info = _load_object(dbpedia_relations_file)
  end

  def break_into_sentences(article)
    sentences = []
    article[1].split("\n").each do |paragraphs|
      paragraphs.split(".").each do |sentence|
        sentences.push(sentence.strip) if sentence.size > 3
      end
    end
    return sentences
  end

  def title_to_dbpedia_uri(title)
    title = title.dup
    title[0] = title[0].upcase
    return "/#{title.gsub(" ", "_")}"
  end

  def dbpedia_uri_to_title(uri)
    uri = uri.dup[1..uri.size]
    return "#{uri.gsub("_", " ")}"
  end

  def isolate_ids_and_pure_text(sentence)
    vec = []
    to_push = true

    return [""] if sentence.empty?

    sentence.split(" ").each do |token|
      if (token.include?("<db") or to_push)
        to_push = false

        vec.push(token)
      elsif token.include?("</db>")
        to_push = true
        vec[vec.size-1] = vec.last + " " + token
      else
        vec[vec.size-1] = vec.last + " " + token
      end
    end

    return vec
  end
  
  # Heuristic for name cases
  def _str_title_regexp(title)
    regexp = "#{title}"

    split = title.split(" ")
    if split.size > 1 and split.last == split.last.capitalize
      regexp += "|#{title.split(' ').first}|#{title.split(' ').last}"
    end

    return regexp
  end

  def _str_dbpedia_relations_names_to_regexp(relations_array)
    regexp = ""

    relations_array.each do |relation|
      object = dbpedia_uri_to_title(relation.first)
      regexp += "#{_str_title_regexp(object)}|"
    end
    
    regexp = regexp[0..regexp.size-2] if regexp[regexp.size-1] == '|'

    return regexp
  end

  def re_for_enrichment(title, dbpedia_info)
    re =  _str_title_regexp(title)
    
    title_uri = title_to_dbpedia_uri(title)
    
    relations = dbpedia_info[title_uri]

    if relations
      re += "|" + _str_dbpedia_relations_names_to_regexp(relations)
    end

    re = Regexp.new("(" + re + ")", true)
  end

  def resolve_match_to_uri(term, title, dbpedia_info)
    lookup = term.gsub(" ", "_").downcase
    title_uri = title_to_dbpedia_uri(title)
    
    if title_uri.downcase.include?(lookup)
      return title_uri
    end

    if dbpedia_info[title_uri]
      dbpedia_info[title_uri].each do |relation|
        if relation.first.downcase.include?(lookup)
          return relation.first
        end
      end
    end

    return title_to_dbpedia_uri(term)
  end

  def enrich(sentence, title, dbpedia_info)
    re = re_for_enrichment(title, dbpedia_info)

    parts = isolate_ids_and_pure_text(sentence)

    parts.each_with_index do |part, index|
      unless part.include?("<db")
        parts[index] = part.gsub(re) { |block|
          "<db id=#{resolve_match_to_uri(block, title, dbpedia_info)}>#{block}</db>"
        }
      end
    end

    return parts.join(" ")
  end

  def combinatorics_over_pairs_of_instances(tokenized_sentence)
    sentences = []
    instances_indexes = []
    
    tokenized_sentence.each_with_index do |token, index|
      if token.include?("<db")
        instances_indexes.push(index)
      end
    end

    0.upto(instances_indexes.size-1) do |i|
      (i+1).upto(instances_indexes.size-1) do |j|
        sentence = []
        tokenized_sentence.each_with_index do |token, index|
          if token.include?("<db")
            if (index == instances_indexes[i] or index == instances_indexes[j])
              term = "<" + token.split(">").first.match(/id=(.+)/)[1] + ">"
            else
              term = token.match(/>(.+)</)[1]
            end
            sentence.push(token.gsub(/<(.+)>/, term))
          else
            sentence.push(token)
          end
        end
        sentences.push(sentence.join(" "))
      end
    end

    return sentences
  end

  def extract_sentences
    sentences = []

    #enrichment
    @articles.each do |article|
      art_sentences = break_into_sentences(article)
      art_sentences.each do |sentence|
        sentences.push(enrich(sentence, article[0], @dbpedia_info))
      end
    end

    #filtering
    filtered_sentences = []
    sentences.delete_if do |sentence|
      tokens = isolate_ids_and_pure_text(sentence)

      #too short
      if tokens.size < 3
        true
      end

      instances = []
      tokens.each do |token|
        if token.include?("<db")
          instances.push(token)
        end
      end

      #less than 2 instances
      if instances.size < 2
        true
      end

      #combinatorics over pairs
      filtered_sentences.push(combinatorics_over_pairs_of_instances(tokens))
      false
    end

    return filtered_sentences.flatten
  end
end
