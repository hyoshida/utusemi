describe Utusemi::Configuration do
  let(:product) { FactoryGirl.build(:product) }

  before do
    Utusemi.configure do
      map :sample do |options|
        name :title
        caption options[:caption] || :none
      end
    end
  end

  subject { Product }
  it { should respond_to(:utusemi) }

  describe 'ActiveRecord::Base#utusemi' do
    subject { product.utusemi(:sample) }
    it { should respond_to(:title) }
    it { should respond_to(:name) }
  end

  describe 'ActiveRecord::Base#utusemi with options' do
    subject { product.utusemi(:sample, caption: :title) }
    it { expect(subject.caption).to eq(subject.title) }
  end

  context 'association models' do
    let(:product) { FactoryGirl.build(:product, :with_stock) }

    before do
      Utusemi.configure do
        map(:product) { name :title }
        map(:stock) { quantity :units }
      end
    end

    describe '#utusemi(:type)' do
      subject(:product_with_utusemi) { product.utusemi(:product) }
      it { should respond_to(:title) }
      it { should respond_to(:name) }

      context 'has_many' do
        describe '#first' do
          # TODO: Implement the new syntax
          #   map(:sample_one) { ... }
          #   map(:sample_two) { ... }
          #   product.utusemi(sample_one: { stocks: :sample_two }).stocks.first
          #
          #   # However:
          #   #   product.utusemi(sample_one: { stocks: :sample_two }).stocks.first.product
          #   #   #=> that is too bad!!
          #
          #   or
          #
          #   map(:product) { ... }
          #   map(:stock) { ... }
          #   product.utusemi.stocks.first
          #
          subject { product_with_utusemi.stocks.first }
          it { should respond_to(:units) }
          it { should respond_to(:quantity) }
          it { expect(subject.units).to eq(subject.quantity) }
        end
      end
    end
  end
end
