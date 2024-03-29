# frozen_string_literal: true

require 'logstash/filters/base'
require 'logstash/filters/gramdict'
require 'logstash/filters/preprocessor'

module LogStash
  module Filters
    # Parses log events using PILAR
    class Pilar < LogStash::Filters::Base
      config_name 'pilar'

      # Optional configuration: Specify the field name that contains the message to be used.
      # If this is not set, the filter will use the value of the "message" field by default.
      config :source_field, validate: :string, default: 'message'

      # To improve accuracy of the parsing plugin, users will have the option of sending pre-existing logs
      # which the parser will use to seed data structures. This seeding process will greatly improve accuracy
      # of subsequent log parsing
      config :seed_logs_path, validate: :path, required: false

      # The parsing algorithm requires a numeric probabilistic threshold to determine whether a
      # particular parsed token is a dynamic token (i.e. changes extremely frequently) or if it is static.
      # If the probability that the token is a dynamic token is above this threshold, the token is considered
      # dynamic. The default threshold is set at 0.5. Since this is a probability threshold, the config value
      # must be between 0 and 1.
      config :dynamic_token_threshold, validate: :number, required: false, default: 0.5

      # The standard log format for the application must be included in this plugin's configuration in the format
      # of "<log_part_1_placeholder> <log_part_2_placeholder> ...". For example, if logs are usually of the form
      # "02012024 1706542368 Random log", then the log format would be "<date> <time> <message>".
      # If no log format is included, we will use the default of "<date> <time> <message>"
      config :logformat, validate: :string, required: false, default: '<date> <time> <message>'

      # The content_specifier variable is the placeholder value in the `logformat` variable which the parser should use
      # to identify the actual log message. For example, if `logformat = '<date> <time> <message>'`, then the
      # content_specifier should be 'message' since this is the part of the log that the parser should parse. The
      # default will be 'message', matching the default format in the `logformat` variable
      config :content_specifier, validate: :string, required: false, default: 'message'

      # The regex is an array of strings that will be converted to regexes that the user can input in order to supply
      # the parser with prelimiary information about what is a a dynamic component of the log. For example, if the
      # user wants to demark that IP addresses are known dynamic tokens, then the user can pass in passes in
      # ['(\d+\.){3}\d+'] for IP addresses to be extracted before parsing begins.
      config :regexes, validate: :string, list: true, required: false, default: []

      # This determines the maximum size of the single, double, and triple gram dictionaries respectively.
      # Upon any of those hash maps reaching their maximum size, a LRU evicition policy is used to remove items.
      # This controls the upper limit of the memory usage of this filter.
      config :maximum_gram_dict_size, validate: :number, required: false, default: 10_000

      def register
        @linenumber = 1
        @regexes = regexes.map { |regex| Regexp.new(regex) }

        # Check if dynamic_token_threshold is between 0 and 1
        return unless @dynamic_token_threshold < 0.0 || @dynamic_token_threshold > 1.0

        raise LogStash::ConfigurationError, 'dynamic_token_threshold must be between 0 and 1'
      end

      def filter(event)
        # Initialize gramdict and preprocessor for this thread if not already done
        unless Thread.current[:gramdict] && Thread.current[:preprocessor]
          Thread.current[:gramdict] = GramDict.new(@maximum_gram_dict_size)
          Thread.current[:preprocessor] =
            Preprocessor.new(Thread.current[:gramdict], @logformat, @content_specifier, @regexes)

          # Populate gramdict with seed logs
          if @seed_logs_path && ::File.exist?(@seed_logs_path)
            ::File.open(@seed_logs_path, 'r') do |seed_logs|
              seed_logs.each_line do |seed_log|
                Thread.current[:preprocessor].process_log_event(seed_log, @dynamic_token_threshold, false)
              end
            end
          end
        end

        # Use the message from the specified source field
        if event.get(@source_field)

          processed_log = Thread.current[:preprocessor].process_log_event(
            event.get(@source_field), @dynamic_token_threshold, true
          )

          if processed_log
            template_string, dynamic_tokens = processed_log

            # Set the new values in the returned event
            event.set('template_string', template_string)
            event.set('dynamic_tokens', dynamic_tokens)
          else
            event.set('dynamic_tokens', nil)
            event.set('template_string', nil)
          end

          # include the raw log message
          raw_log = event.get(@source_field)
          event.set('raw_log', raw_log.strip)
        end

        # Emit event
        filter_matched(event)
      end
    end
  end
end
