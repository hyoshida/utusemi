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

  context 'association models' do
    let(:product) { FactoryGirl.build(:product, :with_stock) }

    before do
      Utusemi.configure do
        map(:product) { name :title }
        map(:stock) { quantity :units }
      end
    end

    describe '#utusemi(type)' do
      subject(:product_with_utusemi) { product.utusemi(:product) }
      it { should respond_to(:title) }
      it { should respond_to(:name) }

      context 'has_many' do
        describe '#first' do
          # TODO: Implement the new syntax
          #
          #   map(:sample_one) { ... }
          #   map(:sample_two) { ... }
          #   class Stock < ActiveRecord::Base
          #     belongs_to :product, utusemi: :sample_one
          #   end
          #   class Product < ActiveRecord::Base
          #     has_many :stocks, utusemi: :sample_two
          #   end
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
