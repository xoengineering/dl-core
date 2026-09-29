require 'date'
require 'fileutils'
require 'json'

module DL
  module Core
    module Sidecar
      # metadata.json: every field of a metadata Data object, dates as ISO 8601 strings
      class JSON
        FILENAME = 'metadata.json'.freeze

        def initialize metadata
          @metadata = metadata
        end

        def to_s
          "#{::JSON.pretty_generate(serialize(@metadata.to_h))}\n"
        end

        def write to:
          FileUtils.mkdir_p to
          File.write File.join(to, FILENAME), to_s
        end

        private

        def serialize object
          case object
          when Hash       then object.to_h { |key, value| [key.to_s, serialize(value)] }
          when Array      then object.map { |item| serialize item }
          when Data       then serialize object.to_h
          when Date, Time then object.iso8601
          else object
          end
        end
      end
    end
  end
end
