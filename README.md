# dl-core

Shared foundation for the `<site>-dl` gems that build offline archives: [arxiv-dl](https://github.com/xoengineering/arxiv-dl), [jstor-dl](https://github.com/xoengineering/jstor-dl), and more.

## What's in it

| Class                                  | Purpose                                                                                           |
| -------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `DL::Core::Client`                     | Polite HTTP: User-Agent naming the gem, minimum interval between requests, timeouts, retries on 429/503 (honoring `Retry-After`) |
| `DL::Core::Error`, `DL::Core::HTTPError` | Base error for every gem; `HTTPError` for non-success responses (`status`, `url`)               |
| `DL::Core::Author`                     | `name` and `affiliations`                                                                         |
| `DL::Core::Slug`                       | Title → URL-safe slug, truncated at a word boundary                                               |
| `DL::Core::PaperFolder`                | A paper's folder: flat while one version is archived, `v<N>/` folders once there are several; override `moved_into` to fix up files moved one level deeper |
| `DL::Core::Sidecar::YAML`, `JSON`      | `metadata.yaml` / `metadata.json` from any metadata `Data` object                                 |
| `DL::Core::Sidecar::Markdown`          | `metadata.md`: YAML frontmatter from the metadata, plus a body each gem writes                    |
| `DL::Core::CLI`                        | The shared command line: targets as args or `--input FILE\|-`, `-p`, `--rate-limit`, `-v`, `-q`, per-target errors, exit 1 on any failure |

## Building a `<site>-dl` gem on it

Each gem's errors subclass `DL::Core::Error`, and its CLI subclasses `DL::Core::CLI`:

```ruby
module Example
  module Downloader
    class Error < DL::Core::Error; end

    class CLI < DL::Core::CLI
      def program = 'example-dl'

      def target_name = 'EXAMPLE_ID_OR_URL'

      # EXAMPLE_DOWNLOAD_PATH, EXAMPLE_RATE_LIMIT
      def env_prefix = 'EXAMPLE'

      def default_path = File.join(Dir.home, 'Downloads', 'Example_Papers')

      def version = VERSION

      def user_agent = "example-dl/#{VERSION} (+https://github.com/xoengineering/example-dl)"

      def identifier_for(target) = Identifier.new(target)

      def archive_for(identifier, root:, client:) = Archive.new(identifier, root:, client:)
    end
  end
end
```

`identifier_for` raises a `DL::Core::Error` subclass for input the gem doesn't recognize; the object it returns responds to `id`. `archive_for` returns an object whose `run` archives the paper and returns its folder.

## Development

```sh
script/setup    # install dependencies
script/test     # run specs and rubocop
script/console  # interactive prompt
```

## License

MIT — see [LICENSE.md](LICENSE.md).

## Code of Conduct

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/version/3/0/) 3.0 — see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
