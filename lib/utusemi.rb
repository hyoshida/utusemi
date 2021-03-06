require 'rails'

require 'utusemi/definition'
require 'utusemi/configuration'
require 'utusemi/railtie'
require 'utusemi/core'

module Utusemi
  class << self
    def enable
      this = self
      ActiveSupport.on_load(:active_record) do
        # for instance
        this.include_to_activerecord_base
        # for model and relation
        this.prepend_to_activerecord_base
        this.prepend_to_activerecord_relation
        this.prepend_to_activerecord_singleton_class
        this.prepend_to_activerecord_associations_hasmanyassociation
        this.prepend_to_activerecord_associations_collectionproxy
      end
    end

    def config
      @configuration ||= Configuration.new
    end

    def configure(&block)
      config.instance_eval(&block)
    end

    def include_to_activerecord_base
      # TODO: Organize name spaces
      ActiveRecord::Base.send(:include, Core::InstanceMethods)
    end

    def prepend_to_activerecord_base
      ActiveRecord::Base.send(:prepend, Core::ActiveRecord::Base)
    end

    def prepend_to_activerecord_relation
      ActiveRecord::Relation.send(:prepend, Core::ActiveRecord::QueryMethods)
      ActiveRecord::Relation.send(:prepend, Core::ActiveRecord::Relation)
    end

    def prepend_to_activerecord_singleton_class
      ActiveRecord::Base.singleton_class.send(:prepend, Core::ActiveRecord::Base::ClassMethods)
      # for rails 3.x
      ActiveRecord::Base.singleton_class.send(:prepend, Core::ActiveRecord::RelationMethod) if Rails::VERSION::MAJOR == 3
      # for association
      ActiveRecord::Base.singleton_class.send(:prepend, Core::ActiveRecord::AssociationMethods)
    end

    def prepend_to_activerecord_associations_hasmanyassociation
      ActiveRecord::Associations::HasManyAssociation.send(:prepend, Core::ActiveRecord::Associations)
    end

    def prepend_to_activerecord_associations_collectionproxy
      ActiveRecord::Associations::CollectionProxy.send(:prepend, Core::ActiveRecord::CollectionProxy) if Rails::VERSION::MAJOR == 3
    end
  end
end
