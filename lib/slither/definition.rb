class Slither
  class Definition
    attr_reader :sections, :templates, :options, :columns, :length

    RESERVED_NAMES = [:spacer]

    def initialize(options = {})
      @sections = []
      @templates = {}
      @options = {
        :align => :right,
        :by_bytes => true,
        :sectionless => false,
      }.merge(options)

      sections << Slither::Section.new(:sectionless, @options.merge(options)) if options[:sectionless]
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

    def template(name, options = {}, &block)
      section = Slither::Section.new(name, @options.merge(options))
      yield(section)
      @templates[name] = section
    end

    def method_missing(method, *args, &block)
      if @options[:sectionless]
        @sections.first.send(method, *args, &block) if @sections.first.respond_to?(method)
      else
        raise Slither::AddedColumnToSectionedError if method == :column
        section(method, *args, &block)
      end
    end

  end
end
