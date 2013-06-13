# -*- coding: utf-8 -*-
require 'test/unit'
require './src/scrivener.rb'

class ScrivenerTest < Test::Unit::TestCase
  def setup
    @text = 'Anarchism

Anarchism is often defined as a <db id=/Political_philosophy>political philosophy</db> which holds the <db id=/State_(polity)>state</db> to be undesirable, unnecessary, or harmful. However, others argue that while anti-statism is central, it is inadequate to define anarchism. Therefore, they argue instead that anarchism entails opposing <db id=/Authority>authority</db> or <db id=/Hierarchical_organization>hierarchical organization</db> in the conduct of human relations, including, but not only, the state system. Proponents of anarchism, known as "anarchists", advocate <db id=/Stateless_society>stateless societies</db> based on non-<db id=/Hierarchy>hierarchical</db> <db id=/Free_association_(communism_and_anarchism)>free associations</db>.
As a subtle and anti-dogmatic philosophy, anarchism draws on many currents of thought and strategy. Anarchism does not offer a fixed body of doctrine from a single particular world view, instead fluxing and flowing as a philosophy. There are many types and traditions of anarchism, not all of which are mutually exclusive. <db id=/Anarchist_schools_of_thought>Anarchist schools of thought</db> can differ fundamentally, supporting anything from extreme <db id=/Individualism>individualism</db> to complete collectivism. Strains of anarchism have often been divided into the categories of <db id=/Social_anarchism>social</db> and <db id=/Individualist_anarchism>individualist anarchism</db> or similar dual classifications.
Anarchism as a mass <db id=/Social_movement>social movement</db> has regularly endured fluctuations in popularity. The central tendency of anarchism as a social movement has been represented by <db id=/Anarchist_communism>anarcho-communism</db> and <db id=/Anarcho-syndicalism>anarcho-syndicalism</db>, with <db id=/Individualist_anarchism>individualist anarchism</db> being primarily a literary phenomenon which nevertheless did have an impact on the bigger currents and individualists have also participated in large anarchist organizations.
Etymology and terminology.
'

    @example_text = '<doc id="12" url="http://en.wikipedia.org/wiki?curid=12" title="Anarchism">' + @text + '</doc>'

    @scrivener = Scrivener.new('./spec/mocks/wiki_00', './spec/mocks/dbpedia_relations')

    # Example of dbpedia_relations:
    # {"/Anarchism"=>
    #  {"/Political_philosophy" => "/philosophy", "/Social_movement" => "/partOf"},
    #  "/Irving_Shulman"=> {"/Rebel_without_a_case" => "/wrote"}}
  end

  def test_should_detect_articles
    assert_equal(@scrivener.articles.size, 1)
    assert_equal(@scrivener.articles.first, ['Anarchism', @text])
  end

  def test_should_break_text_into_lines
    assert_equal(@scrivener.break_into_sentences(['Bug point id', 'Weird example with <db id=/1q21.1_duplication_syndrome>syndrome</db>. La la.']), ['Weird example with <db id=/1q21.1_duplication_syndrome>syndrome</db>', 'La la'])
    
    assert_equal(@scrivener.break_into_sentences(['Anarchism', @text]),
                 ['Anarchism',
                  'Anarchism is often defined as a <db id=/Political_philosophy>political philosophy</db> which holds the <db id=/State_(polity)>state</db> to be undesirable, unnecessary, or harmful',
                  'However, others argue that while anti-statism is central, it is inadequate to define anarchism',
                  'Therefore, they argue instead that anarchism entails opposing <db id=/Authority>authority</db> or <db id=/Hierarchical_organization>hierarchical organization</db> in the conduct of human relations, including, but not only, the state system',
                  'Proponents of anarchism, known as "anarchists", advocate <db id=/Stateless_society>stateless societies</db> based on non-<db id=/Hierarchy>hierarchical</db> <db id=/Free_association_(communism_and_anarchism)>free associations</db>',
                  'As a subtle and anti-dogmatic philosophy, anarchism draws on many currents of thought and strategy',
                  'Anarchism does not offer a fixed body of doctrine from a single particular world view, instead fluxing and flowing as a philosophy',
                  'There are many types and traditions of anarchism, not all of which are mutually exclusive', 
                  '<db id=/Anarchist_schools_of_thought>Anarchist schools of thought</db> can differ fundamentally, supporting anything from extreme <db id=/Individualism>individualism</db> to complete collectivism',
                  'Strains of anarchism have often been divided into the categories of <db id=/Social_anarchism>social</db> and <db id=/Individualist_anarchism>individualist anarchism</db> or similar dual classifications',
                  'Anarchism as a mass <db id=/Social_movement>social movement</db> has regularly endured fluctuations in popularity',
                  'The central tendency of anarchism as a social movement has been represented by <db id=/Anarchist_communism>anarcho-communism</db> and <db id=/Anarcho-syndicalism>anarcho-syndicalism</db>, with <db id=/Individualist_anarchism>individualist anarchism</db> being primarily a literary phenomenon which nevertheless did have an impact on the bigger currents and individualists have also participated in large anarchist organizations',
                  'Etymology and terminology'])
  end

  def test_should_convert_title_to_dbpedia_uri
    assert_equal(@scrivener.title_to_dbpedia_uri("Anarchism"), "/Anarchism")
    assert_equal(@scrivener.title_to_dbpedia_uri("Politics of Angola"), "/Politics_of_Angola")
    assert_equal(@scrivener.title_to_dbpedia_uri("Apollo 8"), "/Apollo_8")
    assert_equal(@scrivener.title_to_dbpedia_uri("Gustav Kirchhoff"), "/Gustav_Kirchhoff")
    assert_equal(@scrivener.title_to_dbpedia_uri("mineral water"), "/Mineral_water")
  end

  def test_should_convert_dbpedia_uri_to_title
    assert_equal(@scrivener.dbpedia_uri_to_title("/Anarchism"), "Anarchism")
    assert_equal(@scrivener.dbpedia_uri_to_title("/Politics_of_Angola"), "Politics of Angola")
    assert_equal(@scrivener.dbpedia_uri_to_title("/Apollo_8"), "Apollo 8")
    assert_equal(@scrivener.dbpedia_uri_to_title("/Gustav_Kirchhoff"), "Gustav Kirchhoff")
    assert_equal(@scrivener.dbpedia_uri_to_title("/Mineral_water"), "Mineral water")
  end

  def test_should_isolate_ids_and_pure_text
    assert_equal(@scrivener.isolate_ids_and_pure_text(""), [""])
    assert_equal(@scrivener.isolate_ids_and_pure_text("<db id=/Anarchism>Anarchism</db>"), ["<db id=/Anarchism>Anarchism</db>"])
    assert_equal(@scrivener.isolate_ids_and_pure_text("Anarchism"), ["Anarchism"])
    assert_equal(@scrivener.isolate_ids_and_pure_text("<db id=/Anarchism>Anarchism</db> as a mass <db id=/Social_movement>social movement</db> has regularly endured fluctuations in popularity"), ["<db id=/Anarchism>Anarchism</db>", "as a mass", "<db id=/Social_movement>social movement</db>", "has regularly endured fluctuations in popularity"])
    assert_equal(@scrivener.isolate_ids_and_pure_text("       <db id=/Anarchism>Anarchism</db> as a mass <db id=/Social_movement>social movement</db> has regularly endured fluctuations in popularity        "), ["<db id=/Anarchism>Anarchism</db>", "as a mass", "<db id=/Social_movement>social movement</db>", "has regularly endured fluctuations in popularity"])
    assert_equal(@scrivener.isolate_ids_and_pure_text('Proponents of <db id=/Anarchism>anarchism</db>, known as "anarchists", advocate <db id=/Stateless_society>stateless societies</db> based on non-<db id=/Hierarchy>hierarchical</db> <db id=/Free_association_(communism_and_anarchism)>free associations</db>.'), ['Proponents of', '<db id=/Anarchism>anarchism</db>,', 'known as "anarchists", advocate', '<db id=/Stateless_society>stateless societies</db>', 'based on', 'non-<db id=/Hierarchy>hierarchical</db>', '<db id=/Free_association_(communism_and_anarchism)>free associations</db>.'])
  end

  def test_should_convert_dbpedia_relations_to_regexp
    assert_equal(@scrivener._str_dbpedia_relations_names_to_regexp(@scrivener.dbpedia_info['/Anarchism']), "Political\\ philosophy|Social\\ movement")
    assert_equal(@scrivener._str_dbpedia_relations_names_to_regexp(@scrivener.dbpedia_info['/Irving_Shulman']), "Rebel\\ without\\ a\\ case")
    assert_equal(@scrivener._str_dbpedia_relations_names_to_regexp([['/Irving_Shulman', '/the_man']]), "Irving\\ Shulman|Irving|Shulman")
  end

  def test_should_create_re_for_enrichment
    assert_equal(@scrivener.re_for_enrichment('Anarchism', @scrivener.dbpedia_info), /(Anarchism|Political\ philosophy|Social\ movement)/i)
    assert_equal(@scrivener.re_for_enrichment('Irving Shulman', @scrivener.dbpedia_info), /(Irving\ Shulman|Irving|Shulman|Rebel\ without\ a\ case)/i)
    assert_equal(@scrivener.re_for_enrichment('Whig Party (United States)', @scrivener.dbpedia_info), /(Whig\ Party\ \(United\ States\)|Whig|States\))/i)
  end

  def test_should_resolve_references_to_uri
    assert_equal(@scrivener.resolve_match_to_uri('Shulman', 'Irving Shulman', @scrivener.dbpedia_info), '/Irving_Shulman')
    assert_equal(@scrivener.resolve_match_to_uri('Irving', 'Irving Shulman', @scrivener.dbpedia_info), '/Irving_Shulman')
    assert_equal(@scrivener.resolve_match_to_uri('Social movement', 'Anarchism', @scrivener.dbpedia_info), '/Social_movement')
    assert_equal(@scrivener.resolve_match_to_uri('Social Movement', 'Anarchism', @scrivener.dbpedia_info), '/Social_movement')
  end

  def test_should_enrich_sentences_based_on_title_and_dbpedia
    assert_equal(@scrivener.enrich('<db id=/Anarchism>Anarchism</db> and anarchism as a mass social movement has regularly endured fluctuations in popularity', 'Anarchism', @scrivener.dbpedia_info),
                 '<db id=/Anarchism>Anarchism</db> and <db id=/Anarchism>anarchism</db> as a mass <db id=/Social_movement>social movement</db> has regularly endured fluctuations in popularity')

    assert_equal(@scrivener.enrich('Shulman wrote Rebel Without a Case.', 'Irving Shulman', @scrivener.dbpedia_info),
                 '<db id=/Irving_Shulman>Shulman</db> wrote <db id=/Rebel_without_a_case>Rebel Without a Case</db>.')
  end

  # pattern: <as appear in text/ID>
  def test_should_apply_combinatorics_over_instances_on_sentences
    assert_equal(@scrivener.combinatorics_over_pairs_of_instances(@scrivener.isolate_ids_and_pure_text('<db id=/Anarchism>Anarchism</db> is often defined as a <db id=/Political_philosophy>political philosophy</db> which holds the <db id=/State_(polity)>state</db> to be undesirable, unnecessary, or harmful'), false), ['<Anarchism/Anarchism> is often defined as a <political_philosophy/Political_philosophy> which holds the state to be undesirable, unnecessary, or harmful', '<Anarchism/Anarchism> is often defined as a political philosophy which holds the <state/State_(polity)> to be undesirable, unnecessary, or harmful', 'Anarchism is often defined as a <political_philosophy/Political_philosophy> which holds the <state/State_(polity)> to be undesirable, unnecessary, or harmful'])

    assert_equal(@scrivener.combinatorics_over_pairs_of_instances(@scrivener.isolate_ids_and_pure_text('Proponents of <db id=/Anarchism>anarchism</db>, known as "anarchists", advocate <db id=/Stateless_society>stateless societies</db> based on non-<db id=/Hierarchy>hierarchical</db> <db id=/Free_association_(communism_and_anarchism)>free associations</db>'), false), ['Proponents of <anarchism/Anarchism>, known as "anarchists", advocate <stateless_societies/Stateless_society> based on non-hierarchical free associations', 'Proponents of <anarchism/Anarchism>, known as "anarchists", advocate stateless societies based on non-<hierarchical/Hierarchy> free associations', 'Proponents of <anarchism/Anarchism>, known as "anarchists", advocate stateless societies based on non-hierarchical <free_associations/Free_association_(communism_and_anarchism)>', 'Proponents of anarchism, known as "anarchists", advocate <stateless_societies/Stateless_society> based on non-<hierarchical/Hierarchy> free associations', 'Proponents of anarchism, known as "anarchists", advocate <stateless_societies/Stateless_society> based on non-hierarchical <free_associations/Free_association_(communism_and_anarchism)>', 'Proponents of anarchism, known as "anarchists", advocate stateless societies based on non-<hierarchical/Hierarchy> <free_associations/Free_association_(communism_and_anarchism)>'] )
  end

  def test_should_include_only_sentences_with_relations_between_instances
    assert_equal(@scrivener.judge_sentence('/Anarchism', '/Political_philosophy'), '/philosophy')
    assert_equal(@scrivener.judge_sentence('/Anarchism', '/State_(polity)'), false)
    assert_equal(@scrivener.judge_sentence('/Anarchism', '/Social_movement'), '/partOf')
  end

  # here insert heuristics from DBpedia relations from Anarchism and already define relations
  def test_extract_useful_sentences
    assert_equal(@scrivener.extract_sentences,
                 [['<Anarchism/Anarchism> is often defined as a <political_philosophy/Political_philosophy> which holds the state to be undesirable, unnecessary, or harmful', '/philosophy'],
                  ['<Anarchism/Anarchism> as a mass <social_movement/Social_movement> has regularly endured fluctuations in popularity', '/partOf'],
                  ["The central tendency of <anarchism/Anarchism> as a <social_movement/Social_movement> has been represented by anarcho-communism and anarcho-syndicalism, with individualist anarchism being primarily a literary phenomenon which nevertheless did have an impact on the bigger currents and individualists have also participated in large anarchist organizations", '/partOf']])
  end
end
