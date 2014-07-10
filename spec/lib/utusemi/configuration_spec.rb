describe Utusemi::Configuration do
  before do
    Utusemi.configure do
      map :sample do
        name :title
      end
    end
    class Product < ActiveRecord::Base; end
  end

  subject { Product }

  it { should respond_to(:utusemi) }

  context 'ActiveRecord::Base#utusemi' do
    let(:product) { FactoryGirl.build(:product) }

    subject { product.utusemi(:sample) }

    it { should respond_to(:title) }
    it { should respond_to(:name) }
  end
end
