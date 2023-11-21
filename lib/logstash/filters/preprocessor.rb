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
  def token_spliter(log_line)
    # Finds matches in the stripped line for the regex format
    stripped_log_line = log_line.strip
    match = stripped_log_line.match(@format)

    # If not match found, return nil
    if match.nil?
      nil
    else
      # Gets content
      content = match[@content_specifier]
      puts content

      # Mask content and return
      processed_line = mask_log_event(content)
      processed_line.strip.split
    end
  end
end
