require 'spec_helper'

describe "mock_model(RealModel)" do
  context "given a String" do
    context "that does not represent an existing constant" do
      it "class says it's name" do
        model = mock_model("Foo")
        expect(model.class.name).to eq("Foo")
      end
    end

    context "that represents an existing constant" do
      context "that extends ActiveModel::Naming" do
        it "treats the constant as the class" do
          model = mock_model("MockableModel")
          expect(model.class.name).to eq("MockableModel")
        end
      end

      context "that does not extend ActiveModel::Naming" do
        it "raises with a helpful message" do
          expect do
            mock_model("String")
          end.to raise_error(ArgumentError)
        end
      end
    end
  end

  context "given a class that does not extend ActiveModel::Naming" do
    it "raises with a helpful message" do
      expect do
        mock_model(String)
      end.to raise_error(ArgumentError)
    end
  end

  describe "with #id stubbed" do
    before(:each) do
      @model = mock_model(MockableModel, :id => 1)
    end

    it "is named using the stubbed id value" do
      expect(@model.instance_variable_get(:@name)).to eq("MockableModel_1")
    end
  end

  describe "destroy" do
    it "sets persisted to false" do
      model = mock_model(MockableModel)
      model.destroy
      expect(model).not_to be_persisted
    end
  end

  describe "association" do
    it "constructs a mock association object" do
      model = mock_model(MockableModel)
      expect(model.association(:association_name)).to be
    end

    it "returns a different association object for each association name" do
      model = mock_model(MockableModel)
      posts = model.association(:posts)
      authors = model.association(:authors)

      expect(posts).not_to equal(authors)
    end

    it "returns the same association model each time for the same association name" do
      model = mock_model(MockableModel)
      posts1 = model.association(:posts)
      posts2 = model.association(:posts)

      expect(posts1).to equal(posts2)
    end
  end

  describe "errors" do
    context "default" do
      it "is empty" do
        model = mock_model(MockableModel)
        expect(model.errors).to be_empty
      end
    end

    context "with :save => false" do
      it "is not empty" do
        model = mock_model(MockableModel, :save => false)
        expect(model.errors).not_to be_empty
      end
    end

    context "with :update_attributes => false" do
      it "is not empty" do
        model = mock_model(MockableModel, :save => false)
        expect(model.errors).not_to be_empty
      end
    end
  end

  describe "with params" do
    it "does not mutate its parameters" do
      params = {:a => 'b'}
      mock_model(MockableModel, params)
      expect(params).to eq({:a => 'b'})
    end
  end

  describe "has_many association" do
    before(:each) do
      @real = HasManyAssociatedModel.new
      @mock_model = mock_model(MockableModel)
      @real.mockable_models << @mock_model
    end

    it "passes: associated_model == mock" do
      expect([@mock_model]).to eq(@real.mockable_models)
    end

    it "passes: mock == associated_model" do
      expect(@real.mockable_models).to eq([@mock_model])
    end
  end

  describe "has_one association" do
    before(:each) do
      @real = HasOneAssociatedModel.new
      @mock_model = mock_model(MockableModel)
      @real.mockable_model = @mock_model
    end

    it "passes: associated_model == mock" do
      expect(@mock_model).to eq(@real.mockable_model)
    end

    it "passes: mock == associated_model" do
      expect(@real.mockable_model).to eq(@mock_model)
    end
  end

  describe "belongs_to association" do
    before(:each) do
      @real = AssociatedModel.create!
      @mock_model = mock_model(MockableModel)
      @real.mockable_model = @mock_model
    end

    it "passes: associated_model == mock" do
      expect(@mock_model).to eq(@real.mockable_model)
    end

    it "passes: mock == associated_model" do
      expect(@real.mockable_model).to eq(@mock_model)
    end
  end

  xdescribe "belongs_to association that doesn't exist yet" do
    before(:each) do
      @real = AssociatedModel.create!
      @mock_model = mock_model("Other")
      @real.nonexistent_model = @mock_model
    end

    it "passes: associated_model == mock" do
      expect(@mock_model).to eq(@real.nonexistent_model)
    end

    it "passes: mock == associated_model" do
      expect(@real.nonexistent_model).to eq(@mock_model)
    end
  end

  describe "#is_a?" do
    before(:each) do
      @model = mock_model(SubMockableModel)
    end

    it "says it is_a?(RealModel)" do
      expect(@model.is_a?(SubMockableModel)).to be(true)
    end

    it "says it is_a?(OtherModel) if RealModel is an ancestors" do
      expect(@model.is_a?(MockableModel)).to be(true)
    end

    it "can be stubbed" do
      expect(mock_model(MockableModel, :is_a? => true).is_a?(:Foo)).to be_truthy
    end
  end

  describe "#kind_of?" do
    before(:each) do
      @model = mock_model(SubMockableModel)
    end

    it "says it is kind_of? if RealModel is" do
      expect(@model.kind_of?(SubMockableModel)).to be(true)
    end

    it "says it is kind_of? if RealModel's ancestor is" do
      expect(@model.kind_of?(MockableModel)).to be(true)
    end

    it "can be stubbed" do
      expect(mock_model(MockableModel, :kind_of? => true).kind_of?(:Foo)).to be_truthy
    end
  end

  describe "#instance_of?" do
    before(:each) do
      @model = mock_model(SubMockableModel)
    end

    it "says it is instance_of? if RealModel is" do
      expect(@model.instance_of?(SubMockableModel)).to be(true)
    end

    it "does not say it instance_of? if RealModel isn't, even if it's ancestor is" do
      expect(@model.instance_of?(MockableModel)).to be(false)
    end

    it "can be stubbed" do
      expect(mock_model(MockableModel, :instance_of? => true).instance_of?(:Foo)).to be_truthy
    end
  end

  describe "#has_attribute?" do
    context "with an ActiveRecord model" do
      around do |example|
        original = RSpec::Mocks.configuration.syntax
        RSpec::Mocks.configuration.syntax = :should
        example.run
        RSpec::Mocks.configuration.syntax = original
      end

      before(:each) do
        MockableModel.stub(:column_names).and_return(["column_a", "column_b"])
        @model = mock_model(MockableModel)
      end

      it "has a given attribute if the underlying model has column of the same name" do
        expect(@model.has_attribute?("column_a")).to be_truthy
        expect(@model.has_attribute?("column_b")).to be_truthy
        expect(@model.has_attribute?("column_c")).to be_falsey
      end

      it "accepts symbols" do
        expect(@model.has_attribute?(:column_a)).to be_truthy
        expect(@model.has_attribute?(:column_b)).to be_truthy
        expect(@model.has_attribute?(:column_c)).to be_falsey
      end

      it "allows has_attribute? to be explicitly stubbed" do
        @model = mock_model(MockableModel, :has_attribute? => false)
        expect(@model.has_attribute?(:column_a)).to be_falsey
        expect(@model.has_attribute?(:column_b)).to be_falsey
      end
    end
  end

  describe "#respond_to?" do
    context "with an ActiveRecord model" do
      before(:each) do
        allow(MockableModel).to receive(:column_names).and_return(["column_a", "column_b"])
        @model = mock_model(MockableModel)
      end

      it "accepts two arguments" do
        expect do
          @model.respond_to?("title_before_type_cast", false)
        end.to_not raise_exception
      end

      context "without as_null_object" do
        it "says it will respond_to?(key) if RealModel has the attribute 'key'" do
          expect(@model.respond_to?("column_a")).to be(true)
        end
        it "stubs column accessor (with string)" do
          @model.respond_to?("column_a")
          expect(@model.column_a).to be_nil
        end
        it "stubs column accessor (with symbol)" do
          @model.respond_to?(:column_a)
          expect(@model.column_a).to be_nil
        end
        it "does not stub column accessor if already stubbed in declaration (with string)" do
          model = mock_model(MockableModel, "column_a" => "a")
          model.respond_to?("column_a")
          expect(model.column_a).to eq("a")
        end
        it "does not stub column accessor if already stubbed in declaration (with symbol)" do
          model = mock_model(MockableModel, :column_a => "a")
          model.respond_to?("column_a")
          expect(model.column_a).to eq("a")
        end
        it "does not stub column accessor if already stubbed after declaration (with string)" do
          allow(@model).to receive(:column_a) { "a" }
          @model.respond_to?("column_a")
          expect(@model.column_a).to eq("a")
        end
        it "does not stub column accessor if already stubbed after declaration (with symbol)" do
          allow(@model).to receive(:column_a) { "a" }
          @model.respond_to?("column_a")
          expect(@model.column_a).to eq("a")
        end
        it "says it will not respond_to?(key) if RealModel does not have the attribute 'key'" do
          expect(@model.respond_to?("column_c")).to be(false)
        end
        it "says it will not respond_to?(xxx_before_type_cast)" do
          expect(@model.respond_to?("title_before_type_cast")).to be(false)
        end
      end

      context "with as_null_object" do
        it "says it will respond_to?(key) if RealModel has the attribute 'key'" do
          expect(@model.as_null_object.respond_to?("column_a")).to be(true)
        end
        it "says it will respond_to?(key) even if RealModel does not have the attribute 'key'" do
          expect(@model.as_null_object.respond_to?("column_c")).to be(true)
        end
        it "says it will not respond_to?(xxx_before_type_cast)" do
          expect(@model.as_null_object.respond_to?("title_before_type_cast")).to be(false)
        end
        it "returns self for any unprepared message" do
          @model.as_null_object.tap do |x|
            expect(x.non_existant_message).to be(@model)
          end
        end
      end
    end

    context "with a non-ActiveRecord model" do
      it "responds as normal" do
        model = NonActiveRecordModel.new
        expect(model).to respond_to(:to_param)
      end

      context "with as_null_object" do
        around do |example|
          original = RSpec::Mocks.configuration.syntax
          RSpec::Mocks.configuration.syntax = :should
          example.run
          RSpec::Mocks.configuration.syntax = original
        end

        it "says it will not respond_to?(xxx_before_type_cast)" do
          model = NonActiveRecordModel.new.as_null_object
          expect(model.respond_to?("title_before_type_cast")).to be(false)
        end
      end
    end

    it "can be stubbed" do
      expect(mock_model(MockableModel, :respond_to? => true).respond_to?(:foo)).to be_truthy
    end
  end

  describe "#class" do
    it "returns the mocked model" do
      expect(mock_model(MockableModel).class).to eq(MockableModel)
    end

    it "can be stubbed" do
      expect(mock_model(MockableModel, :class => String).class).to be(String)
    end
  end

  describe "#to_s" do
    it "returns (model.name)_(model#to_param)" do
      expect(mock_model(MockableModel).to_s).to eq("MockableModel_#{to_param}")
    end

    it "can be stubbed" do
      expect(mock_model(MockableModel, :to_s => "this string").to_s).to eq("this string")
    end
  end

  describe "#destroyed?" do
    context "default" do
      it "returns false" do
        @model = mock_model(SubMockableModel)
        expect(@model.destroyed?).to be(false)
      end
    end
  end

  describe "#marked_for_destruction?" do
    context "default" do
      it "returns false" do
        @model = mock_model(SubMockableModel)
        expect(@model.marked_for_destruction?).to be(false)
      end
    end
  end

  describe "#persisted?" do
    context "with default identifier" do
      it "returns true" do
        expect(mock_model(MockableModel)).to be_persisted
      end
    end

    context "with explicit identifier via :id" do
      it "returns true" do
        expect(mock_model(MockableModel, :id => 37)).to be_persisted
      end
    end

    context "with id => nil" do
      it "returns false" do
        expect(mock_model(MockableModel, :id => nil)).not_to be_persisted
      end
    end
  end

  describe "#valid?" do
    context "default" do
      it "returns true" do
        expect(mock_model(MockableModel)).to be_valid
      end
    end

    context "stubbed with false" do
      it "returns false" do
        expect(mock_model(MockableModel, :valid? => false)).not_to be_valid
      end
    end
  end

  describe "#as_new_record" do
    it "says it is a new record" do
      m = mock_model(MockableModel)
      expect(m.as_new_record).to be_new_record
    end

    it "says it is not persisted" do
      m = mock_model(MockableModel)
      expect(m.as_new_record).not_to be_persisted
    end

    it "has a nil id" do
      expect(mock_model(MockableModel).as_new_record.id).to be(nil)
    end

    it "returns nil for #to_param" do
      expect(mock_model(MockableModel).as_new_record.to_param).to be(nil)
    end
  end

  describe "#blank?" do
    it "is false" do
      expect(mock_model(MockableModel)).not_to be_blank
    end
  end

  describe "ActiveModel Lint tests" do
    begin
      require 'minitest/assertions'
      include Minitest::Assertions
      include MinitestAssertion
    rescue LoadError
      if RUBY_VERSION >= '2.2.0'
        # Minitest / TestUnit has been removed from ruby core. However, we are
        # on an old Rails version and must load the appropriate gem
        version = ENV.fetch('RAILS_VERSION', '4.2.4')
        if version >= '4.0.0'
          # ActiveSupport 4.0.x has the minitest '~> 4.2' gem as a dependency
          # This gem has no `lib/minitest.rb` file.
          gem 'minitest' if defined?(Kernel.gem)
          require 'minitest/unit'
          include MiniTest::Assertions
        elsif version >= '3.2.22' || version == '3-2-stable'
          begin
            # Test::Unit "helpfully" sets up autoload for its `AutoRunner`.
            # While we do not reference it directly, when we load the `TestCase`
            # classes from AS (ActiveSupport), AS kindly references `AutoRunner`
            # for everyone.
            #
            # To handle this we need to pre-emptively load 'test/unit' and make
            # sure the version installed has `AutoRunner` (the 3.x line does to
            # date). If so, we turn the auto runner off.
            require 'test/unit'
            require 'test/unit/assertions'
          rescue LoadError => e
            raise LoadError, <<-ERR.squeeze, e.backtrace
              Ruby 2.2+ has removed test/unit from the core library. Rails
              requires this as a dependency. Please add test-unit gem to your
              Gemfile: `gem 'test-unit', '~> 3.0'` (#{e.message})"
            ERR
          end
          include Test::Unit::Assertions
          if defined?(Test::Unit::AutoRunner.need_auto_run = ())
            Test::Unit::AutoRunner.need_auto_run = false
          elsif defined?(Test::Unit.run = ())
            Test::Unit.run = false
          end
        else
          raise LoadError, <<-ERR.squeeze
            Ruby 2.2+ doesn't support this version of Rails #{version}
          ERR
        end
      else
        require 'test/unit/assertions'
        include Test::Unit::Assertions
        if defined?(Test::Unit::AutoRunner.need_auto_run = ())
          Test::Unit::AutoRunner.need_auto_run = false
        elsif defined?(Test::Unit.run = ())
          Test::Unit.run = false
        end
      end
    end

    require 'active_model/lint'
    include ActiveModel::Lint::Tests

    # to_s is to support ruby-1.9
    ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
      example m.gsub('_',' ') do
        send m
      end
    end

    def model
      mock_model(MockableModel, :id => nil)
    end
  end
end
