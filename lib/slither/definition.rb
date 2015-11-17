class Slither
  class Definition
    attr_reader :sections, :templates, :options, :columns, :length

    RESERVED_NAMES = [:spacer]

    def initialize(options = {})
      @sections = []
      @columns = []
      @length = 0
      @templates = {}
      @options = {
        :align => :right,
        :by_bytes => true,
        :sectionless => false,
      }.merge(options)
    end

    def section(name, options = {}, &block)
      raise(Slither::AddedSectionToSectionlessError) if @options[:sectionless]
      raise( ArgumentError, "Reserved or duplicate section name: '#{name}'") if
        Section::RESERVED_NAMES.include?( name ) ||
        (@sections.size > 0 && @sections.map{ |s| s.name }.include?( name ))

      section = Slither::Section.new(name, @options.merge(options))
      section.definition = self
      yield(section)
      @sections << section
      section
    end

    def column(name, length, options = {})
      raise(Slither::AddedColumnToSectionedError) unless @options[:sectionless]
      raise(Slither::DuplicateColumnNameError, "You have already defined a column named '#{name}'.") if @columns.map do |c|
        RESERVED_NAMES.include?(c.name) ? nil : c.name
      end.flatten.include?(name)
      col = Column.new(name, length, @options.merge(options))
      @columns << col
      @length += length
      col
    end

    def spacer(length)
      column(:spacer, length)
    end

    def parse(line)
      line_data = line.unpack(unpacker)
      row = {}
      @columns.each_with_index do |c, i|
        row[c.name] = c.parse(line_data[i]) unless RESERVED_NAMES.include?(c.name)
      end

      row
    end

    def template(name, options = {}, &block)
      section = Slither::Section.new(name, @options.merge(options))
      yield(section)
      @templates[name] = section
    end

    def method_missing(method, *args, &block)
      section(method, *args, &block)
    end

    private

      def unpacker
        @columns.map { |c| c.unpacker }.join('')
      end
  end
end
