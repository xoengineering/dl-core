require 'http'

module DL
  module Core
    # Polite HTTP: a User-Agent naming the calling gem, a minimum interval between
    # requests, timeouts, retries on 429/503, and HTTPError on other failures.
    class Client
      DEFAULT_RATE_LIMIT = 3
      TIMEOUTS           = { connect: 10, read: 60, write: 10 }.freeze # seconds, per operation
      MAX_RETRIES        = 3
      RETRY_BACKOFF      = 10 # seconds before the first retry. doubles on each retry.
      RETRYABLE_STATUSES = [429, 503].freeze

      attr_reader :rate_limit, :user_agent

      # user_agent names the calling gem, e.g. "jstor-dl/0.1.0 (+https://github.com/xoengineering/jstor-dl)"
      def initialize user_agent:, log: nil, rate_limit: DEFAULT_RATE_LIMIT
        @log        = log
        @rate_limit = rate_limit
        @user_agent = user_agent
      end

      def get url
        retries = 0

        loop do
          response = request url
          return response if response.status.success?
          raise http_error(url, response) unless retryable? response, retries

          retries += 1
          wait_before_retry response, retries
        end
      end

      private

      def request url
        throttle
        response = HTTP.timeout(TIMEOUTS).headers('User-Agent' => user_agent).follow.get(url)
        @last_request_at = Time.now
        log_request url, response
        response
      end

      def http_error url, response
        HTTPError.new status: response.status.code, url: url, reason: response.status.reason
      end

      def retryable? response, retries
        RETRYABLE_STATUSES.include?(response.status.code) && retries < MAX_RETRIES
      end

      def wait_before_retry response, retries
        seconds = retry_after(response) || (RETRY_BACKOFF * (2**(retries - 1)))
        @log&.puts "==> #{response.status}. Retrying in #{seconds}s"
        sleep seconds
      end

      # Retry-After in delay-seconds form. The HTTP-date form falls back to backoff.
      def retry_after response
        value = response.headers['Retry-After']
        return if value.nil?

        Integer(value, exception: false)
      end

      def log_request url, response
        return if @log.nil?

        @log.puts "==> GET #{url} (#{response.body.to_s.bytesize} bytes)"
      end

      def throttle
        return if @rate_limit.zero?
        return if @last_request_at.nil?

        elapsed = Time.now - @last_request_at
        return if elapsed >= @rate_limit

        sleep(@rate_limit - elapsed)
      end
    end
  end
end
