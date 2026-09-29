RSpec.describe DL::Core::Slug do
  it 'slugifies a plain title' do
    expect(described_class.new('ComicScene154: A Scene Dataset for Comic Analysis').to_s)
      .to eq 'comicscene154-a-scene-dataset-for-comic-analysis'
  end

  it 'truncates a long title to 80 chars at a word boundary' do
    title = <<~TITLE.tr("\n", ' ').strip
      A Comprehensive Analysis of Computational Narrative Methods for
      Sequential Visual Storytelling and Comic Book Scene Segmentation
      in Multimodal Datasets
    TITLE

    slug = described_class.new(title).to_s

    expect(slug.length).to be <= 80
    expect(slug).not_to    end_with '-'
    expect(slug).to        eq 'a-comprehensive-analysis-of-computational-narrative-methods-for-sequential'
  end

  it 'strips TeX inline math from titles' do
    expect(described_class.new('On the $\alpha$-Convergence of Comic Panel Layouts').to_s)
      .to eq 'on-the-convergence-of-comic-panel-layouts'
  end

  it 'strips TeX commands outside math from titles' do
    expect(described_class.new('A Note on \emph{Sequential} Comic Narratives').to_s)
      .to eq 'a-note-on-sequential-comic-narratives'
  end
end
