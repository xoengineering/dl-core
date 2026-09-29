module DL
  module Core
    # each gem's own Error subclasses this, so the shared CLI can report any gem's failures
    class Error < StandardError; end
  end
end
