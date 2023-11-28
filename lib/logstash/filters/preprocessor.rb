# frozen_string_literal: true

# The Preprocessor class is designed for processing and masking log events.
# This class provides functionality to parse, anonymize, and sanitize log data,
# ensuring sensitive information is masked before further processing or storage.
#
# Key Features:
# - Initialization with dictionaries and regex patterns for custom preprocessing.
# - Support for custom log formats using a flexible regex generator method.
# - Ability to mask sensitive data in log events using predefined and custom regex patterns.
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
# - mask_log_event(log_event): Masks sensitive information in a given log event using both predefined and custom regex
#   patterns.
#
# Example:
#   preprocessor = Preprocessor.new(gram_dict, regexes, logformat)
#   masked_log = preprocessor.mask_log_event(log_event)
#
# This class is essential for log management systems where data privacy and security are paramount.
class Preprocessor
  def initialize(gram_dict, regexes, logformat, content_specifier)
    # gram_dict for uploading log event tokens
    @gram_dict = gram_dict

    # Regexes for further masking (log file specific)
    @regexes = regexes

    # Masking regular expressions for common patterns
    @masking_regexes = [
      /([\w-]+\.)+[\w-]+(:\d+)/, # URL pattern
      %r{/?([0-9]+\.){3}[0-9]+(:[0-9]+)?(:)?}, # IP address pattern
      /(?<=[^A-Za-z0-9])(-?\+?\d+)(?=[^A-Za-z0-9])|[0-9]+$/ # Numbers pattern
    ]

    # Regex for specific log event format
    @format = regex_generator(logformat)

    # This is the content specifier in the @format regex
    @content_specifier = content_specifier
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

  # Method: mask_log_event
  # This method processes a log event (log line) by masking sensitive information or patterns.
  # It's used to anonymize or sanitize log data.
  # The method prepends a space to the log event, then iterates over two sets of regular expression patterns
  # (@regexes and @masking_regexes), replacing any matches with the mask string "<*>".
  #
  # Parameters:
  # log_event: A string representing the log event to be masked.
  #
  # Returns:
  # The masked log event with sensitive or specific data replaced with "<*>".
  # It modifies the log event string internally and returns the updated version.
  def mask_log_event(log_event)
    # Prepend a space to the log line
    # TODO: determine why this is necessary
    log_event = " #{log_event}"

    # Iterate over the provided regex patterns and replace matches with "<*>"
    @regexes.each do |regex|
      log_event = log_event.gsub(regex, '<*>')
    end

    # Apply the general regex patterns
    @masking_regexes.each do |regex|
      log_event = log_event.gsub(regex, '<*>')
    end

    # Return the processed log line
    log_event
  end

  # Splits a log line into tokens based on a given format and regular expression.
  #
  # @param log_line [String] the log line to be processed
  # @return [Array, nil] an array of tokens if matches are found, otherwise nil
  def token_splitter(log_line)
    # Finds matches in the stripped line for the regex format
    stripped_log_line = log_line.strip
    match = stripped_log_line.match(@format)

    # If not match found, return nil
    if match.nil?
      nil
    else
      # Gets content
      content = match[@content_specifier]

      # Mask content and return
      processed_line = mask_log_event(content)
      processed_line.strip.split
    end
  end

  # Processes an array of tokens to upload single grams, digrams, and trigrams to the @gram_dict.
  #
  # This method iterates through each token in the array. For each token, it uploads the token as a single gram.
  # Additionally, if the current token is not the first in the array, it creates and uploads a digram using the current
  # and previous token.
  # If the token is at least the third in the array, the method also creates and uploads a trigram using the current
  # token and the two preceding it.
  # The tokens in digrams and trigrams are separated by a defined separator (`token_seperator`).
  #
  # @param tokens [Array<String>] an array of string tokens to be processed
  # @return [void] this method does not return a value but updates the @gram_dict object.
  def upload_grams_to_gram_dict(tokens)
    token_seperator = '^'

    # Iterate across all tokens
    tokens.each_with_index do |token, index|
      # Upload single gram
      @gram_dict.single_gram_upload(token)

      # If possible, upload a digram
      if index.positive?
        first_token = tokens[index - 1]
        digram = first_token + token_seperator + token
        @gram_dict.double_gram_upload(digram)
      end

      # If possible, upload a trigram
      next unless index > 1

      first_token = tokens[index - 2]
      second_token = tokens[index - 1]
      trigram = first_token + token_seperator + second_token + token_seperator + token
      @gram_dict.tri_gram_upload(trigram)
    end
  end

  # Processes a given log event by tokenizing it and updating the gram dictionary.
  #
  # This method first calls the `token_splitter` method to split the log event into tokens based on the
  # pre-configured format.
  # The tokens are then passed to the `upload_grams_to_gram_dict` method, which iteratively uploads single grams,
  # digrams, and trigrams to the `@gram_dict`.
  #
  # The process involves two primary steps: tokenization and dictionary updating.
  # Tokenization is done based on the log format and involves masking sensitive information before splitting.
  # Each token, digram, and trigram found in the log event is then uploaded to the gram dictionary, enhancing the
  # dictionary's ability to process future log events.
  #
  # @param log_event [String] the log event to be processed
  # @return [void] this method does not return a value but updates the @gram_dict object by adding new entries
  #  based on the tokens extracted from the log event.
  def process_log_event(log_event)
    # Split log event into tokens
    tokens = token_splitter(log_event)

    # Upload tokens to gram dictionary if exists
    if tokens != nil
      upload_grams_to_gram_dict(tokens)
    end
  end
end
