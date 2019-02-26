require 'date'

RSpec.describe NxtInit do
  it "has a version number" do
    expect(NxtInit::VERSION).not_to be nil
  end

  let(:test_class) do
    Class.new do
      include NxtInit
      attr_init :plain,
                with_default_value: 'default',
                with_default_block: -> { default_block }

      private

      def default_block
        'default block'
      end
    end
  end

  describe '.attr_init' do
    context 'when called multiple times' do
      let(:test_class) do
        Class.new do
          include NxtInit
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
        expect { test_class.new }.to raise_error(KeyError, 'NxtInit attr_init key :plain was missing at initialization!')
      end
    end

    context 'when required parameters are given' do
      subject { test_class.new(plain: 'plain') }

      it 'initializes the parameters with the correct values' do
        expect(subject.send(:plain)).to eq('plain')
        expect(subject.send(:with_default_value)).to eq('default')
        expect(subject.send(:with_default_block)).to eq('default block')
      end
    end

    context 'preprocessing block' do
      let(:preprocessor) do
        Class.new do
          include NxtInit
          attr_init name: -> (attr) { attr.capitalize }
        end
      end

      context 'when an parameter was given' do
        subject { preprocessor.new(name: 'andy') }

        it 'calls the block with the param' do
          expect(subject.send(:name)).to eq('Andy')
        end
      end

      context 'when no parameter was given' do
        it 'passes nil to the block' do
          expect { preprocessor.new }.to raise_error(KeyError, /NxtInit attr_init key :name was missing at initialization!/)
        end
      end

      context 'when the parameter was nil' do
        it 'passes nil to the block' do
          expect { preprocessor.new(name: nil) }.to raise_error(NoMethodError, /undefined method `capitalize' for nil:NilClass/)
        end
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
            include NxtInit
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
