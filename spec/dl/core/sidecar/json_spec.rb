require 'date'
require 'json'
require 'tmpdir'

RSpec.describe DL::Core::Sidecar::JSON do
  let(:metadata_class) { Data.define :id, :published, :authors, :category }
  let(:metadata) do
    metadata_class.new(
      id:        '4385670',
      published: Date.new(1907, 10, 5),
      authors:   [DL::Core::Author.new(name: 'Ella Catherine Greene')],
      category:  { id: 'clasweek', name: 'The Classical Weekly' }
    )
  end

  describe '#write' do
    it 'writes pretty-printed metadata.json with string keys and ISO 8601 dates' do
      Dir.mktmpdir do |dir|
        described_class.new(metadata).write to: dir

        text   = File.read File.join(dir, 'metadata.json')
        loaded = JSON.parse text
        expect(text).to include %(\n  "id": "4385670")
        expect(text).to end_with "}\n"
        expect(loaded.fetch('published')).to eq '1907-10-05'
        expect(loaded.fetch('authors')).to   eq [{ 'name' => 'Ella Catherine Greene', 'affiliations' => [] }]
        expect(loaded.fetch('category')).to  eq('id' => 'clasweek', 'name' => 'The Classical Weekly')
      end
    end
  end
end
