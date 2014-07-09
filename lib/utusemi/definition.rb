module Utusemi
  class Definition
    UNPROXIED_METHODS = %w(__send__ __id__ nil? send object_id extend instance_eval initialize block_given? raise caller method instance_exec)
    OPTION_METHODS = %w(class_name foreign_key)

    (instance_methods + private_instance_methods).each do |method|
      undef_method(method) unless UNPROXIED_METHODS.include?(method.to_s)
    end

    OPTION_METHODS.each do |method|
      define_method(method) { @options[method.to_sym] }
    end

    def initialize(options = {})
      @attributes = {}
      @options = options
    end

    def exec(*args, &block)
      instance_exec(*args, &block) if block_given?
      self
    end

    def attributes
      @attributes
    end

    def method_missing(name, *args)
      add_attribute(name, *args)
    end

    private

    def add_attribute(name, value = nil, &block)
      raise AttributeDefinitionError, 'Block given' if block_given?
      @attributes[name.to_sym] = value.to_sym
    end
  end

  class AttributeDefinitionError; end
end
