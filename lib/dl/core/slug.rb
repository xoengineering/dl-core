require 'stringex'

module DL
  module Core
    class Slug
      MAX_LENGTH = 80

      TEX_INLINE_MATH  = /\$[^$]*\$/                # $...$
      TEX_DISPLAY_MATH = /\\\(.*?\\\)|\\\[.*?\\\]/m # \(...\) or \[...\]
      TEX_COMMAND      = /\\[a-zA-Z]+\*?/           # \emph, \alpha, etc.

      def initialize title
        @title = title
      end

      def to_s
        truncate strip_tex(@title).to_url
      end

      private

      def strip_tex string
        string
          .gsub(TEX_INLINE_MATH, ' ')
          .gsub(TEX_DISPLAY_MATH, ' ')
          .gsub(TEX_COMMAND, ' ')
      end

      def truncate slug
        return slug if slug.length <= MAX_LENGTH

        words = slug.split '-'
        result = +''
        words.each do |word|
          break if result.length + 1 + word.length > MAX_LENGTH

          result << '-' unless result.empty?
          result << word
        end
        result
      end
    end
  end
end
