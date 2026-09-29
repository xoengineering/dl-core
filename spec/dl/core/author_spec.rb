RSpec.describe DL::Core::Author do
  let(:author) do
    described_class.new name:         'Jon S. Lawrence',
                        affiliations: ['Australian Astronomical Observatory', 'Macquarie University']
  end

  it 'has a name' do
    expect(author.name).to eq 'Jon S. Lawrence'
  end

  it 'has affiliations in order' do
    expect(author.affiliations).to eq ['Australian Astronomical Observatory', 'Macquarie University']
  end

  it 'defaults affiliations to empty' do
    expect(described_class.new(name: 'Sandro Paval').affiliations).to eq []
  end

  it 'renders as its name' do
    expect(author.to_s).to eq 'Jon S. Lawrence'
  end
end
