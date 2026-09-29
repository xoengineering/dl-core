## [Unreleased]

First version, extracted from arxiv-dl 0.3.0 and jstor-dl 0.1.0.

- `DL::Core::Client`: rate-limited HTTP client with timeouts and retries on 429/503. The User-Agent is now an argument, so each gem names itself.
- `DL::Core::Error` (base for every gem's errors) and `DL::Core::HTTPError`.
- `DL::Core::Author` and `DL::Core::Slug`.
- `DL::Core::Sidecar::YAML`, `JSON`, and `Markdown` metadata writers for any metadata `Data` object.
- `DL::Core::CLI`: the shared command line; each gem subclasses it with its name, defaults, identifier, and archive.
