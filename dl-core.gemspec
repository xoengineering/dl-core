require_relative 'lib/dl/core/version'

Gem::Specification.new do |spec|
  spec.name    = 'dl-core'
  spec.version = DL::Core::VERSION
  spec.authors = ['Shane Becker']
  spec.email   = ['veganstraightedge@gmail.com']

  spec.summary     = 'Shared foundation for the <site>-dl offline-archive gems (arxiv-dl, jstor-dl, and more).'
  spec.description = <<~DESCRIPTION
    Polite rate-limited HTTP client with retries and timeouts, sidecar metadata writers,
    title slugs, and a shared CLI for the <site>-dl family of gems that build offline archives.
  DESCRIPTION
  spec.homepage = 'https://github.com/xoengineering/dl-core'

  spec.license = 'MIT'
  spec.required_ruby_version = '>= 4.0.7'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/xoengineering/dl-core'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/xoengineering/dl-core/issues'
  spec.metadata['changelog_uri']     = 'https://github.com/xoengineering/dl-core/blob/main/CHANGELOG.md'

  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(
        *%w[
          .github/
          .gitignore
          .rspec
          .rubocop.yml
          .ruby-version
          Gemfile
          Rakefile
          bin/
          script/
          spec/
          tasks/
        ]
      )
    end
  end
  spec.require_paths = ['lib']
end
