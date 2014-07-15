describe Utusemi::Configuration do
  describe '"times" option' do
    let!(:product_one) { FactoryGirl.create(:product, description1: nil, description2: nil, description3: nil) }
    let!(:product_two) { FactoryGirl.create(:product, description1: 'foo', description2: 'bar', description3: 'hoge') }
    let!(:product_three) { FactoryGirl.create(:product, description1: 'foo', description2: 'bar', description3: nil) }

    before do
      Utusemi.configure do
        map(:sample) { |options| description "description#{options[:index]}" }
      end
    end

    subject { Product.utusemi(:sample, times: 3) }

    it 'found a record that all description are nil' do
      expect(subject.where(description: nil).count).to eq(1)
    end

    it 'found a record that all description are not nil' do
      pending 'Rails 3 is not supported' if Rails::VERSION::MAJOR == 3
      expect(subject.where.not(description: nil).count).to eq(1)
    end
  end
end
