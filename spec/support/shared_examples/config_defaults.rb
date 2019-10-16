# frozen_string_literal: true

shared_examples "a class that includes Config::Helpers" do
  describe "setting defaults" do
    let(:accessor_names) do
      (described_class.instance_methods - Class.methods)
        .select { |method| method.to_s.end_with?("=") }
        .map { |name| name.to_s.chomp("=") }
    end

    before do
      overrides = respond_to?(:default_overrides) ? default_overrides : {}
      names = accessor_names
      described_class.defaults do |klass|
        names.each do |name|
          val = overrides[name] || "default_#{name}"
          klass.send("#{name}=", val)
        end
      end
    end

    after { described_class.clear_defaults! }

    it "allows accessors to be configured with default values" do
      overrides = respond_to?(:default_overrides) ? default_overrides : {}
      klass = if respond_to?(:model)
                described_class.new(model)
              else
                described_class.new
              end
      accessor_names.each do |name|
        expected = overrides[name] || "default_#{name}"
        expect(klass.send(name)).to eq expected
      end
    end

    it "allows defaults to be overridden" do
      overrides = respond_to?(:new_overrides) ? new_overrides : {}
      names = accessor_names
      block = proc do |klass|
        names.each do |name|
          val = overrides[name] || "new_#{name}"
          klass.send("#{name}=", val)
        end
      end
      klass = if respond_to?(:model)
                described_class.new(model, &block)
              else
                described_class.new(&block)
              end
      names.each do |name|
        expected = overrides[name] || "new_#{name}"
        expect(klass.send(name)).to eq expected
      end
    end
  end # describe 'setting defaults'
end
