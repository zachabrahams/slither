require File.join(File.dirname(__FILE__), 'spec_helper')

describe Slither::Definition do  
  before(:each) do
  end
  
  describe "when specifying alignment" do
    it "should have an alignment option" do
      d = Slither::Definition.new :align => :right
      expect(d.options[:align]).to eq(:right)
    end
    
    it "should default to being right aligned" do
      d = Slither::Definition.new
      expect(d.options[:align]).to eq(:right)
    end
  
    it "should override the default if :align is passed to the section" do
      d = Slither::Definition.new
      expect(d.options[:align]).to eq(:right)
      d.section('name', :align => :left) {}
      section = nil
      d.sections.each { |sec| section = sec if sec.name == 'name' }
      expect(section.options[:align]).to eq(:left)
    end
  end
  
  describe "when creating a section" do
    before(:each) do
      @d = Slither::Definition.new
      @section = double('section').as_null_object
    end
    
    it "should create and yield a new section object" do
      yielded = nil
      @d.section :header do |section|
        yielded = section
      end
      expect(yielded).to be_a(Slither::Section)
      expect(@d.sections.first).to eq(yielded)
    end
          
    it "should magically build a section from an unknown method" do
      expect(Slither::Section).to receive(:new).with(:header, anything()).and_return(@section)
      @d.header {}
    end
    
    it "should not create duplicate section names" do
      expect { @d.section(:header) {} }.not_to raise_error
      expect { @d.section(:header) {} }.to raise_error(ArgumentError, "Reserved or duplicate section name: 'header'")
    end
    
    it "should throw an error if a reserved section name is used" do
      expect { @d.section(:spacer) {} }.to raise_error(ArgumentError, "Reserved or duplicate section name: 'spacer'")
    end
  end
  
  describe "when creating a template" do
    before(:each) do
      @d = Slither::Definition.new
      @section = double('section').as_null_object
    end
    
    it "should create a new section" do
      expect(Slither::Section).to receive(:new).with(:row, anything()).and_return(@section)
      @d.template(:row) {}
    end
    
    it "should yield the new section" do
      expect(Slither::Section).to receive(:new).with(:row, anything()).and_return(@section)
      yielded = nil
      @d.template :row do |section|
        yielded = section
      end
      expect(yielded).to eq(@section)
    end
    
    it "add a section to the templates collection" do
      expect(@d.templates.size).to eq(0)
      @d.template :row do |t|
        t.column :id, 3
      end
      expect(@d.templates.size).to eq(1)
    end
  end
end