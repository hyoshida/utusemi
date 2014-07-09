module Utusemi
  class Configuration
    def initialize
      @maps ||= {}
    end

    def map(name, *args, &block)
      return map_get(name, *args) unless block_given?
      options = args.shift if args.first.is_a? Hash
      map_set(name, options, &block)
    end

    private

    def map_set(name, options, &block)
      @maps[name.to_sym] = (options || {}).merge(block: block)
    end

    def map_get(name, *args)
      map = @maps[name.to_sym].try(:dup) if name
      block = map.delete(:block) if map
      definition = Definition.new(map)
      definition.exec(*args, &block)
    end
  end
end
