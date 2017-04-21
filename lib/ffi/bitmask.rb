require 'ffi'

module FFI

  module Library

    # @overload bitmask(name, values)
    #  Create a named bitmask
    #  @example
    #   bitmask :foo, [:red, :green, :blue] # bits 0,1,2 are used
    #   bitmask :foo, [:red, :green, 5, :blue] # bits 0,5,6 are used
    #  @param [Symbol] name for new bitmask
    #  @param [Array<Symbol, Integer>] values for new bitmask
    # @overload bitmask(*args)
    #  Create an unamed bitmask
    #  @example
    #   bm = bitmask :red, :green, :blue # bits 0,1,2 are used
    #   bm = bitmask :red, :green, 5, blue # bits 0,5,6 are used
    #  @param [Symbol, Integer] args values for new bitmask
    # @overload bitmask(values)
    #  Create an unamed bitmask
    #  @example
    #   bm = bitmask [:red, :green, :blue] # bits 0,1,2 are used
    #   bm = bitmask [:red, :green, 5, blue] # bits 0,5,6 are used
    #  @param [Array<Symbol, Integer>] values for new bitmask
    # @overload bitmask(native_type, name, values)
    #  Create a named enum and specify the native type.
    #  @example
    #   bitmask FFI::Type::UINT64, :foo, [:red, :green, :blue]
    #  @param [FFI::Type] native_type native type for new bitmask
    #  @param [Symbol] name for new bitmask
    #  @param [Array<Symbol, Integer>] values for new bitmask
    # @overload bitmask(native_type, *args)
    #  @example
    #   bitmask FFI::Type::UINT64, :red, :green, :blue
    #  @param [FFI::Type] native_type native type for new bitmask
    #  @param [Symbol, Integer] args values for new bitmask
    # @overload bitmask(native_type, values)
    #  Create a named enum and specify the native type.
    #  @example
    #   bitmask FFI::Type::UINT64, [:red, :green, :blue]
    #  @param [FFI::Type] native_type native type for new bitmask
    #  @param [Array<Symbol, Integer>] values for new bitmask
    # @return [FFI::Bitmask]
    # Create a new FFI::Bitmask
    def bitmask(*args)
      native_type = args.first.kind_of?(FFI::Type) ? args.shift : nil
      name, values = if args[0].kind_of?(Symbol) && args[1].kind_of?(Array)
        [ args[0], args[1] ]
      elsif args[0].kind_of?(Array)
        [ nil, args[0] ]
      else
        [ nil, args ]
      end
      @ffi_enums = FFI::Enums.new unless defined?(@ffi_enums)
      @ffi_enums << (e = native_type ? FFI::Bitmask.new(native_type, values, name) : FFI::Bitmask.new(values, name))

      typedef(e, name) if name
      e
    end

  end

  # Represents a C enum whose values are power of 2
  #
  # @example
  #  enum {
  #    red = (1<<0),
  #    green = (1<<1),
  #    blue = (1<<2)
  #  }
  #
  # Contrary to classical enums, bitmask values are usually combined
  # when used.
  class Bitmask < Enum

    # @overload initialize(info, tag=nil)
    #   @param [nil, Enumerable] info symbols and bit rank for new Bitmask
    #   @param [nil, Symbol] tag name of new Bitmask
    # @overload initialize(native_type, info, tag=nil)
    #   @param [FFI::Type] native_type Native type for new Bitmask
    #   @param [nil, Enumerable] info symbols and bit rank for new Bitmask
    #   @param [nil, Symbol] tag name of new Bitmask
    def initialize(*args)
      @native_type = args.first.kind_of?(FFI::Type) ? args.shift : Type::INT
      info, @tag = *args
      @kv_map = Hash.new
      unless info.nil?
        last_cst = nil
        value = 0
        info.each do |i|
          case i
          when Symbol
            raise ArgumentError, "duplicate bitmask key" if @kv_map.has_key?(i)
            @kv_map[i] = 1 << value
            last_cst = i
            value += 1
          when Integer
            raise ArgumentError, "bitmask index should be positive" if i<0
            @kv_map[last_cst] = 1 << i
            value = i+1
          end
        end
      end
      @vk_map = @kv_map.invert
    end

    # Get a symbol list or a value from the bitmask
    # @overload [](*query)
    #  Get bitmask value from symbol list
    #  @param [Symbol] query
    #  @return [Integer]
    # @overload [](query)
    #  Get bitmaks value from symbol array
    #  @param [Array<Symbol>] query
    #  @return [Integer]
    # @overload [](*query)
    #  Get a list of bitmask symbols corresponding to
    #  the or reduction of a list of integer
    #  @param [Integer] query
    #  @return [Array<Symbol>]
    # @overload [](query)
    #  Get a list of bitmask symbols corresponding to
    #  the or reduction of a list of integer
    #  @param [Array<Integer>] query
    #  @return [Array<Symbol>]
    def [](*query)
      flat_query = query.flatten
      raise ArgumentError, "query should be homogeneous, #{query.inspect}" unless flat_query.all? { |o| o.is_a?(Symbol) } || flat_query.all? { |o| o.is_a?(Integer) || o.respond_to?(:to_int) }
      case flat_query[0]
      when Symbol
        flat_query.inject(0) do |val, o|
          v = @kv_map[o]
          if v then val |= v else val end
        end
      when Integer, ->(o) { o.respond_to?(:to_int) }
        val = flat_query.inject(0) { |mask, o| mask |= o.to_int }
        @kv_map.select { |_, v| v & val != 0 }.keys
      end
    end

    # Get the native value of a bitmask
    # @overload to_native(query, ctx)
    #  @param [Symbol, Integer, #to_int] query
    #  @param ctx unused
    #  @return [Integer] value of a bitmask
    # @overload to_native(query, ctx)
    #  @param [Array<Symbol, Integer, #to_int>] query
    #  @param ctx unused
    #  @return [Integer] value of a bitmask
    def to_native(query, ctx)
      return 0 if query.nil?
      flat_query = [query].flatten
      flat_query.inject(0) do |val, o|
        case o
        when Symbol
          v = @kv_map[o]
          raise ArgumentError, "invalid bitmask value, #{o.inspect}" unless v
          val |= v
        when Integer
          val |= o
        when ->(obj) { obj.respond_to?(:to_int) }
          val |= o.to_int
        else
          raise ArgumentError, "invalid bitmask value, #{o.inspect}"
        end
      end
    end

    # @param [Integer] val
    # @param ctx unused
    # @return [Array<Symbol, Integer>] list of symbol names corresponding to val, plus an optional remainder if some bits don't match any constant
    def from_native(val, ctx)
      list = @kv_map.select { |_, v| v & val != 0 }.keys
      # If there are unmatch flags,
      # return them in an integer,
      # else information can be lost.
      # Similar to Enum behavior.
      remainder = val ^ list.inject(0) do |tmp, o|
        v = @kv_map[o]
        if v then tmp |= v else tmp end
      end
      list.push remainder unless remainder == 0
      return list
    end
  end
end
