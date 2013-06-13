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

      print "\rClustering lines by articles titles..."
      lines.each do |line|
        if (line[0..3] == '<doc')
          @articles.push([line.match(/title=\"(.+)\"/)[1], ''])
        elsif (line[0..3] != '</do')
          (@articles.last)[1] += line
        end
      end

      lines = nil
    end

    print "\rLoading dbpedia relations file..."
    @dbpedia_info = _load_object(dbpedia_relations_file)
    print "\rDone!\n"
  end

  def break_into_sentences(article)
    sentences = []
    article[1].split("\n").each do |paragraphs|
      new_paragraph = true
      paragraphs.split(".").each do |sentence|
        if sentence.size > 3
          if new_paragraph
            sentences.push(sentence.strip)
            new_paragraph = false
          else
            if sentence[0] != " "
              if sentences.size == 0
                sentences.push(sentence.strip)
              else
                sentences[sentences.size-1] += ".#{sentence}"
              end
            else
              sentences.push(sentence.strip)
            end
          end
        end
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
    regexp = Regexp.quote("#{title}")

    split = title.split(" ")
    if split.size > 1 and split.last == split.last.capitalize
      regexp += "|#{Regexp.quote(title.split(' ').first)}|#{Regexp.quote(title.split(' ').last)}"
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

  def judge_sentence(instance_1, instance_2)
    unless @dbpedia_info[instance_1].nil?
      return @dbpedia_info[instance_1][instance_2] if @dbpedia_info[instance_1][instance_2]
    end

    unless @dbpedia_info[instance_2].nil?
      return @dbpedia_info[instance_2][instance_1] if @dbpedia_info[instance_2][instance_1]
    end

    return false
  end
  
  def combinatorics_over_pairs_of_instances(tokenized_sentence, filter)
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
        i1 = ""
        i2 = ""
        tokenized_sentence.each_with_index do |token, index|
          if token.include?("<db")
            if (index == instances_indexes[i] or index == instances_indexes[j])
              term_id = token.split(">").first.match(/id=(.+)/)[1]
              term_used = token.match(/>(.+)</)[1]
              term = "<" + term_used.gsub(" ", "_") + term_id + ">"

              if i1.empty?
                i1 = term_id
              else
                i2 = term_id
              end
            else
              if token.match(/>(.+)</).nil?
                pp tokenized_sentence
              end
              term = token.match(/>(.+)</)[1]
            end
            sentence.push(token.gsub(/<(.+)>/, term))
          else
            sentence.push(token)
          end
        end

        sentence = sentence.join(" ")

        if filter
          relation = judge_sentence(i1, i2)
          sentences.push([sentence, relation]) if relation
        else
          sentences.push(sentence) unless sentence.empty?
        end

      end
    end

    return sentences
  end

  def extract_sentences
    sentences = []

    #enrichment
    i = 1
    @articles.each do |article|
      print "\rBreaking and enriching sentences of article #{i} of #{@articles.size}..."

      art_sentences = break_into_sentences(article)
      art_sentences.each do |sentence|
        sentences.push(enrich(sentence, article[0], @dbpedia_info))
      end

      i += 1
    end

    #filtering
    i = 1
    filtered_sentences = []
    sentences.delete_if do |sentence|
      print "\rProcessing sentence #{i} of #{sentences.size}..."
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
      else
        sentences = combinatorics_over_pairs_of_instances(tokens, true)
        sentences.each do |sentence|
          filtered_sentences.push(sentence) unless sentence.empty?
        end
      end

      false
    end

    return filtered_sentences
  end
end
