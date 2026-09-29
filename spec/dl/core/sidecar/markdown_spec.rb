require 'date'
require 'tmpdir'
require 'yaml'

RSpec.describe DL::Core::Sidecar::Markdown do
  let(:metadata_class) { Data.define :id, :title, :published, :authors }
  let(:metadata) do
    metadata_class.new(
      id:        '4385670',
      title:     'The Elements of the Translation of Latin',
      published: Date.new(1907, 10, 5),
      authors:   [DL::Core::Author.new(name: 'Ella Catherine Greene')]
    )
  end
  let(:body) { "\n# The Elements of the Translation of Latin\n" }

  def written extras: {}
    Dir.mktmpdir do |dir|
      described_class.new(metadata, body:, extras:).write to: dir
      File.read File.join(dir, 'metadata.md')
    end
  end

  describe '#write' do
    it 'writes YAML frontmatter from the metadata, then the body' do
      _, frontmatter_text, rest = written.split(/^---\n/, 3)
      frontmatter = YAML.safe_load frontmatter_text, permitted_classes: [Date]

      expect(frontmatter.keys).to eq %w[id title published authors]
      expect(frontmatter['authors']).to eq [{ 'name' => 'Ella Catherine Greene', 'affiliations' => [] }]
      expect(rest).to eq body
    end

    it 'appends extra frontmatter fields after the metadata fields' do
      _, frontmatter_text, = written(extras: { bibtex_key: 'greene1907the' }).split(/^---\n/, 3)
      frontmatter = YAML.safe_load frontmatter_text, permitted_classes: [Date]

      expect(frontmatter.keys.last).to eq 'bibtex_key'
      expect(frontmatter['bibtex_key']).to eq 'greene1907the'
    end
  end
end
