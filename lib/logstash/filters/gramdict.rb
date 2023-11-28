# frozen_string_literal: true

# The GramDict class is designed for processing and analyzing log events.
# It creates dictionaries for single, double, triple, and four-word combinations
# (n-grams) found in the log data. The class is initialized with several parameters:
# - separator: Character or string used to separate log entries.
# - logformat: A string representing the format of the log entries.
# - regex: Regular expression used for pre-processing log entries.
# - ratio: A float representing the fraction of the log file to process.
#
# Methods:
# - SingleGramUpload(gram): Updates the count of a single word in the dictionary.
# - DoubleGramUpload(gram): Updates the count of a double word combination in the dictionary.
# - TriGramUpload(gram): Updates the count of a triple word combination in the dictionary.
# - FourGramUpload(gram): Updates the count of a four-word combination in the dictionary.
# - UploadGram(tokens, index): Processes a token at a specific index for all n-gram dictionaries.
# - GramBuilder(tokens): Processes an array of tokens for n-gram analysis.
# - DictionarySetUp(): Initializes the dictionaries with data from the log file.
#
# This class is useful for log file analysis, especially for identifying common patterns
# and anomalies in log entries.
class GramDict
  def initialize(separator, logformat, ratio)
    @four_gram_dict = {}
    @tri_gram_dict = {}
    @double_gram_dict = {}
    @single_gram_dict = {}

    @separator = separator
    @logformat = logformat
    @ratio = ratio
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

  # Method: four_gram_upload
  # This method manages the frequency count of four grams (sequences of four words or tokens) in a hash map.
  # It either increments the existing count or initializes it to 1 if the four gram is new.
  #
  # Parameters:
  # gram: A string that denotes the four gram to be updated in the hash map.
  #
  # Returns:
  # Nothing. The @four_gram_dict is updated accordingly.
  def four_gram_upload(gram)
    if @four_gram_dict.key?(gram)
      @four_gram_dict[gram] += 1
    else
      @four_gram_dict[gram] = 1
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
end
