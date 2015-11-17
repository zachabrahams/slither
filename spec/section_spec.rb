require File.join(File.dirname(__FILE__), 'spec_helper')
    
describe Slither::Section do
  before(:each) do
    @section = Slither::Section.new(:body)
  end
  
  it "should have no columns after creation" do
    expect(@section.columns).to be_empty
  end
  
  it "should know it's reserved names" do
    expect(Slither::Section::RESERVED_NAMES).to eq([:spacer])
  end
  
  describe "when adding columns" do    
    it "should build an ordered column list" do
      expect(@section.columns.size).to eq(0)
    
      col1 = @section.column :id, 10
      col2 = @section.column :name, 30
      col3 = @section.column :state, 2
    
      expect(@section.columns.size).to eq(3)
      expect(@section.columns[0]).to be(col1)
      expect(@section.columns[1]).to be(col2)
      expect(@section.columns[2]).to be(col3)
    end
  
    it "should create spacer columns" do
      expect(@section.columns.size).to eq(0)
      @section.spacer(5)
      expect(@section.columns.size).to eq(1)
    end
  
    it "can should override the alignment of the definition" do
      section = Slither::Section.new('name', :align => :left)
      expect(section.options[:align]).to eq(:left)
    end
    
    it "should use a missing method to create a column" do
      expect(@section.columns.size).to eq(0)
      @section.first_name 5
      expect(@section.columns.size).to eq(1)
    end
    
    it "should prevent duplicate column names" do
      @section.column :id, 10
      expect { @section.column(:id, 30) }.to raise_error(Slither::DuplicateColumnNameError, "You have already defined a column named 'id'.")
    end
    
    it "should allow duplicate column names that are reserved (i.e. spacer)" do
      @section.spacer 10
      expect { @section.spacer 10 }.not_to raise_error
    end    
  end
  
  it "should accept and store the trap as a block" do
    @section.trap { |v| v == 4 }
    trap = @section.instance_variable_get(:@trap)
    expect(trap).to be_a(Proc)
    expect(trap.call(4)).to eq(true)
  end
  
  describe "when adding a template" do
    before(:each) do
      @template = double('templated section', :columns => [1,2,3], :options => {})
      @definition = double("definition", :templates => { :test => @template } )
      @section.definition = @definition
    end
    
    it "should ensure the template exists" do
      @definition.stub :templates => {}
      expect { @section.template(:none) }.to raise_error(ArgumentError)
    end
    
    it "should add the template columns to the current column list" do
      expect(@template).to receive(:length).and_return(0)
      @section.template :test
      expect(@section.columns.size).to eq(3)
    end
    
    it "should merge the template option" do
       @section = Slither::Section.new(:body, :align => :left)
       @section.definition = @definition
       expect(@template).to receive(:length).and_return(0)
       @template.stub :options => {:align => :right}
       @section.template :test
       expect(@section.options).to eq({:align => :left})
    end
  end

  describe "when formatting a row" do    
    before(:each) do
      @data = { :id => 3, :name => "Ryan" }
    end
    
    it "should default to string data aligned right" do
      @section.column(:id, 5)
      @section.column(:name, 10)      
      expect(@section.format( @data )).to eq("    3      Ryan")      
    end
    
    it "should left align if asked" do
      @section.column(:id, 5)
      @section.column(:name, 10, :align => :left)  
      expect(@section.format(@data)).to eq("    3Ryan      ")      
    end
    
    # it "should raise an error if the data and column definitions aren't the same size" do
    #   @section.column(:id, 5)
    #   lambda { @section.format(@data) }.should raise_error(
    #     Slither::ColumnMismatchError,
    #     "The 'body' section has 1 column(s) defined, but there are 2 column(s) provided in the data."
    #   )
    # end
  end
  
  describe "when parsing a file" do
    before(:each) do
      @line = '   45      Ryan      WoodSC '
      @section = Slither::Section.new(:body)
      @column_content = { :id => 5, :first => 10, :last => 10, :state => 2 }      
    end
    
    it "should return a key for key column" do
      @column_content.each { |k,v| @section.column(k, v) }
      parsed = @section.parse(@line)
      @column_content.each_key { |name| expect(parsed).to have_key(name) }
    end

    it "should not return a key for reserved names" do
      @column_content.each { |k,v| @section.column(k, v) }
      @section.spacer 5
      expect(@section.columns.size).to eq(5)
      parsed = @section.parse(@line)
      expect(parsed.keys.size).to eq(4)
    end
  end
  
  it "should try to match a line using the trap" do
    @section.trap do |line|
      line == 'hello'
    end
    expect(@section.match('hello')).to be_truthy
    expect(@section.match('goodbye')).to be_falsey
  end
end
