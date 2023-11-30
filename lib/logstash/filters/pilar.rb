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

      def register
        @gramdict = GramDict.new
        @preprocessor = Preprocessor.new(@gramdict, '<date> <time> <message>', 'message')
      end

      def filter(event)
        # Use the message from the specified source field
        if event.get(@source_field)
          processed_log = @preprocessor.process_log_event(event.get(@source_field))

          if processed_log
            event_string, template_string = processed_log

            # Set the new values in the returned event
            event.set('event_string', event_string)
            event.set('template_string', template_string)
          else
            event.set('event_string', nil)
            event.set('template_string', nil)
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
