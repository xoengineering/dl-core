require_relative 'core/author'
require_relative 'core/cli'
require_relative 'core/client'
require_relative 'core/error'      # before errors below that subclass Error
require_relative 'core/http_error' # after error
require_relative 'core/paper_folder'
require_relative 'core/sidecar/json'
require_relative 'core/sidecar/markdown'
require_relative 'core/sidecar/yaml'
require_relative 'core/slug'
require_relative 'core/version'

module DL
  module Core
  end
end
