module DL
  module Core
    Author = Data.define :name, :affiliations do
      def initialize name:, affiliations: []
        super
      end

      def to_s = name
    end
  end
end
