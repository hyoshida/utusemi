module Utusemi
  class Configuration
    def initialize
      @maps ||= {}
    end

    def map(name, *args, &block)
      name = (name || '').to_sym
      return map_get(name, *args) unless block_given?
      options = args.shift if args.first.is_a? Hash
      map_set(name, options, &block)
    end

    private

    def map_set(name, options, &block)
      @maps[name] = {}
      @maps[name].update(options) if options
      @maps[name].update(block: block)
    end

    def map_get(name, *args)
      map = @maps[name].try(:dup) || {}
      block = map.delete(:block)
      definition = Definition.new(map)
      definition.exec(*args, &block)
    end
  end
end
