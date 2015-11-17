require File.join(File.dirname(__FILE__), 'spec_helper')

describe Slither::Column do
  before(:each) do
    @name = :id
    @length = 5
    @column = Slither::Column.new(@name, @length)
  end

  describe "when being created" do
    it "should have a name" do
      expect(@column.name).to eq(@name)
    end

    it "should have a length" do
      expect(@column.length).to eq(@length)
    end

    it "should have a default padding" do
      expect(@column.padding).to eq(:space)
    end

    it "should have a default alignment" do
      expect(@column.alignment).to eq(:right)
    end

    it "should return a proper formatter" do
      expect(@column.send(:formatter)).to eq("%5s")
    end
  end

  describe "when specifying an alignment" do
    before(:each) do
      @column = Slither::Column.new(@name, @length, :align => :left)
    end

    it "should only accept :right or :left for an alignment" do
      expect{ Slither::Column.new(@name, @length, :align => :bogus) }.to raise_error(ArgumentError, "Option :align only accepts :right (default) or :left")
    end

    it "should override the default alignment" do
      expect(@column.alignment).to eq(:left)
    end
  end

  describe "when specifying padding" do
    before(:each) do
      @column = Slither::Column.new(@name, @length, :padding => :zero)
    end

    it "should accept only :space or :zero" do
      expect{ Slither::Column.new(@name, @length, :padding => :bogus) }.to raise_error(ArgumentError, "Option :padding only accepts :space (default) or :zero")
    end

    it "should override the default padding" do
      expect(@column.padding).to eq(:zero)
    end
  end

  it "should return the proper unpack value for a string" do
    expect(@column.send(:unpacker)).to eq('A5')
  end

  describe "when parsing a value from a file" do
    it "should default to a string" do
      expect(@column.parse('    name ')).to eq('name')
      expect(@column.parse('      234')).to eq('234')
      expect(@column.parse('000000234')).to eq('000000234')
      expect(@column.parse('12.34')).to eq('12.34')
    end

    it "should support the integer type" do
      @column = Slither::Column.new(:amount, 10, :type=> :integer)
      expect(@column.parse('234     ')).to eq(234)
      expect(@column.parse('     234')).to eq(234)
      expect(@column.parse('00000234')).to eq(234)
      expect(@column.parse('Ryan    ')).to eq(0)
      expect(@column.parse('00023.45')).to eq(23)
    end

    it "should support the float type" do
      @column = Slither::Column.new(:amount, 10, :type=> :float)
      expect(@column.parse('  234.45')).to eq(234.45)
      expect(@column.parse('234.5600')).to eq(234.56)
      expect(@column.parse('     234')).to eq(234.0)
      expect(@column.parse('00000234')).to eq(234.0)
      expect(@column.parse('Ryan    ')).to eq(0)
      expect(@column.parse('00023.45')).to eq(23.45)
    end

    it "should support the money_with_implied_decimal type" do
      @column = Slither::Column.new(:amount, 10, :type=> :money_with_implied_decimal)
      expect(@column.parse('   23445')).to eq(234.45)
    end

    it "should support the date type" do
      @column = Slither::Column.new(:date, 10, :type => :date)
      dt = @column.parse('2009-08-22')
      expect(dt).to be_a(Date)
      expect(dt.to_s).to eq('2009-08-22')
    end

    it "should use the format option with date type if available" do
      @column = Slither::Column.new(:date, 10, :type => :date, :format => "%m%d%Y")
      dt = @column.parse('08222009')
      expect(dt).to be_a(Date)
      expect(dt.to_s).to eq('2009-08-22')
    end

    it "should use a formatting block if available" do
      @column = Slither::Column.new(:name, 10, :type => :string) { |value| value.upcase }
      st = @column.parse('john smith')
      st.should be_a(String)
      st.should == 'JOHN SMITH'
    end
  end

  describe "when applying formatting options" do
    it "should return a proper formatter" do
      @column = Slither::Column.new(@name, @length, :align => :left)
      expect(@column.send(:formatter)).to eq("%-5s")
    end

    it "should respect a right alignment" do
      @column = Slither::Column.new(@name, @length, :align => :right)
      expect(@column.format(25)).to eq('   25')
    end

    it "should respect a left alignment" do
      @column = Slither::Column.new(@name, @length, :align => :left)
      expect(@column.format(25)).to eq('25   ')
    end

    it "should respect padding with spaces" do
      @column = Slither::Column.new(@name, @length, :padding => :space)
      expect(@column.format(25)).to eq('   25')
    end

    it "should respect padding with zeros with integer types" do
      @column = Slither::Column.new(@name, @length, :type => :integer, :padding => :zero)
      expect(@column.format(25)).to eq('00025')
    end

    describe "that is a float type" do
      it "should respect padding with zeros aligned right" do
        @column = Slither::Column.new(@name, @length, :type => :float, :padding => :zero, :align => :right)
        expect(@column.format(4.45)).to eq('04.45')
      end

      it "should respect padding with zeros aligned left" do
        @column = Slither::Column.new(@name, @length, :type => :float, :padding => :zero, :align => :left)
        expect(@column.format(4.45)).to eq('4.450')
      end
    end
  end

  describe "when formatting values for a file" do
    it "should default to a string" do
      @column = Slither::Column.new(:name, 10)
      expect(@column.format('Bill')).to eq('      Bill')
    end

    describe "whose size is too long" do
      it "should raise an error if truncate is false" do
        @value = "XX" * @length
        expect { @column.format(@value) }.to raise_error(
          Slither::FormattedStringExceedsLengthError,
          "The formatted value '#{@value}' in column '#{@name}' exceeds the allowed length of #{@length} chararacters."
        )
      end

      it "should truncate from the left if truncate is true and aligned left" do
        @column = Slither::Column.new(@name, @length, :truncate => true, :align => :left)
        expect(@column.format("This is too long")).to eq("This ")
      end

      it "should truncate from the right if truncate is true and aligned right" do
        @column = Slither::Column.new(@name, @length, :truncate => true, :align => :right)
        expect(@column.format("This is too long")).to eq(" long")
      end
    end

    it "should support the integer type" do
      @column = Slither::Column.new(:amount, 10, :type => :integer)
      expect(@column.format(234)).to        eq('       234')
      expect(@column.format('234')).to      eq('       234')
    end

    it "should support the float type" do
      @column = Slither::Column.new(:amount, 10, :type => :float)
      expect(@column.format(234.45)).to       eq('    234.45')
      expect(@column.format('234.4500')).to   eq('    234.45')
      expect(@column.format('3')).to          eq('       3.0')
    end

    it "should support the float type with a format" do
      @column = Slither::Column.new(:amount, 10, :type => :float, :format => "%.3f")
      expect(@column.format(234.45)).to       eq('   234.450')
      expect(@column.format('234.4500')).to   eq('   234.450')
      expect(@column.format('3')).to          eq('     3.000')
    end

    it "should support the float type with a format, alignment and padding" do
      @column = Slither::Column.new(:amount, 10, :type => :float, :format => "%.2f", :align => :left, :padding => :zero)
      expect(@column.format(234.45)).to       eq('234.450000')
      @column = Slither::Column.new(:amount, 10, :type => :float, :format => "%.2f", :align => :right, :padding => :zero)
      expect(@column.format('234.400')).to    eq('0000234.40')
      @column = Slither::Column.new(:amount, 10, :type => :float, :format => "%.4f", :align => :left, :padding => :space)
      expect(@column.format('3')).to          eq('3.0000    ')
    end

    it "should support the money_with_implied_decimal type" do
      @column = Slither::Column.new(:amount, 10, :type=> :money_with_implied_decimal)
      expect(@column.format(234.450)).to   eq("     23445")
      expect(@column.format(12.34)).to     eq("      1234")
    end

    it "should support the date type" do
      dt = Date.new(2009, 8, 22)
      @column = Slither::Column.new(:date, 10, :type => :date)
      expect(@column.format(dt)).to eq('2009-08-22')
    end

    it "should support the date type with a :format" do
      dt = Date.new(2009, 8, 22)
      @column = Slither::Column.new(:date, 8, :type => :date, :format => "%m%d%Y")
      expect(@column.format(dt)).to eq('08222009')
    end

    it "should support a formatting block" do
      @column = Slither::Column.new(:name, 10, :type => :string) { |value| value.upcase }
      @column.format('john smith').should == 'JOHN SMITH'
    end
  end

end
