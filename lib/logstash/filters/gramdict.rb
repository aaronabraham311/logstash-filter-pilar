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
  def initialize(separator, logformat, regex, ratio)
    @four_gram_dict = {}
    @tri_gram_dict = {}
    @double_gram_dict = {}
    @single_gram_dict = {}

    @separator = separator
    @logformat = logformat
    @regex = regex
    @ratio = ratio

    @format = regex_generator(logformat)
  end

  # Method: regex_generator
  # This method generates a regular expression based on a specified log format.
  # It is designed to parse log files where the format of the logs is known and can be described using placeholders.
  #
  # Parameters:
  # logformat: A string representing the log format. Placeholders for the data fields are enclosed in angle brackets (< >).
  #
  # Returns:
  # A Regexp object that can be used to match and extract data from log lines that follow the specified format.
  def regex_generator(logformat)
    # Split the logformat string into an array of strings and placeholders.
    # Placeholders are identified as text within angle brackets (< >).
    splitters = logformat.split(/(<[^<>]+>)/)

    # Initialize an empty string to build the regex pattern.
    format = ''

    # Iterate through the array of strings and placeholders.
    splitters.each_with_index do |splitter, k|
      if k.even?
        # For the actual string parts (even-indexed elements),
        # substitute spaces with the regex pattern for whitespace (\s+).
        format += splitter.gsub(/\s+/, '\s+')
      else
        # For placeholders (odd-indexed elements),
        # remove angle brackets and create named capture groups.
        # This transforms each placeholder into a regex pattern that matches any characters.
        header = splitter.gsub(/[<>]/, '')
        format += "(?<#{header}>.*?)"
      end
    end

    # Compile the complete regex pattern, anchored at the start and end,
    # to ensure it matches an entire line of the log file.
    Regexp.new("^#{format}$")
  end
end
