# frozen_string_literal: true

require 'logstash/filters/parser'

# The Preprocessor class is designed for processing and masking log events.
# This class provides functionality to parse, anonymize, and sanitize log data,
# ensuring sensitive information is masked before further processing or storage.
#
# Key Features:
# - Initialization with dictionaries and regex patterns for custom preprocessing.
# - Support for custom log formats using a flexible regex generator method.
#
# Usage:
# The class is initialized with a gram dictionary for tokenizing log events, a set of regexes
# for custom masking tailored to specific log files, and a log format for parsing log events.
# Once initialized, it can generate regex patterns based on the provided log format and mask
# sensitive information in log events, replacing it with a generic mask string.
#
# Methods:
# - initialize(gram_dict, regexes, logformat): Sets up the preprocessing environment with the necessary dictionaries
#   and formats.
# - regex_generator(logformat): Generates a regular expression based on a specified log format, useful for parsing logs
#   with known structures.
# - token_splitter(log_line): splits a log line into tokens
# - upload_grams_to_gram_dict(tokens): uploads a list of tokens into the single_gram, bi_gram and tri_gram dictionaries
# - process_log_event(event): processes an entire log event by calling Parser.parse()
#
# Example:
#   preprocessor = Preprocessor.new(gram_dict, regexes, logformat)
#
# This class is essential for log management systems where data privacy and security are paramount.
class Preprocessor
  def initialize(gram_dict, logformat, content_specifier)
    # gram_dict for uploading log event tokens
    @gram_dict = gram_dict

    # Regex for specific log event format
    @format = regex_generator(logformat)

    # This is the content specifier in the @format regex
    @content_specifier = content_specifier

    # This is to associate logs to EventIDs for Testing Purposes
    @template_to_template_id = {}

    # Current Log Counter
    @template_to_template_id_counter = 0
  end

  # Method: regex_generator
  # This method generates a regular expression based on a specified log format.
  # It is designed to parse log files where the format of the logs is known and can be described using placeholders.
  #
  # Parameters:
  # logformat: A string representing the log format.
  #
  # Returns:
  # A Regexp object that can be used to match and extract data from log lines that follow the specified format.
  def regex_generator(logformat)
    # Split the logformat string into an array of strings and placeholders.
    # Placeholders are identified as text within angle brackets (< >).
    splitters = logformat.split(/(<[^<>]+>)/)

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
    Regexp.new("^#{format}$")
  end

  # Splits a log line into tokens based on a given format and regular expression.
  #
  # Parameters:
  # log_line [String] the log line to be processed
  # Returns:
  # [Array, nil] an array of tokens if matches are found, otherwise nil
  def token_splitter(log_line)
    # Finds matches in the stripped line for the regex format
    stripped_log_line = log_line.strip
    match = stripped_log_line.match(@format)

    # If not match found, return nil
    if match.nil?
      nil
    else
      # Gets content and return
      content = match[@content_specifier]
      content.strip.split
    end
  end

  # Processes a given log event by tokenizing it, parsing it, and updating the gram dictionary.
  #
  # This method first calls the `token_splitter` method to split the log event into tokens based on the
  # pre-configured format.
  # The tokens are then passed to the `upload_grams` method, which iteratively uploads single grams,
  # digrams, and trigrams to the `@gram_dict`.
  #
  # The process involves two primary steps: tokenization and dictionary updating.
  # Tokenization is done based on the log format.
  # Each token, digram, and trigram found in the log event is then uploaded to the gram dictionary, enhancing the
  # dictionary's ability to process future log events.
  #
  # Parameters:
  # log_event [String] the log event to be processed
  # threshold [Float] a numeric value used to determine if a token is dynamic based on its frequency.
  #
  # Returns:
  # event_string [String], template_string[String], which are useful for log analysis and pattern recognition.
  # It also updates the gram dict based on this information.
  def process_log_event(log_event, threshold)
    # Split log event into tokens
    tokens = token_splitter(log_event)

    # If no tokens were returned, do not parse the logs and return
    return if tokens.nil?

    # Parse the log based on the pre-existing gramdict data
    parser = Parser.new(@gram_dict, threshold)
    event_string, template_string = parser.parse(tokens)

    if !@template_to_template_id.key?(template_string)
      @template_to_template_id[template_string] = @template_to_template_id_counter
      @template_to_template_id_counter += 1
    end

    template_id = @template_to_template_id[template_string]

    # Update gram_dict
    @gram_dict.upload_grams(tokens)

    [event_string, template_string, template_id]
  end

  # Processes a given seed file log event by tokenizing it and updating the gram dictionary.
  #
  # This method is the same as the process_log_event except it doesn't parse the tokens and does not output anything
  #
  # Parameters:
  # log_event [String] the log event to be processed
  #
  # Returns:
  # nil
  def process_seed_log_event(log_event, threshold)
    # Split log event into tokens
    tokens = token_splitter(log_event)

    # If no tokens were returned, do not parse the logs and return
    return if tokens.nil?

    # Update gram_dict
    @gram_dict.upload_grams(tokens)
  end
end