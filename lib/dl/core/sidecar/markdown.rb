require 'fileutils'

module DL
  module Core
    module Sidecar
      # metadata.md: YAML frontmatter from the metadata (plus any extras), then a
      # Markdown body that each gem writes for its own source
      class Markdown
        FILENAME = 'metadata.md'.freeze

        def initialize metadata, body:, extras: {}
          @metadata = metadata
          @body     = body
          @extras   = extras
        end

        def to_s
          "#{frontmatter}\n#{@body}"
        end

        def write to:
          FileUtils.mkdir_p to
          File.write File.join(to, FILENAME), to_s
        end

        private

        def frontmatter
          yaml = YAML.new(@metadata, extras: @extras).to_s.delete_prefix "---\n"

          "---\n#{yaml}---"
        end
      end
    end
  end
end
