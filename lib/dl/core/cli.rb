require 'optparse'

module DL
  module Core
    # The shared <site>-dl command line. Each gem subclasses it and defines:
    #
    #   program                                  "jstor-dl"
    #   target_name                              "JSTOR_ID_OR_URL", for the usage line
    #   env_prefix                               "JSTOR", for JSTOR_DOWNLOAD_PATH and JSTOR_RATE_LIMIT
    #   default_path                             where downloads go without -p or the ENV var
    #   version                                  the gem's version, for --version
    #   user_agent                               for requests, naming the gem
    #   identifier_for(target)                   parses one target; raises an Error subclass if invalid
    #   archive_for(identifier, root:, client:)  an object whose #run archives it and returns its folder
    #
    # and can override default_rate_limit when its source allows fewer requests.
    class CLI
      def initialize argv, stderr: $stderr, stdin: $stdin, stdout: $stdout
        @argv   = argv
        @stderr = stderr
        @stdin  = stdin
        @stdout = stdout
      end

      def run
        options = parse
        return options.fetch(:exit_status) if options.key? :exit_status

        return error_with usage    if options[:targets].empty?
        return error_with conflict if options[:verbose] && options[:quiet]

        failures = download_each options
        failures.zero? ? 0 : 1
      end

      def program = raise(NotImplementedError, "#{self.class} must define #program")

      def target_name = raise(NotImplementedError, "#{self.class} must define #target_name")

      def env_prefix = raise(NotImplementedError, "#{self.class} must define #env_prefix")

      def default_path = raise(NotImplementedError, "#{self.class} must define #default_path")

      def version = raise(NotImplementedError, "#{self.class} must define #version")

      def user_agent = raise(NotImplementedError, "#{self.class} must define #user_agent")

      def identifier_for(_target) = raise(NotImplementedError, "#{self.class} must define #identifier_for")

      def archive_for(_identifier, root:, client:) = raise(NotImplementedError, "#{self.class} must define #archive_for")

      def client_for(rate_limit:, log:) = Client.new(user_agent:, rate_limit:, log:)

      # seconds between requests when neither --rate-limit nor <PREFIX>_RATE_LIMIT is set.
      # A gem whose source allows fewer requests overrides this.
      def default_rate_limit = Client::DEFAULT_RATE_LIMIT

      private

      def usage
        "Usage: #{program} [options] <#{target_name}> [<#{target_name}>...]"
      end

      def conflict
        '-v and -q are mutually exclusive'
      end

      def parse
        options = { targets: [], verbose: false, quiet: false }
        parser  = build_parser options

        begin
          parser.parse! @argv
          options[:targets] = @argv + input_targets(options[:input])
        rescue OptionParser::ParseError, SystemCallError => e
          @stderr.puts e.message
          return { exit_status: 1 }
        end

        options[:path]       ||= ENV["#{env_prefix}_DOWNLOAD_PATH"] || default_path
        options[:rate_limit] ||= (ENV["#{env_prefix}_RATE_LIMIT"] || default_rate_limit).to_i
        options
      end

      def build_parser options
        OptionParser.new do |parser|
          parser.banner = usage
          parser.on('-i FILE', '--input FILE')       { |value| options[:input] = value }
          parser.on('-p PATH', '--path PATH')        { |value| options[:path] = value }
          parser.on('--rate-limit SECONDS', Integer) { |value| options[:rate_limit] = value }
          parser.on('-v', '--verbose')               { options[:verbose] = true }
          parser.on('-q', '--quiet')                 { options[:quiet]   = true }
          parser.on('--version') do
            @stdout.puts version
            options[:exit_status] = 0
          end
          parser.on('-h', '--help') do
            @stdout.puts parser.help
            options[:exit_status] = 0
          end
        end
      end

      # one target per line from FILE, or stdin for "-"; blank lines and # comments skipped
      def input_targets input
        return [] if input.nil?

        text = input == '-' ? @stdin.read : File.read(input)
        text.lines.map(&:strip).reject { it.empty? || it.start_with?('#') }
      end

      def error_with message
        @stderr.puts message
        1
      end

      def download_each options
        client = client_for rate_limit: options[:rate_limit], log: (options[:verbose] ? @stdout : nil)

        failures = 0
        options[:targets].each do |target|
          failures += 1 unless download_one(target, client:, options:)
        end
        failures
      end

      # true on success; reports the failure and returns false otherwise
      def download_one target, client:, options:
        identifier = identifier_for target
        @stdout.puts "==> Downloading #{identifier.id}" if options[:verbose]

        path = archive_for(identifier, root: options[:path], client: client).run
        @stdout.puts path unless options[:quiet]
        true
      rescue Error, HTTP::Error => e
        @stderr.puts "#{target}: #{e.message}"
        false
      end
    end
  end
end
