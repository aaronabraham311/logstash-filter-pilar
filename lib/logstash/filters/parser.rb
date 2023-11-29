# frozen_string_literal: true

require 'digest'
require 'logstash/filters/gramdict'

# The Parser class is responsible for analyzing log tokens and generating templates and events.
# It identifies dynamic tokens within logs and creates standardized templates
# by replacing these dynamic tokens. The class is initialized with three parameters:
# - gramdict: An instance of the GramDict class used for n-gram frequency analysis.
# - threshold: A numeric value used to determine if a token is dynamic based on its frequency.
# If it's frequency is less than this threshold, it's dynamic.
#
# Methods:
# - is_dynamic: Determines if a token is dynamic by comparing its frequency to the set threshold.
# - calculate_frequency: Calculates frequency of a token considering its index position.
# - calculate_bigram_frequency: Determines frequency based on adjacent tokens (bigrams).
# - calculate_trigram_frequency: Calculates frequency based on trigram context.
# - find_dynamic_indices: Identifies all dynamic tokens in a log entry.
# - template_generator: Generates a log template by replacing dynamic tokens.
# - parse: Processes each token list to generate event strings and templates.
class Parser
  def initialize(gramdict, threshold)
    @gramdict = gramdict
    @threshold = threshold
  end

  # Method: is_dynamic
  # This method evaluates if a given token in a log is dynamic by assessing its frequency relative to a set threshold.
  # A token is deemed dynamic if its frequency is equal to or lower than the threshold value.
  #
  # Parameters:
  # - tokens: An array of tokens from a log entry.
  # - dynamic_indices: An array containing indices of previously identified dynamic tokens.
  # - index: The index of the current token being evaluated.
  #
  # Returns:
  # A boolean indicating whether the token is dynamic (true) or static (false).
  def is_dynamic(tokens, dynamic_indices, index)
    frequency = calculate_frequency(tokens, dynamic_indices, index)
    frequency <= @threshold
  end

  # Method: calculate_frequency
  # This method determines the frequency of a token within a log entry, considering the context provided by adjacent
  # tokens.
  # It switches between bigram and trigram frequency calculations based on the token's position and the dynamic status
  # of preceding tokens.
  #
  # The method returns 1 for the first token (index 0), giving it maximum frequency as its assuming no previous context.
  # For the second token (index 1), it calculates the bigram frequency. For a token where the token two indices before
  # is dynamic, a bigram is also used as trigram frequency calculation does not make sense on a dynamic token.
  # In all other cases, it calculates the trigram frequency.
  #
  # Parameters:
  # - tokens: An array of tokens from the log entry.
  # - dynamic_indices: An array of indices for previously identified dynamic tokens.
  # - index: The index of the current token for which the frequency is calculated.
  #
  # Returns:
  # The calculated frequency of the token as a float, based on bigram or trigram analysis.
  def calculate_frequency(tokens, dynamic_indices, index)
    if index.zero?
      1
    elsif index == 1 || dynamic_indices.include?(index - 2)
      calculate_bigram_frequency(tokens, index)
    else
      calculate_trigram_frequency(tokens, index)
    end
  end

  # Method: calculate_bigram_frequency
  # This method calculates the frequency of a token within the context of a bigram (pair of adjacent tokens).
  # It forms a bigram with the token and its preceding token, then checks their frequency in the GramDict instance.
  # The frequency is determined as the ratio of the bigram frequency to the frequency of the preceding single token.
  #
  # Parameters:
  # tokens: An array of tokens representing the log entry.
  # index: The current index of the token for which the bigram frequency is being calculated.
  #
  # Returns:
  # The frequency of the bigram as a float. If the bigram or singlegram is not found in the dictionaries,
  # it returns 0, indicating a lack of previous occurrences.
  def calculate_bigram_frequency(tokens, index)
    singlegram = tokens[index - 1]
    doublegram = "#{singlegram}^#{tokens[index]}"

    if @gramdict.double_gram_dict.include?(doublegram) && @gramdict.single_gram_dict.include?(singlegram)
      @gramdict.double_gram_dict[doublegram].to_f / @gramdict.single_gram_dict[singlegram]
    else
      0
    end
  end

  # Method: calculate_trigram_frequency
  # This method calculates the frequency of a token within the context of a trigram (sequence of three adjacent tokens).
  # It forms a trigram with the token and its two preceding tokens and also considers the intermediate bigram.
  # The frequency is determined as the ratio of the trigram frequency to the frequency of the preceding bigram.
  #
  # Parameters:
  # tokens: An array of tokens representing the log entry.
  # index: The current index of the token for which the trigram frequency is being calculated.
  #
  # Returns:
  # The frequency of the trigram as a float. If the trigram or the intermediate bigram is not found in the dictionaries,
  # it returns 0, suggesting a unique or rare occurrence in the logs.
  def calculate_trigram_frequency(tokens, index)
    doublegram = "#{tokens[index - 2]}^#{tokens[index - 1]}"
    trigram = "#{doublegram}^#{tokens[index]}"

    if @gramdict.tri_gram_dict.include?(trigram) && @gramdict.double_gram_dict.include?(doublegram)
      @gramdict.tri_gram_dict[trigram].to_f / @gramdict.double_gram_dict[doublegram]
    else
      0
    end
  end

  # Method: gram_checker
  # This method identifies dynamic tokens in a given log entry. It iterates through the tokens
  # and uses the is_dynamic method to check if each token is dynamic. Dynamic tokens are those
  # whose frequency is less than or equal to a certain threshold, suggesting variability in log entries.
  #
  # Parameters:
  # tokens: An array of tokens representing the log entry.
  #
  # Returns:
  # An array of indices corresponding to dynamic tokens within the log entry.
  def find_dynamic_indices(tokens)
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

  # Method: template_generator
  # Generates a standardized log template from a list of tokens. This method replaces dynamic tokens
  # (identified by their indices in dynamic_indices) with a placeholder symbol '<*>'. The result is a template
  # that represents the static structure of the log entry, with dynamic parts generalized.
  #
  # Parameters:
  # tokens: An array of tokens from the log entry.
  # dynamic_indices: An array of indices indicating which tokens are dynamic.
  #
  # Returns:
  # A string representing the log template, with dynamic tokens replaced by '<*>'.
  def template_generator(tokens, dynamic_indices)
    template = String.new('')
    tokens.each_with_index do |token, index|
      template << if dynamic_indices.include?(index)
                    '<*> '
                  else
                    "#{token} "
                  end
    end
    template
  end

  # Method: parse
  # This method processes the log entry represented as tokens. It identifies dynamic tokens,
  # generates a log template, and then compiles two strings: event_string and template_string.
  # The event_string maps each event to its template, while template_string counts the occurrences
  # of each template. It also ensures that templates are properly formatted by removing certain characters.

  # Parameters:
  # tokens: An array of tokens from the log entry.
  # Returns:
  # An array containing the event_string and template_string, which are useful for log analysis and pattern recognition.
  def parse(log_tokens)
    dynamic_indices = find_dynamic_indices(log_tokens)
    template_string = template_generator(log_tokens, dynamic_indices)

    # TODO: The Python iteration of the parser does a few regex checks here on the templates
    # It's unclear based on prelimilarly data if we need this, but once the full plugin has been fleshed out we can
    # revisit
    template_string.gsub!(/[,'"]/, '')

    id = Digest::MD5.hexdigest(template_string)[0...4]

    event_string = "e#{id},#{template_string}\n"

    [event_string, template_string]
  end
end
