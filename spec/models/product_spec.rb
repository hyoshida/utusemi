describe Product do
  let(:product) { FactoryGirl.build(:product) }

  before do
    Utusemi.configure do
      map :sample do |options|
        name :title
        caption options[:caption] || :none
      end
    end
  end

  it { should respond_to(:utusemi) }

  # TODO: Implement the new syntax
  #
  #   map(:product) { ... }
  #   Product.utusemi.first
  #
  describe '#utusemi(type)' do
    subject { product.utusemi(:sample) }
    it { should respond_to(:title) }
    it { should respond_to(:name) }
  end

  describe '#utusemi(type, options)' do
    subject { product.utusemi(:sample, caption: :title) }
    it { expect(subject.caption).to eq(subject.title) }
  end

  describe '::utusemi(type)' do
    before { FactoryGirl.create(:product, title: 'foobar') }
    subject { described_class.utusemi(:sample) }

    it '::where by alias column' do
      expect(subject.where(name: 'foobar').count).to eq(1)
    end

    it '::order by alias column' do
      expect { subject.order(:name) }.not_to raise_error
    end

    it 'call alias column from instance' do
      expect(subject.first.name).to eq(subject.first.title)
    end
  end

  describe '::utusemi(type, options)' do
    before { FactoryGirl.create(:product, title: 'foobar') }
    subject { described_class.utusemi(:sample, caption: :title) }

    it 'call alias column from instance' do
      expect(subject.first.caption).to eq(subject.first.title)
    end
  end
end
