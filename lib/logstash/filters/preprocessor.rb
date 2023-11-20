class Preprocessor
    def initialize(gram_dict, regexes, logformat)
        # gram_dict for uploading log event tokens
        @gram_dict = gram_dict

        # Regexes for further masking (log file specific)
        @regexes = regexes

        # Masking regular expressions for common patterns
        @masking_regexes = [
            /([\w-]+\.)+[\w-]+(:\d+)/,                # URL pattern
            /\/?([0-9]+\.){3}[0-9]+(:[0-9]+)?(:)?/,   # IP address pattern
            /(?<=[^A-Za-z0-9])(-?\+?\d+)(?=[^A-Za-z0-9])|[0-9]+$/ # Numbers pattern
        ]

        # Regex for specific log event format
        @format = regex_generator(logformat)
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
end