require 'date'
require 'tmpdir'
require 'yaml'

RSpec.describe DL::Core::Sidecar::YAML do
  let(:metadata_class) { Data.define :id, :title, :published, :authors, :category }
  let(:metadata) do
    metadata_class.new(
      id:        '4385670',
      title:     'The Elements of the Translation of Latin',
      published: Date.new(1907, 10, 5),
      authors:   [DL::Core::Author.new(name: 'Ella Catherine Greene')],
      category:  { id: 'clasweek', name: 'The Classical Weekly' }
    )
  end

  describe '#write' do
    it 'writes metadata.yaml with string keys, in field order, nested Data and hashes included' do
      Dir.mktmpdir do |dir|
        described_class.new(metadata).write to: dir

        loaded = YAML.safe_load_file File.join(dir, 'metadata.yaml'), permitted_classes: [Date]
        expect(loaded.keys).to eq %w[id title published authors category]
        expect(loaded.fetch('published')).to eq Date.new(1907, 10, 5)
        expect(loaded.fetch('authors')).to   eq [{ 'name' => 'Ella Catherine Greene', 'affiliations' => [] }]
        expect(loaded.fetch('category')).to  eq('id' => 'clasweek', 'name' => 'The Classical Weekly')
      end
    end

    it 'creates the target directory' do
      Dir.mktmpdir do |dir|
        target = File.join dir, 'a', 'b'
        described_class.new(metadata).write to: target

        expect(File).to exist File.join(target, 'metadata.yaml')
      end
    end
  end
end
