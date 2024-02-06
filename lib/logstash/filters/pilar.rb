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
      config :seed_logs_path, validate: :path, required: false
      config :logformat, validate: :string, default: '<Date> <Time> <Content>'
      config :content_specifier, validate: :string, default: 'Content'
      config :threshold, validate: :number, default: 0.5

      def register
        @linenumber = 1
        @gramdict = GramDict.new
        @preprocessor = Preprocessor.new(@gramdict, logformat, content_specifier)

        if threshold > 1 || threshold < 0
          raise LogStash::ConfigurationError, "Threshold value #{threshold} is invalid. It must be between 0 and 1."
        end

        # populate gramdict with seed logs
        return unless @seed_logs_path

        ::File.open(@seed_logs_path, 'r') do |seed_logs|
          seed_logs.each_line do |seed_log|
            # TODO: Here, we are parsing every seed log file when we don't need to,
            # might need to separate these steps out
            @preprocessor.process_log_event(seed_log, 0.0, false)
          end
        end
      end

      def filter(event)
        # Use the message from the specified source field
        if event.get(@source_field)
          processed_log = @preprocessor.process_log_event(event.get(@source_field), threshold, true)
          event.set('line_id',  @linenumber)
          @linenumber += 1

          if processed_log
            template_string, dynamic_tokens, template_id = processed_log

            # Set the new values in the returned event
            event.set('template_string', template_string)
            event.set('dynamic_tokens', dynamic_tokens)
            event.set('template_id', template_id)
          else
            event.set('dynamic_tokens', nil)
            event.set('template_string', nil)
            event.set('template_id', nil)
          end

          # include the raw log message
          event.set('raw_log', event.get(@source_field))
        end

        # Emit event
        filter_matched(event)
      end
    end
  end
end
