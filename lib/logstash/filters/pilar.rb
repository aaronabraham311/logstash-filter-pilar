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

      # The regex is an array of strings that will be converted to regexes that the user can input in order to supply the 
      # parser with prelimiary information about what is a a dynamic component of the log. For example, if the user wants 
      # to demark that IP addresses are known dynamic tokens, then the user can pass in passes in ['(\d+\.){3}\d+'] for IP
      # addresses to be extracted before parsing begins.
      config :regexes, validate: :array, required: false, default: []

      def register
        @linenumber = 1
        @regexes = regexes.map { |regex| Regexp.new(regex) }
        @gramdict = GramDict.new
        @preprocessor = Preprocessor.new(@gramdict, @logformat, @content_specifier, @regexes)

        # Check if dynamic_token_threshold is between 0 and 1
        if @dynamic_token_threshold < 0.0 || @dynamic_token_threshold > 1.0
          raise LogStash::ConfigurationError, 'dynamic_token_threshold must be between 0 and 1'
        end

        # populate gramdict with seed logs
        return unless @seed_logs_path

        ::File.open(@seed_logs_path, 'r') do |seed_logs|
          seed_logs.each_line do |seed_log|
            # TODO: Here, we are parsing every seed log file when we don't need to,
            # might need to separate these steps out
            @preprocessor.process_log_event(seed_log, false)
          end
        end
      end

      def filter(event)
        # Use the message from the specified source field
        if event.get(@source_field)
          processed_log = @preprocessor.process_log_event(
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
