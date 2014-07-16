describe Product do
  let(:product) { FactoryGirl.build(:product, title: 'default title') }

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
    it { expect(subject.title).to eq(subject.name) }

    it '#<attribute>=' do
      subject.name = 'new name'
      expect(subject.title).to eq('new name')
    end

    it '#<attribute>?' do
      expect(subject.name?).to be true
    end

    context 'persisted' do
      let(:product) { FactoryGirl.create(:product) }

      it '#<attribute>_was' do
        name_was = subject.name
        subject.name = 'new name'
        expect(subject.name_was).to eq(name_was)
      end

      it '#changed' do
        subject.name = 'new name'
        expect(subject.changed).to include('name')
      end
    end
  end

  describe '#utusemi(type, options)' do
    subject { product.utusemi(:sample, caption: :title) }
    it { expect(subject.caption).to eq(subject.title) }
  end

  describe '::utusemi(type)' do
    before { FactoryGirl.create(:product, title: 'foobar') }
    subject { described_class.utusemi(:sample) }

    it '::where by alias column in Hash and String' do
      expect(subject.where(name: 'foobar').count).to eq(1)
    end

    it '::where by alias column in Hash and Array' do
      FactoryGirl.create(:product, title: 'hoge')
      expect(subject.where(name: %w(foobar hoge)).count).to eq(2)
    end

    it '::where by alias column in String' do
      expect(subject.where('name LIKE ?', 'foo%').count).to eq(1)
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
