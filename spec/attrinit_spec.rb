RSpec.describe Attrinit do
  it "has a version number" do
    expect(Attrinit::VERSION).not_to be nil
  end

  let(:test_class) do
    Class.new do
      include Attrinit
      attr_init :plain, with_default_value: 'default', with_default_block: -> { default_block }

      private

      def default_block
        'default block'
      end
    end
  end

  describe 'attr_init' do
    context 'when called multiple times' do
      let(:test_class) do
        Class.new do
          include Attrinit
          attr_init :plain, with_default_value: 'default', with_default_block: -> { default_block }
          attr_init :plain, with_default_value: 'new default', with_default_block: -> { 'other default block' }
          attr_init :additional

          private

          def default_block
            'default block'
          end
        end
      end

      subject { test_class.new(plain: 'plain', additional: 'additional') }

      it 'overwrites the initializers from before' do
        expect(subject.send :plain).to eq('plain')
        expect(subject.send :additional).to eq('additional')
        expect(subject.send :with_default_value).to eq('new default')
        expect(subject.send :with_default_block).to eq('other default block')
      end
    end
  end

  describe '.new' do
    context 'when a required parameter is missing' do
      it 'raises an error' do
        expect { test_class.new }.to raise_error(KeyError)
      end
    end

    context 'when required parameters are given' do
      subject { test_class.new(plain: 'plain') }

      it 'initializes the parameters with the correct values' do
        expect(subject.send :plain).to eq('plain')
        expect(subject.send :with_default_value).to eq('default')
        expect(subject.send :with_default_block).to eq('default block')
      end
    end

    describe 'inheritance' do
      context 'when the parent class does not implement attr_init' do
        let(:parent_class) do
          Class.new do
            def initialize(name, company: 'getsafe')
              @name = name
              @company = company
            end

            attr_reader :name, :company
          end
        end

        let(:test_class) do
          Class.new(parent_class) do
            include Attrinit
            attr_init :plain,
                             with_default_value: 'default',
                             with_default_block: -> { 'default block' }

          end
        end

        subject { test_class.new('Andy', company: 'Getsafe', plain: 'plain') }

        it 'passes through arguments and non attr_init options' do
          expect(subject.send :plain).to eq('plain')
          expect(subject.send :with_default_value).to eq('default')
          expect(subject.send :with_default_block).to eq('default block')
          expect(subject.name).to eq('Andy')
          expect(subject.company).to eq('Getsafe')
        end
      end

      context 'when the parent class implements attr_init' do
        let(:attr_init_inherited) do
          Class.new(test_class) do
            attr_init :subclass
          end
        end

        subject { attr_init_inherited.new(plain: 'inherited', subclass: 'only I can see') }

        it 'copies the attr_init options from the parent class' do
          expect(subject.send(:plain)).to eq('inherited')
          expect(subject.send(:subclass)).to eq('only I can see')
        end

        it 'does not influence the attr_init_opts of the parent class' do
          expect { attr_init_inherited }.not_to change { test_class.attr_init_opts}
        end
      end
    end
  end
end
