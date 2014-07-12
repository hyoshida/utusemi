describe Utusemi::Configuration do
  let(:product) { FactoryGirl.build(:product) }

  before do
    Utusemi.configure do
      map :sample do |options|
        name :title
        caption options[:caption] || :none
      end
    end
    class Product < ActiveRecord::Base; end
  end

  subject { Product }
  it { should respond_to(:utusemi) }

  context 'ActiveRecord::Base#utusemi' do
    subject { product.utusemi(:sample) }
    it { should respond_to(:title) }
    it { should respond_to(:name) }
  end

  context 'ActiveRecord::Base#utusemi with options' do
    subject { product.utusemi(:sample, caption: :title) }
    it { expect(subject.caption).to eq(subject.title) }
  end
end
