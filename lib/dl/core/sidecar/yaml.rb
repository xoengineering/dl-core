require 'fileutils'
require 'yaml'

module DL
  module Core
    module Sidecar
      # metadata.yaml: every field of a metadata Data object (plus any extras), in field order
      class YAML
        FILENAME = 'metadata.yaml'.freeze

        def initialize metadata, extras: {}
          @metadata = metadata
          @extras   = extras
        end

        def to_s
          ::YAML.dump stringify(@metadata.to_h.merge(@extras))
        end

        def write to:
          FileUtils.mkdir_p to
          File.write File.join(to, FILENAME), to_s
        end

        private

        def stringify object
          case object
          when Hash  then object.to_h { |key, value| [key.to_s, stringify(value)] }
          when Array then object.map { |item| stringify item }
          when Data  then stringify object.to_h
          else object
          end
        end
      end
    end
  end
end
