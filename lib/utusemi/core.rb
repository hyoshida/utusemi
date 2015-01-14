module Utusemi
  module Core
    # 用途
    #   モデル向けカラムマッパとインスタンス向けカラムマッパの共通処理
    #
    # 役割
    #   モデル向けカラムマッパ => Utusemi::Core::ActiveRecord
    #   インスタンス向けカラムマッパ => Utusemi::Core::InstanceMethods
    #
    # 備考
    #   utusemiメソッドの第２引数は、任意のオプションをHashで指定する。
    #   ただしoptions[:times]は予約済みで、指定した回数分だけmapメソッドを
    #   繰り返し、options[:index]にイテレート中のカウントを返す。
    #   また、その結果から複数のwhere条件を構築する。
    #
    module Base
      def utusemi_values
        utusemi_values = @utusemi_values || {}
        utusemi_values = klass_utusemi_values unless utusemi_values[:flag]
        utusemi_values
      end

      def utusemi(obj = nil, options = {})
        clone.utusemi!(obj, options)
      end

      def utusemi!(obj = nil, options = {})
        obj = true if obj.nil?
        @utusemi_values ||= {}
        @utusemi_values[:flag] = obj ? true : false
        @utusemi_values[:type] = obj.to_sym if obj.class.in? [Symbol, String]
        @utusemi_values[:type] ||= default_utusemi_type
        @utusemi_values[:options] = options
        warning_checker unless Rails.env.production?
        self
      end

      private

      def utusemi_column_names(index = nil)
        return {} unless utusemi_values[:flag]
        options = utusemi_values[:options] || {}
        options.update(index: index)
        Utusemi.config.map(utusemi_values[:type], options).attributes
      end

      def mapped_utusemi_column_name(column_name, index = nil)
        utusemi_column_names(index)[column_name.to_sym] || column_name
      end

      def unmapped_utusemi_column_name(column_name, index = nil)
        utusemi_column_names(index).invert[column_name.to_sym] || column_name
      end

      def warning_checker
        utusemi_column_names.each do |new_column_name, origin_column_name|
          return if new_column_name != origin_column_name
          Rails.logger.warn "[Utusemi:WARNING] \"#{new_column_name}\" is duplicated in map(:#{utusemi_values[:type]})."
        end
      end

      def default_utusemi_type
        class_for_default_utusemi_type.model_name.singular.to_sym
      end

      def class_for_default_utusemi_type
        case self
        when ActiveRecord::Relation
          @klass
        when ActiveRecord::Base
          self.class
        else
          self
        end
      end

      def klass_utusemi_values
        return {} unless @klass
        utusemi_values = @klass.instance_variable_get(:@utusemi_values) || {}
        return {} unless utusemi_values[:flag]
        utusemi_values
      end
    end

    # 用途
    #   Utusemi.config.mapに設定したマッピングを意識せずに実装できるよう、
    #   デフォルト名による各カラムへのアクセスを可能にする
    #
    # 使用例
    #   Utusemi.config do
    #     map :product do
    #       name :title
    #     end
    #   end
    #
    #   product = Product.first
    #   product.name
    #   #=> NoMethodError: undefined method `name' for #<Product:...>
    #
    #   product.utusemi(:product).name
    #   #=> 'test product'
    #
    module InstanceMethods
      include Base

      def utusemi!(obj = nil, options = {})
        super.tap { utusemi_columns_mapper if obj.class.in? [Symbol, String] }
      end

      def changed
        return super unless utusemi_values[:flag]
        super + super.map { |column_name| unmapped_utusemi_column_name(column_name).to_s }
      end

      private

      def utusemi_columns_mapper
        utusemi_column_names.each_pair do |new_column_name, origin_column_name|
          next if new_column_name == origin_column_name
          # alias_attributeと同じことを、対象カラム名を動的に変更して行う
          define_getter_method(new_column_name, origin_column_name)
          define_setter_method(new_column_name, origin_column_name)
          define_predicate_method(new_column_name, origin_column_name)
          define_was_method(new_column_name, origin_column_name)
        end
      end

      def define_getter_method(column_name, origin_column_name)
        define_singleton_method(column_name) { send origin_column_name }
      end

      def define_setter_method(column_name, origin_column_name)
        define_singleton_method("#{column_name}=") { |value| send "#{origin_column_name}=", value }
      end

      def define_predicate_method(column_name, origin_column_name)
        define_singleton_method("#{column_name}?") { send "#{origin_column_name}?" }
      end

      def define_was_method(column_name, origin_column_name)
        define_singleton_method("#{column_name}_was") { send "#{origin_column_name}_was" }
      end

      def utusemi_for_association(name, association, options = {})
        utusemi_values = self.utusemi_values
        utusemi_values = self.class.utusemi_values unless utusemi_values[:flag]
        utusemi_flag = utusemi_values[:flag] || options[:force]
        return association unless utusemi_flag
        association.utusemi!(name.to_s.singularize, utusemi_values[:options])
      end
    end

    # 用途
    #   whereなどのArelチェインにおいて、Utusemi.config.mapに設定したマッピングを
    #   意識せずに実装できるよう、デフォルト名による各カラムへのアクセスを可能にする
    #
    # 使用例
    #   Product.utusemi(:product).where(name: "test")
    #   #=> [<products.titleが"test"であるレコード>]
    #
    module ActiveRecord
      module Base
        module ClassMethods
          include Utusemi::Core::Base

          case Rails::VERSION::MAJOR
          when 4
            delegate :utusemi, to: :all
          when 3
            delegate :utusemi, to: :scoped
          end
        end
      end

      module QueryMethods
        include Utusemi::Core::Base

        def build_where(opts = :chain, *rest)
          return super unless utusemi_values[:flag]
          if utusemi_values[:options][:times]
            opts_with_times(opts, utusemi_values[:options][:times]) { |opts_with_mapped| super(opts_with_mapped, *rest) }
          else
            super(opts_with_mapped_column_name(opts), *rest)
          end
        end

        def order(opts = nil, *rest)
          opts = opts_with_mapped_column_name(opts) if utusemi_values[:flag]
          super
        end

        private

        def opts_with_times(opts, times)
          1.upto(times).map do |index|
            yield opts_with_mapped_column_name(opts, index)
          end
        end

        def opts_with_mapped_column_name(opts, index = nil)
          case opts
          when Hash
            key_values = opts.map { |key, value| [mapped_utusemi_column_name(key.to_s, index), value] }.flatten(1)
            Hash[*key_values]
          when String, Symbol
            mapped_column_names_for_string(opts.to_s, index)
          else
            opts
          end
        end

        def mapped_column_names_for_string(string, index = nil)
          utusemi_column_names(index).each do |old_column_name, new_column_name|
            string.gsub!(/\b#{old_column_name}\b/, new_column_name.to_s)
          end
          string
        end
      end

      # Rails 3.x で scope に対してのカラムマッピングが正常に動作するようにするためのもの
      #
      # 原因
      #   scope 内の条件が unscoped { ... } 内で実行されるため、カラムマッピングを実施する為のフラグが
      #   引き継がれず、カラムマッピングが作動しない
      #
      # 対策
      #   scope メソッドでは unscoped { ... } の結果を Relation.new として再生成しているので
      #   relation メソッドを利用した際にカラムマッピング実施フラグがあればこれを継承するようにした
      #
      module RelationMethod
        def relation(*args, &block)
          utusemi_values = current_scope.try(:utusemi_values) || {}
          return super unless utusemi_values[:flag]
          super.utusemi(utusemi_values[:type], utusemi_values[:options])
        end
      end

      # Rails 3.x で関連モデルの named scope に対してのカラムマッピングが正常に動作するようにするためのもの
      #
      # 原因
      #   product.stocks.unsold のような named scope において、stocks は utusemi_values を所持していないため
      #   カラムマッピングが作動しない
      #
      # 対策
      #   stocks は呼び出し元である product を truthly_owner として所持しているので、
      #   これを見てカラムマッピングを実施するか否かを判別するようにした
      #
      module CollectionProxy
        def scoped(*args, &block)
          association = @association
          utusemi_values = association.truthly_owner.utusemi_values
          return super unless utusemi_values[:flag]
          super.utusemi!(association.klass.model_name.singular, utusemi_values[:options])
        end
      end

      module Relation
        # 用途
        #   utusemiメソッドを利用してレコードを検索した場合は
        #   Utusemi::Core#utusemiを個別呼び出さなくても済むようになる
        #
        # 使用例
        #   product = Product.utusemi(:product).where(name: 'test').first
        #   product.utusemi(:product).name
        #   #=> 'test' (= products.title)
        #
        #   こうなっていたコードが以下のようになる
        #
        #   product = Product.utusemi(:product).where(name: 'test').first
        #   product.name
        #   #=> true (= products.title)
        #
        def to_a
          return super unless utusemi_values[:flag]
          super.each { |record| record.utusemi!(utusemi_values[:type], utusemi_values[:options]) }
        end
      end

      module Base
        # 用途
        #   utusemiメソッドを利用後にレコードを作成した場合は
        #   Utusemi::Core#utusemiを個別呼び出さなくても済むようになる
        #
        # 使用例
        #   product = Product.utusemi(:product).new(name: 'test')
        #   product.name
        #   #=> 'test' (= products.title)
        #
        def initialize(*args, &block)
          case Rails::VERSION::MAJOR
          when 4
            current_scope = self.class.current_scope
          when 3
            current_scope = self.class.scoped
          end
          utusemi_values = current_scope.try(:utusemi_values) || {}
          utusemi_values = self.class.utusemi_values unless utusemi_values[:flag]
          utusemi!(utusemi_values[:type], utusemi_values[:options]) if utusemi_values[:flag]
          super
        end

        # 用途
        #   cloneでは浅いコピーしか行われず@utusemi_valuesの内容が
        #   書き変わってしまうので、これを解決するために@utusemi_valuesもdupする
        def initialize_copy(original_obj)
          @utusemi_values = original_obj.utusemi_values.dup
          super
        end

        # 用途
        #   association_cacheの影響でAssociation#ownerでclone前のインスタンスしか取得できないため
        #   別経路から実際の呼び出し元インスタンスを参照できるようにし、utusemi_valuesを取り出せるようにする
        def association(name)
          truthly_owner = self
          association = super
          association.singleton_class.send(:define_method, :truthly_owner) { truthly_owner }
          association
        end
      end

      # 用途
      #   関連モデルにカラムマッパを継承する
      #
      # 使用例
      #   class Product
      #     has_many :stocks
      #     ...
      #   end
      #   stock = Product.utusemi(:product).stocks.first
      #   stock.quantity
      #   #=> 10 (= stocks.units)
      #
      module Associations
        def scope(*args)
          utusemi_values = truthly_owner.utusemi_values
          return super unless utusemi_values[:flag]
          super.utusemi!(@reflection.klass.model_name.singular, utusemi_values[:options])
        end

        def load_target(*args)
          utusemi_values = truthly_owner.utusemi_values
          return super unless utusemi_values[:flag]
          super.each { |record| record.utusemi!(@reflection.klass.model_name.singular, utusemi_values[:options]) }
        end
      end

      module AssociationMethods
        def belongs_to(name, *args, &block)
          prepend_utusemi_association_reader_module(name)
          super
        end

        def has_one(name, *args, &block)
          prepend_utusemi_association_reader_module(name)
          super
        end

        def has_many(name, *args, &block)
          prepend_utusemi_association_reader_module(name)
          super
        end

        private

        def prepend_utusemi_association_reader_module(name)
          return if method_defined?(name)
          prepend build_utusemi_association_reader_module(name)
        end

        def build_utusemi_association_reader_module(name)
          wodule = Module.new
          wodule.class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{name}(*args, &block)
              association = super
              return unless association
              return association unless association.is_a? ActiveRecord::Base
              utusemi_for_association('#{name}'.to_sym, association)
            end
          EOS
          wodule
        end
      end
    end
  end
end
