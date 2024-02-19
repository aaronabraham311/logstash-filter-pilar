# frozen_string_literal: true
require 'lru_redux'

# The GramDict class is designed for processing and analyzing log events.
# It creates dictionaries for single, double, triple, and four-word combinations
# (n-grams) found in the log data. The class is initialized with several parameters:
#
# Methods:
# - single_gram_upload(gram): Updates the count of a single word in the dictionary.
# - double_gram_upload(gram): Updates the count of a double word combination in the dictionary.
# - tri_gram_upload(gram): Updates the count of a triple word combination in the dictionary.
# - four_gram_upload(gram): Updates the count of a four-word combination in the dictionary.
# - Getters for each gram_dict (asides from four_gram_dict)
#
# This class is useful for log file analysis, especially for identifying common patterns
# and anomalies in log entries.
class GramDict
  def initialize(max_gram_dict_size)

    @max_gram_dict_size = max_gram_dict_size
    @tri_gram_dict = LruRedux::Cache.new(max_gram_dict_size)
    @double_gram_dict = LruRedux::Cache.new(max_gram_dict_size)
    @single_gram_dict = LruRedux::Cache.new(max_gram_dict_size)
  end

  # Method: single_gram_upload
  # This method updates the frequency count of a single gram (word or token) in a hash map.
  # It increases the count of the gram if it already exists in the hash map,
  # or initializes it to 1 if it's the first occurrence.
  #
  # Parameters:
  # gram: A string representing the single gram whose count needs to be updated.
  #
  # Returns:
  # Nothing. It updates the @single_gram_dict in place.
  def single_gram_upload(gram)
    if @single_gram_dict.key?(gram)
      @single_gram_dict[gram] += 1
    else
      @single_gram_dict[gram] = 1
    end
  end

  # Method: double_gram_upload
  # This method is used to update the frequency count of a double gram (pair of words or tokens) in a hash map.
  # It increments the count of the double gram if it exists,
  # or initializes it to 1 if it's not already present.
  #
  # Parameters:
  # gram: A string representing the double gram to be updated in the hash map.
  #
  # Returns:
  # Nothing. It updates the @double_gram_dict in place.
  def double_gram_upload(gram)
    if @double_gram_dict.key?(gram)
      @double_gram_dict[gram] += 1
    else
      @double_gram_dict[gram] = 1
    end
  end

  # Method: tri_gram_upload
  # This method updates the count of a tri gram (sequence of three words or tokens) in a hash map.
  # It increases the count if the tri gram is already present,
  # or sets it to 1 for a new tri gram.
  #
  # Parameters:
  # gram: A string representing the tri gram for frequency updating.
  #
  # Returns:
  # Nothing. It modifies the @tri_gram_dict internally.
  def tri_gram_upload(gram)
    if @tri_gram_dict.key?(gram)
      @tri_gram_dict[gram] += 1
    else
      @tri_gram_dict[gram] = 1
    end
  end

  # Method: single_gram_dict
  # This method is a getter for the single_gram_dict
  #
  # Parameters:
  # Nothing.
  #
  # Returns:
  # The @single_gram_dict member
  attr_reader :single_gram_dict

  # Method: double_gram_dict
  # This method is a getter for the double_gram_dict
  #
  # Parameters:
  # Nothing.
  #
  # Returns:
  # The @double_gram_dict member
  attr_reader :double_gram_dict

  # Method: tri_gram_dict
  # This method is a getter for the tri_gram_dict
  #
  # Parameters:
  # Nothing.
  #
  # Returns:
  # The @tri_gram_dict member
  attr_reader :tri_gram_dict

  # Processes an array of tokens to upload single grams, digrams, and trigrams to the @gram_dict.
  #
  # This method iterates through each token in the array. For each token, it uploads the token as a single gram.
  # Additionally, if the current token is not the first in the array, it creates and uploads a digram using the current
  # and previous token.
  # If the token is at least the third in the array, the method also creates and uploads a trigram using the current
  # token and the two preceding it.
  # The tokens in digrams and trigrams are separated by a defined separator (`token_seperator`).
  #
  # Parameters:
  # tokens [Array<String>] an array of string tokens to be processed
  #
  # Returns:
  # [void] this method does not return a value but updates single_gram_dict, double_gram_dict and tri_gram_dict
  def upload_grams(tokens)
    token_seperator = '^'

    # Iterate across all tokens
    tokens.each_with_index do |token, index|
      # Upload single gram
      single_gram_upload(token)

      # If possible, upload a digram
      if index.positive?
        first_token = tokens[index - 1]
        digram = first_token + token_seperator + token
        double_gram_upload(digram)
      end

      # If possible, upload a trigram
      next unless index > 1

      first_token = tokens[index - 2]
      second_token = tokens[index - 1]
      trigram = first_token + token_seperator + second_token + token_seperator + token
      tri_gram_upload(trigram)
    end
  end

  def clone
    new_gram_dict = GramDict.new(@max_gram_dict_size)
    new_gram_dict
  end
end
