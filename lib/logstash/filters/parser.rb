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

  # Helper method to update entropy dictionary
  def update_entropy_dict(f_score)
    f_str = f_score.to_s
    if @entropy_dict.include?(f_str)
      @entropy_dict[f_str] += 1
    else
      @entropy_dict[f_str] = 1
    end
  end

  def is_dynamic(tokens, dynamic_index, index)
    f = 0

    if index.zero?
      f = 1
    elsif index == 1
      singlegram = tokens[index - 1]
      doublegram = "#{tokens[index - 1]}^#{tokens[index]}"

      f = if @double_dict.include?(doublegram) && @single_dict.include?(singlegram)
            @double_dict[doublegram].to_f / @single_dict[singlegram]
          else
            0
          end

      update_entropy_dict(f)
    else
      if dynamic_index.include?(index - 2)
        singlegram = tokens[index - 1]
        doublegram = "#{tokens[index - 1]}^#{tokens[index]}"
        f = if @double_dict.include?(doublegram) && @single_dict.include?(singlegram)
              @double_dict[doublegram].to_f / @single_dict[singlegram]
            else
              0
            end
      else
        doublegram = "#{tokens[index - 2]}^#{tokens[index - 1]}"
        trigram = "#{doublegram}^#{tokens[index]}"
        f = if @tri_dict.include?(trigram) && @double_dict.include?(doublegram)
              @tri_dict[trigram].to_f / @double_dict[doublegram]
            else
              0
            end
      end
      update_entropy_dict(f)
    end
    f <= @threshold
  end

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
    template = String.new('')
    tokens.each_with_index do |token, index|
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

    event_string = String.new("EventId,EventTemplate\n")
    template_string = String.new("EventTemplate,Occurrences\n")

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
end
