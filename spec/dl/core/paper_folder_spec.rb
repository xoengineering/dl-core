require 'tmpdir'

RSpec.describe DL::Core::PaperFolder do
  let(:metadata_class) { Data.define :id, :version, :title }

  # writes a real metadata.yaml recording `version`, the marker of a flat archive
  def archive_flat version, into:
    metadata = metadata_class.new(id: 'hal-01207234', version:, title: 'Constructive solution')
    DL::Core::Sidecar::YAML.new(metadata).write to: into
  end

  describe '#archived?' do
    it 'is false for a missing folder' do
      Dir.mktmpdir do |root|
        expect(described_class.new(File.join(root, 'paper')).archived?(1)).to be false
      end
    end

    it 'is true for the version held flat' do
      Dir.mktmpdir do |root|
        archive_flat 1, into: root

        expect(described_class.new(root).archived?(1)).to be true
        expect(described_class.new(root).archived?(2)).to be false
      end
    end

    it 'is true for a version with its own v<N>/ folder' do
      Dir.mktmpdir do |root|
        FileUtils.mkdir_p File.join(root, 'v2')

        expect(described_class.new(root).archived?(2)).to be true
        expect(described_class.new(root).archived?(1)).to be false
      end
    end
  end

  describe '#location_of' do
    it 'is the folder itself for the version held flat' do
      Dir.mktmpdir do |root|
        archive_flat 1, into: root

        expect(described_class.new(root).location_of(1)).to eq root
      end
    end

    it 'is v<N>/ otherwise' do
      Dir.mktmpdir do |root|
        expect(described_class.new(root).location_of(2)).to eq File.join(root, 'v2')
      end
    end
  end

  describe '#destination_for' do
    it 'is the folder itself for v1 of a new paper' do
      Dir.mktmpdir do |root|
        path = File.join root, 'paper'

        expect(described_class.new(path).destination_for(1)).to eq path
      end
    end

    it 'is v<N>/ for a later version of a new paper' do
      Dir.mktmpdir do |root|
        path = File.join root, 'paper'

        expect(described_class.new(path).destination_for(2)).to eq File.join(path, 'v2')
      end
    end

    it 'is v1/ when other versions already have folders' do
      Dir.mktmpdir do |root|
        FileUtils.mkdir_p File.join(root, 'v2')

        expect(described_class.new(root).destination_for(1)).to eq File.join(root, 'v1')
      end
    end

    it 'is v1/ when an interrupted later version left a .partial folder' do
      Dir.mktmpdir do |root|
        FileUtils.mkdir_p File.join(root, 'v2.partial')

        expect(described_class.new(root).destination_for(1)).to eq File.join(root, 'v1')
      end
    end
  end

  describe '#unflatten!' do
    it 'moves the flat version into v<N>/' do
      Dir.mktmpdir do |root|
        archive_flat 1, into: root
        File.write File.join(root, 'hal-01207234v1.pdf'), 'pdf'

        described_class.new(root).unflatten!

        expect(File).to     exist File.join(root, 'v1', 'hal-01207234v1.pdf')
        expect(File).to     exist File.join(root, 'v1', 'metadata.yaml')
        expect(File).not_to exist File.join(root, 'metadata.yaml')
        expect(described_class.new(root).location_of(1)).to eq File.join(root, 'v1')
      end
    end

    it 'does nothing when the folder is not flat' do
      Dir.mktmpdir do |root|
        FileUtils.mkdir_p File.join(root, 'v2')

        described_class.new(root).unflatten!

        expect(Dir.children(root)).to eq ['v2']
      end
    end

    it 'calls moved_into with the v<N>/ folder, so a gem can fix up what it moved' do
      Dir.mktmpdir do |root|
        archive_flat 1, into: root
        folder = described_class.new root
        allow(folder).to receive(:moved_into)

        folder.unflatten!

        expect(folder).to have_received(:moved_into).with(File.join(root, 'v1'))
      end
    end
  end
end
