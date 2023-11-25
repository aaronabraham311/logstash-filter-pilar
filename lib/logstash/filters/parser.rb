# frozen_string_literal: true

require 'digest'

# Define a Parser class for processing tokens and generating templates.
class Parser
  def initialize(tokens_list, single_dict, double_dict, tri_dict, threshold)
    @tokens_list = tokens_list
    @single_dict = single_dict
    @double_dict = double_dict
    @tri_dict = tri_dict
    @threshold = threshold

    @entropy_dict = {}
  end

  def is_dynamic(tokens, dynamic_index, index); end

  def gram_checker(tokens)
    dynamic_index = []
    if tokens.length >= 2
      index = 1
      while index < tokens.length
        dynamic_index << index if is_dynamic(tokens, dynamic_index, index) # Directly calling is_dynamic
        index += 1
      end
    end
    dynamic_index
  end

  def template_generator(tokens, dynamic_index)
    template = ''
    tokens.each_with_index do |_token, index|
      # this looks wack but rubocop made me do it
      template << if dynamic_index.include?(index)
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

    event_string = "EventId,EventTemplate\n"
    template_string = "EventTemplate,Occurrences\n"

    @tokens_list.each do |tokens|
      dynamic_index = gram_checker(tokens)
      template = template_generator(tokens, dynamic_index)

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

  def template_generator_test(tokens, dynamic_index)
    dynamic_value = 0
    static_value = 0

    tokens.each_with_index do |_token, index|
      if dynamic_index.include?(index)
        dynamic_value += 1
      else
        static_value += 1
      end
    end

    [dynamic_value, static_value]
  end

  def parse_test
    dynamic_list = []
    static_list = []
    @tokens_list.each do |tokens|
      dynamic_index = gram_checker(tokens)
      dynamic_value, static_value = template_generator_test(tokens, dynamic_index)
      dynamic_list << dynamic_value
      static_list << static_value
    end

    [dynamic_list, static_list]
  end
end
