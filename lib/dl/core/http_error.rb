module DL
  module Core
    class HTTPError < Error
      attr_reader :status, :url

      def initialize status:, url:, reason: nil
        @status = status
        @url    = url

        super("GET #{url} failed: #{[status, reason].compact.join ' '}")
      end
    end
  end
end
