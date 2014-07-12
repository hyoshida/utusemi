describe Utusemi::Core do
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
  describe ActiveRecord::Associations do
    before do
      Utusemi.configure do
        map(:product) { name :title }
        map(:stock) { quantity :units }
      end
    end

    describe '#scope' do
      let(:product) { FactoryGirl.create(:product, :with_stock) }
      subject { product.reload.utusemi(:product).stocks.first }
      it { should respond_to(:units) }
      it { should respond_to(:quantity) }
      it { expect(subject.units).to eq(subject.quantity) }
    end

    describe '#load_target' do
      let(:product) { FactoryGirl.build(:product, :with_stock) }
      subject { product.utusemi(:product).stocks.first }
      it { should respond_to(:units) }
      it { should respond_to(:quantity) }
      it { expect(subject.units).to eq(subject.quantity) }
    end
  end
end
