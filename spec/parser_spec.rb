require File.join(File.dirname(__FILE__), 'spec_helper')
    
describe Slither::Parser do
  
  describe "when parsing sections" do
    before(:each) do
      @definition = Slither.define :test, :by_bytes => false do |d|
        d.header do |h|
          h.trap { |line| line[0,4] == 'HEAD' }
          h.column :type, 4
          h.column :file_id, 10
        end
        d.body do |b|
          b.trap { |line| line[0,4] != 'HEAD' &&  line[0,4] != 'FOOT'}
          b.column :first, 10
          b.column :last, 10
        end
        d.footer do |f|
          f.trap { |line| line[0,4] == 'FOOT' }
          f.column :type, 4
          f.column :file_id, 10
        end     
      end
      
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
    end

    it "should add lines to the proper sections" do
      @io.string = "HEAD         1\n      Paul    Hewson\n      Dave     Evans\nFOOT         1"

      expected = {
        :header => [ {:type => "HEAD", :file_id => "1" }],
        :body => [ 
          {:first => "Paul", :last => "Hewson" },
          {:first => "Dave", :last => "Evans" }
        ],
        :footer => [ {:type => "FOOT", :file_id => "1" }]
      }      
      result = @parser.parse
      expect(result).to eq(expected)
    end

    it "should allow optional sections to be skipped" do
      @definition.sections[0].optional = true
      @definition.sections[2].optional = true
      @io.string = '      Paul    Hewson'

      expected = { :body => [ {:first => "Paul", :last => "Hewson" } ] }
      expect(@parser.parse).to eq(expected)      
    end
      
    it "should raise an error if a required section is not found" do
      @io.string = '      Ryan      Wood'

      expect { @parser.parse }.to raise_error(Slither::RequiredSectionNotFoundError, "Required section 'header' was not found.")
    end
    
    it "should raise an error if the line is too long" do
      @definition.sections[0].optional = true
      @definition.sections[2].optional = true
      @io.string = 'abc'*20
      
      expect { @parser.parse }.to raise_error(Slither::LineWrongSizeError)
    end
    
    it "should raise an error if the line is too short" do
      @definition.sections[0].optional = true
      @definition.sections[2].optional = true
      @io.string = 'abc'

      expect { @parser.parse }.to raise_error(Slither::LineWrongSizeError)
    end
    
  end
  
  describe "when parsing by bytes" do
    before(:each) do
      @definition = Slither.define :test do |d|
        d.body do |b|
          b.trap { true }
          b.column :first, 5
          b.column :last, 5
        end   
      end
      
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
    end
    
    it 'should raise error for data with line length too long' do
      @io.string = "abcdefghijklmnop"

      expect { @parser.parse_by_bytes }.to raise_error(Slither::LineWrongSizeError)
    end
    
    it 'should raise error for data with line length too short' do
      @io.string = "abc"

      expect { @parser.parse_by_bytes }.to raise_error(Slither::LineWrongSizeError)
    end
    
    it 'should raise error for data with empty lines' do
      @io.string = "abcdefghij\r\n\n\n\n"  # 10 then 3

      expect { @parser.parse_by_bytes }.to raise_error(Slither::LineWrongSizeError)
    end
    
    it 'should handle utf characters' do
      utf_str1 = "\xE5\x9B\xBD45"
      utf_str2 = "ab\xE5\x9B\xBD"
      @io.string = (utf_str1 + utf_str2)

      expected = {
        :body => [ {:first => utf_str1, :last => utf_str2} ]
      }
      
      expect(Slither.parseIo(@io, :test)).to eq(expected)
    end
    
    it 'should handle mid-line newline chars' do
      str1 = "12\n45"
      str2 = "a\n\r\nb"
      @io.string = (str1 + str2 + "\n" + str1 + str2)

      expected = {
        :body => [ {:first => str1, :last => str2}, {:first => str1, :last => str2} ]
      }
      
      expect(Slither.parseIo(@io, :test)).to eq(expected)
    end
    
    it 'should throw exception if section lengths are different' do
      definition = Slither.define :test, :by_bytes => true do |d|
        d.body do |b|
          b.column :one, 5
        end
        d.foot do |f|
          f.column :only, 2
        end   
      end
      
      parser = Slither::Parser.new(definition, @io)
      
      expect { parser.parse_by_bytes }.to raise_error(Slither::SectionsNotSameLengthError)
    end
  end
  
  describe 'when calling the helper method' do
    
    it 'remove_newlines returns true for file starting in newlines or EOF' do
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
      
      expect(@parser.send(:remove_newlines!)).to eq(true)
      
      @io.string = "\nXYZ"
      expect(@parser.send(:remove_newlines!)).to eq(true)
      @io.string = "\r\n"
      expect(@parser.send(:remove_newlines!)).to eq(true)
      @io.string = "\n\n\n\nXYZ\n"
      expect(@parser.send(:remove_newlines!)).to eq(true)
      @io.string = ""
      expect(@parser.send(:remove_newlines!)).to eq(true)
      
    end
    
    it 'remove_newlines returns false for any other first characters' do
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
      
      @io.string = "XYZ\nxyz"
      expect(@parser.send(:remove_newlines!)).to eq(false)
      @io.string = " \nxyz"
      expect(@parser.send(:remove_newlines!)).to eq(false)
      @io.string = "!YZxyz\n"
      expect(@parser.send(:remove_newlines!)).to eq(false)
      
    end
    
    it 'remove_newlines leaves first non-newline char in place' do
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
      
      @io.string = "\nXYZ"
      expect(@parser.send(:remove_newlines!)).to eq(true)
      expect(@io.getc).to eq("X")
      expect(@parser.send(:remove_newlines!)).to eq(false)
    end
    
    it 'newline? it is true for \n or \r and false otherwise' do
      @parser = Slither::Parser.new(nil,nil)
      
      [["\n",true],["\r",true],["n",false]].each do |el|
        expect(@parser.send(:newline?,el[0].ord)).to eq(el[1])
      end
      expect(@parser.send(:newline?,nil)).to eq(false)
      expect(@parser.send(:newline?,"")).to eq(false)
    end
    
  end
end