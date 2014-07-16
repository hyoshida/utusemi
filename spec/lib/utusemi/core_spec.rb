describe Utusemi::Core do
  describe Utusemi::Core::Base do
    describe '#warning_checker' do
      let(:warning_message) { '[Utusemi:WARNING] "title" is duplicated in map(:product).' }

      before do
        Utusemi.configure do
          map(:product) { title :title }
        end
      end

      context 'alias is duplicated in ::utusemi' do
        let!(:product) { FactoryGirl.create(:product, :with_stock) }
        it 'output warning' do
          expect(Rails.logger).to receive(:warn).with(warning_message)
          Product.utusemi(:product)
        end
      end

      context 'alias is duplicated in #utusemi' do
        let(:product) { FactoryGirl.build(:product, :with_stock) }
        it 'output warning' do
          expect(Rails.logger).to receive(:warn).with(warning_message)
          product.utusemi(:product)
        end
      end
    end
  end

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

  describe ActiveRecord::Base::ClassMethods do
    describe '::utusemi!' do
      before { class TemporaryModel < ActiveRecord::Base; end }
      before { subject.utusemi! }
      subject { TemporaryModel }
      it { expect(subject.utusemi_values).not_to be_empty }
    end

    describe '::utusemi' do
      before { subject.utusemi }
      subject { Product }
      it { expect(subject.utusemi_values).to be_empty }
    end
  end

  describe Utusemi::Core::InstanceMethods do
    let(:product_first) { FactoryGirl.build(:product) }
    let(:product_second) { FactoryGirl.build(:product) }

    describe '#utusemi!' do
      before { subject.utusemi! }
      subject { product_first }
      it { expect(subject.utusemi_values).not_to be_empty }
    end

    describe '#utusemi' do
      before { subject.utusemi }
      subject { product_second }
      it { expect(subject.utusemi_values).to be_empty }
    end
  end
end
