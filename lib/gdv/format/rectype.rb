require 'date'

module GDV::Format

    class FormatError < RuntimeError
    end

    class RecordError < RuntimeError
    end

    class RecType
        attr_reader :satz, :sparte, :line, :label, :parts
        def initialize(parts, h)
            @satz = h[:satz]
            @sparte = h[:sparte]
            @sparte = nil if @sparte == ""
            @line = h[:line]
            @label = h[:label]
            @parts = parts
            @part_index = {}
            @parts.each do |p|
                p.rectype = self
                p.fields.each do |f|
                    unless @part_index[f.name]
                        @part_index[f.name] = [p.nr, f.name]
                    end
                end
            end
        end

        def index(name)
            @part_index[name]
        end

        def inspect
            "satz = #{satz}\nsparte = #{sparte}\n parts = #{parts.inspect}"
        end

        def finalize
            @parts.each { |p| p.finalize }
        end

        def emit
            parts.each { |p| p.emit }
            puts "K:#{line}:#{satz}:#{sparte}:#{label}"
        end

        def self.parse(parts, l)
            RecType.new(parts, :line => l[1], :satz => l[2], :sparte => l[3],
                        :label => l[4])
        end
    end

    class Part
        attr_reader :nr, :line, :fields, :key_fields
        attr_accessor :rectype

        def initialize(fields, h)
            @nr = h[:nr]
            @line = h[:line]
            @fields = fields
            @key_fields = fields.select { |f| f.const? }
            @fields.each do |f|
                f.part = self
            end
            @field_index = {}
        end

        def field_at(pos, len)
            @fields.each do |f|
                if f.pos == pos && f.len == len
                    return f
                end
            end
            nil
        end

        def field?(name)
            @field_index.key?(name)
        end

        # Look a field up by its name or number
        def [](name)
            if name.is_a?(Fixnum)
                @fields[name - 1]
            else
                unless field?(name)
                    names = @field_index.keys.collect { |k| k.to_s }.sort
                    raise FormatError, "#{line}: No field named #{name} in #{self.rectype.satz}:#{self.rectype.sparte}:#{self.nr}. Possible fields: #{names.join(", ")}"
                end
                @field_index[name]
            end
        end

        def inspect
            self.to_s
        end

        def to_s
            "<Part:#{rectype.satz}:#{rectype.sparte}:#{nr} (line #{line})>"
        end

        def rectype=(rt)
            unless rectype.nil?
                raise FormatError, "RecType already set for #{self}"
            end
            @rectype = rt
        end

        def finalize
            # Make sure field names are unique and compute the
            # length for the 'space' field which might be missing
            names = {}
            used = 0
            @warnings ||= []
            fields.each do |f|
                names[f.name] ||= 0
                names[f.name] += 1
                # 'Overlay' fields have pos set
                used += f.len if f.len && f.pos == 0
            end
            pos = 1
            fields.each do |f|
                f.pos = pos if f.pos == 0
                if f.len.nil? && f.type == :space
                    if used
                        f.len = 256 - used
                        used = nil
                    else
                        raise FormatError, "#{line}: two fields without a length"
                    end
                end
                raise FormatError, "#{line}: missing length #{f.inspect}" if f.len.nil?
                pos += f.len
            end
            names.keys.each do |n|
                if names[n] > 1
                    fields.select { |f| f.name == n }.each do |f|
                        @warnings << "rename #{f.nr}: #{f.name}"
                        f.uniquify_name!
                    end
                end
            end
            fields.each do |f|
                f.finalize
                if @field_index.key?(f.name)
                    raise FormatError, "Duplicate field #{f.name}"
                end
                @field_index[f.name] = f
            end
        end

        def emit
            fields.each { |f| f.emit }
            @warnings.each { |w| puts "C:#{w}" }
            puts "T:#{line}:#{nr}"
        end

        def self.parse(fields, l)
            Part.new(fields, :line => l[1], :nr => l[2].to_i)
        end
    end

    class Field
        attr_reader :nr, :name, :type, :values, :label, :line
        attr_accessor :part, :pos, :len, :map
        attr_reader :precision

        def initialize(h)
            @map = h[:map]
            @line = h[:line]
            @nr = h[:nr]
            if h[:name].empty?
                @name = :"field#{nr}"
            else
                @name = h[:name].to_sym
            end
            if @name == "blank" || @name == "waehrung"
                # For these fields, we don't care too much about their name
                @name = :"#{@name}#{@nr}"
            end
            # Seems to be true based on some examples
            @values = h[:values] || []
            if @name == :snr && @values == ["1"]
                @values << ' '
            end
            @pos = h[:pos] || 0
            @len = h[:len]
            @type = h[:type]
            if number?
                @precision = @values.shift.to_i
            else
                @values = @values.uniq
            end
            @label = h[:label]
            @part = nil
        end

        def uniquify_name!
            @name = "#{@name}_f#{@nr}"
        end

        # Return the raw string for this field from +record+
        def extract(record)
            record[pos-1..pos+len-2]
        end

        # Convert the value for this field in +record+. For mapped types,
        # return the entry from the map. Strip spaces
        def convert(record)
            s = extract(record)
            if mapped?
                map[s]
            elsif number?
                if precision > 0
                    s.to_i / (10.0 ** precision)
                else
                    s.to_i
                end
            elsif type == :date
                d = s[0,2].to_i
                m = s[2,2].to_i
                y = s[4,4].to_i
                return nil if y + m + d == 0
                d = 1 if d == 0
                m = 1 if m == 0
                Date.civil(y,m,d)
            else
                s.strip
            end
        end

        def const?
            type == :const
        end

        def number?
            type == :number
        end

        def mapped?
            ! @map.nil?
        end

        def to_s
            "<Field[#{nr}]#{type}:#{pos}+#{len}>\n"
        end

        def part=(p)
            unless part.nil?
                raise FormatError, "Part already set for #{self}"
            end
            @part = p
        end

        def finalize
            if const?
                if values.empty?
                    raise FormatError,
                    "#{line}:Values can not be empty for const fields #{self.inspect}"
                end
                values.each do |v|
                    if len != v.size
                        raise FormatError,
                        "#{line}:Value #{v} must have exactly #{len} chars"
                    end
                end
            else
                unless values.empty?
                    raise FormatError,
                    "#{line}:Values can only be given for const fields #{self.inspect}"
                end
            end
        end

        def emit
            if number?
                v = [ precision ]
            else
                v = values.join(",")
            end
            puts "F:#{line}:#{nr}:#{name}:#{pos}:#{len}:#{type}:#{v}:#{label}"
        end

        def self.parse(l, maps={})
            v = l[7] || ""
            t = l[6].to_sym
            Field.new(:line => l[1],
                      :nr => l[2].to_i,
                      :name => l[3],
                      :pos => l[4].to_i,
                      :len => l[5].to_i,
                      :type => t,
                      :values => v.split(","),
                      :label => l[8], :map => maps[t])
        end
    end

    class Path
        attr_accessor :satz, :teil, :nr, :sparte
        def initialize(satz, teil, nr, sparte)
            @satz = satz
            @teil = teil
            @nr = nr
            @sparte = sparte
        end
    end

    class ValueMap
        attr_accessor :label, :values
        def initialize(label, values)
            @label = label
            @values = values
        end

        def [](k)
            values[k]
        end
    end

end
