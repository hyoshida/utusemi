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
end
