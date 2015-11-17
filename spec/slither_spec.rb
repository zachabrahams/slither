require File.join(File.dirname(__FILE__), 'spec_helper')

describe Slither do

  before(:each) do
    @name = :doc
    @options = { :align => :left }
  end

  describe "when defining a format" do
    before(:each) do
      @definition = double('definition')
    end

    it "should create a new definition using the specified name and options" do
      expect(Slither).to receive(:define).with(@name, @options).and_return(@definition)
      Slither.define(@name , @options)
    end

    it "should pass the definition to the block" do
      yielded = nil
      Slither.define(@name) do |y|
        yielded = y
      end
      expect(yielded).to be_a( Slither::Definition )
    end

    it "should add to the internal definition count" do
      Slither.definitions.clear
      expect(Slither.definitions.size).to eq(0)
      Slither.define(@name , @options) {}
      expect(Slither.definitions.size).to eq(1)
    end
  end

  describe "when creating file from data" do
    it "should raise an error if the definition name is not found" do
      expect { Slither.generate(:not_there, {}) }.to raise_error(ArgumentError)
    end

    it "should output a string" do
      definition = double('definition')
      generator = double('generator')
      expect(generator).to receive(:generate).with({})
      expect(Slither).to receive(:definition).with(:test).and_return(definition)
      expect(Slither::Generator).to receive(:new).with(definition).and_return(generator)
      Slither.generate(:test, {})
    end

    it "should output a file" do
  	  file = double('file')
  	  text = double('string')
  	  expect(file).to receive(:write).with(text)
  	  expect(File).to receive(:open).with('file.txt', 'w').and_yield(file)
  	  expect(Slither).to receive(:generate).with(:test, {}).and_return(text)
      Slither.write('file.txt', :test, {})
  	end
  end

  describe "when parsing a file" do
    before(:each) do
      @file_name = 'file.txt'
    end

    it "should check the file exists" do
      expect { Slither.parse(@file_name, :test, {}) }.to raise_error(ArgumentError)
    end

    it "should raise an error if the definition name is not found" do
      Slither.definitions.clear
      File.stub(:exists? => true)
      expect { Slither.parse(@file_name, :test, {}) }.to raise_error(ArgumentError)
    end

    it "should create a parser and call parse" do
      File.stub(:exists? => true)
      file_io = double("IO")
      parser = double("parser")
      definition = Slither::Definition.new :by_bytes => false

      expect(File).to receive(:open).and_return(file_io)
      expect(Slither).to receive(:definition).with(:test).and_return(definition)
      expect(Slither::Parser).to receive(:new).with(definition, file_io).and_return(parser)
      expect(parser).to receive(:parse).and_return("parse result")

      expect(Slither.parse(@file_name, :test)).to eq("parse result")
    end
  end

  describe 'when parsing a string' do
    before(:each) do
      @raw_string = "****    SECONDCOLUMN   12345"
    end

    it "should raise an error if the definition name is not found" do
      Slither.definitions.clear
      expect { Slither.parse_string(@raw_string, :test, {}) }.to raise_error(ArgumentError)
    end

    it "should create a parser and call parse" do
      string_io = double("StringIO")
      parser = double("parser")
      definition = Slither::Definition.new :by_bytes => false

      expect(StringIO).to receive(:new).and_return(string_io)
      expect(Slither).to receive(:definition).with(:test).and_return(definition)
      expect(Slither::Parser).to receive(:new).with(definition, string_io).and_return(parser)
      expect(parser).to receive(:parse).and_return("parse result")

      expect(Slither.parse_string(@raw_string, :test)).to eq("parse result")
    end


  end

end
