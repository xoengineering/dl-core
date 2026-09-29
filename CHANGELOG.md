## [0.2.0]

- `DL::Core::PaperFolder`, extracted from arxiv-dl and hal-dl: a paper's folder is flat while one version (v1) is archived and uses `v<N>/` folders once there are several; `unflatten!` moves a flat version into its `v<N>/` folder and calls `moved_into(destination)`, which a gem can override (arxiv-dl rewrites `html/` links there).

## [0.1.0]

First version, extracted from arxiv-dl 0.3.0 and jstor-dl 0.1.0.

- `DL::Core::Client`: rate-limited HTTP client with timeouts and retries on 429/503. The User-Agent is now an argument, so each gem names itself.
- `DL::Core::Error` (base for every gem's errors) and `DL::Core::HTTPError`.
- `DL::Core::Author` and `DL::Core::Slug`.
- `DL::Core::Sidecar::YAML`, `JSON`, and `Markdown` metadata writers for any metadata `Data` object.
- `DL::Core::CLI`: the shared command line; each gem subclasses it with its name, defaults, identifier, and archive.
