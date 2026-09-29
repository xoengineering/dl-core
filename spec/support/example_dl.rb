# A minimal <site>-dl gem built on DL::Core, for exercising the shared CLI.
module ExampleDL
  class Error < DL::Core::Error; end

  # numeric IDs only
  class Identifier
    class Invalid < Error; end

    attr_reader :id

    def initialize input
      @id = input.to_s.strip
      raise Invalid, "not an example ID: #{input}" unless /\A\d+\z/.match? @id
    end
  end

  # writes <root>/<id>/paper.txt; ID 404 fails the way a missing paper would
  class Archive
    def initialize identifier, root:, client:
      @identifier = identifier
      @root       = root
      @client     = client
    end

    def run
      raise DL::Core::HTTPError.new(status: 404, url: "https://example.org/#{@identifier.id}") if @identifier.id == '404'

      path = File.join @root, @identifier.id
      FileUtils.mkdir_p path
      File.write File.join(path, 'paper.txt'), "paper #{@identifier.id}"
      path
    end
  end

  class CLI < DL::Core::CLI
    def program = 'example-dl'

    def target_name = 'EXAMPLE_ID'

    def env_prefix = 'EXAMPLE'

    def default_path = File.join(Dir.home, 'Downloads', 'Example_Papers')

    def version = '1.2.3'

    def user_agent = 'example-dl/1.2.3 (+https://github.com/xoengineering/example-dl)'

    def identifier_for(target) = Identifier.new(target)

    def archive_for(identifier, root:, client:) = Archive.new(identifier, root:, client:)
  end
end
