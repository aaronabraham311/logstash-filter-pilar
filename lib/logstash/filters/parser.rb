# frozen_string_literal: true

require 'digest'
require 'logstash/filters/gramdict'

# Define a Parser class for processing tokens and generating templates.
class Parser
  def initialize(tokens_list, gramdict, threshold)
    @tokens_list = tokens_list
    @gramdict = gramdict
    @threshold = threshold
  end

  def is_dynamic(tokens, dynamic_indices, index)
    frequency = if index.zero?
                  1
                else
                  calculate_frequency(tokens, dynamic_indices, index)
                end
    frequency <= @threshold
  end

  def calculate_frequency(tokens, dynamic_indices, index)
    if index == 1
      calculate_bigram_frequency(tokens, index)
    elsif dynamic_indices.include?(index - 2)
      calculate_bigram_frequency(tokens,
                                 index)
    else
      calculate_trigram_frequency(tokens,
                                  index)
    end
  end

  def calculate_bigram_frequency(tokens, index)
    singlegram = tokens[index - 1]
    doublegram = "#{singlegram}^#{tokens[index]}"

    if @gramdict.double_gram_dict.include?(doublegram) && @gramdict.single_gram_dict.include?(singlegram)
      @gramdict.double_gram_dict[doublegram].to_f / @gramdict.single_gram_dict[singlegram]
    else
      0
    end
  end

  def calculate_trigram_frequency(tokens, index)
    doublegram = "#{tokens[index - 2]}^#{tokens[index - 1]}"
    trigram = "#{doublegram}^#{tokens[index]}"

    if @gramdict.tri_gram_dict.include?(trigram) && @gramdict.double_gram_dict.include?(doublegram)
      @gramdict.tri_gram_dict[trigram].to_f / @gramdict.double_gram_dict[doublegram]
    else
      0
    end
  end

  def gram_checker(tokens)
    dynamic_indices = []
    if tokens.length >= 2
      index = 1
      while index < tokens.length
        dynamic_indices << index if is_dynamic(tokens, dynamic_indices, index) # Directly calling is_dynamic
        index += 1
      end
    end
    dynamic_indices
  end

  def template_generator(tokens, dynamic_indices)
    template = String.new('')
    tokens.each_with_index do |token, index|
      # this looks wack but rubocop made me do it
      template << if dynamic_indices.include?(index)
                    '<*> '
                  else
                    "#{token} "
                  end
    end
    template
  end

  # TODO: WE ARE NOW OUTPUTTING SOMETHING DIFFERENT AND THE INPUTS OF THE FUNCTION ARE DIFFERENT
  # THIS NOW MAPS BETTER TO STREAMING FOR NOW
  def parse
    template_dict = {}

    event_string = String.new("EventId,EventTemplate\n")
    template_string = String.new("EventTemplate,Occurrences\n")

    @tokens_list.each do |tokens|
      dynamic_indices = gram_checker(tokens)
      template = template_generator(tokens, dynamic_indices)

      # Remove specific characters from the template
      template.gsub!(/[,'"]/, '') # TODO: SANITY CHECK IF THIS IS EQUIVALENT TO THE OLD REGEX, P SURE IT IS

      id = Digest::MD5.hexdigest(template)[0...4]

      event_string << "e#{id},#{template}\n"

      template_dict[template] = template_dict.fetch(template, 0) + 1
    end

    template_dict.each do |tmp, count|
      template_string << "#{tmp},#{count}\n"
    end
    [event_string, template_string]
  end
end
