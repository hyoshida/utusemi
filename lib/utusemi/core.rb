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
        @utusemi_values ||= {}
      end

      def utusemi(obj = nil, options = {})
        clone.utusemi!(obj, options)
      end

      def utusemi!(obj = nil, options = {})
        obj = true if obj.nil?
        utusemi_values[:flag] = obj ? true : false
        utusemi_values[:type] = obj.to_sym if obj.class.in? [Symbol, String]
        utusemi_values[:options] = options
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

      def eigenclass
        class << self; self; end
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

      def utusemi_columns_mapper
        utusemi_column_names.keys.each do |column_name|
          # alias_attributeと同じことを、対象カラム名を動的に変更して行う
          define_getter_method(column_name)
          define_setter_method(column_name)
          define_predicate_method(column_name)
          define_was_method(column_name)
        end
      end

      def changed
        return super unless utusemi_values[:flag]
        super + super.map { |column_name| unmapped_utusemi_column_name(column_name).to_s }
      end

      private

      def define_getter_method(column_name)
        target_column_name = mapped_utusemi_column_name(column_name)
        define_singleton_method(column_name) { send target_column_name }
      end

      def define_setter_method(column_name)
        target_column_name = mapped_utusemi_column_name(column_name)
        define_singleton_method("#{column_name}=") { |value| send "#{target_column_name}=", value }
      end

      def define_predicate_method(column_name)
        target_column_name = mapped_utusemi_column_name(column_name)
        define_singleton_method("#{column_name}?") { send "#{target_column_name}?" }
      end

      def define_was_method(column_name)
        target_column_name = mapped_utusemi_column_name(column_name)
        define_singleton_method("#{column_name}_was") { send "#{target_column_name}_was" }
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

        def utusemi!(obj = nil, options = {})
          super.tap { warning_checker unless Rails.env.production? }
        end

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

        def warning_checker
          utusemi_column_names.each do |old_column_name, new_column_name|
            return if old_column_name != new_column_name
            Rails.logger.warn "[Utusemi:WARNING] #{old_column_name} is duplicated in Utusemi::Engine.config.#{utusemi_values[:type]}_columns."
          end
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
          return super unless current_scope
          return super unless current_scope.utusemi_values
          return super unless current_scope.utusemi_values[:flag]
          super.utusemi(current_scope.utusemi_values[:type], utusemi_values[:options])
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
          utusemi_values = self.utusemi_values
          utusemi_values = @klass.utusemi_values unless utusemi_values[:flag]
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
          eigenclass = class << association; self; end
          eigenclass.send(:define_method, :truthly_owner) { truthly_owner }
          association
        end
      end

      # 用途
      #   関連モデルにカラムマッパを継承する
      #
      # 使用例
      #   class Product
      #     has_many :stocks, utusemi: true
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
          super.utusemi!(@reflection.name.to_s.singularize, utusemi_values[:options])
        end

        def load_target(*args)
          utusemi_values = truthly_owner.utusemi_values
          return super unless utusemi_values[:flag]
          super.each { |record| record.utusemi!(@reflection.name.to_s.singularize, utusemi_values[:options]) }
        end
      end

      module AssociationMethods
        def belongs_to(name, *args)
          utusemi_association(:belongs_to, name, *args) { |*a| super(*a) }
        end

        def has_one(name, *args)
          utusemi_association(:has_one, name, *args) { |*a| super(*a) }
        end

        def has_many(name, *args)
          utusemi_association(:has_many, name, *args) { |*a| super(*a) }
        end

        private

        def check_deplicated_association_warning(association_type, name, scope)
          return unless method_defined?(name)
          return unless method_defined?("#{name}_with_utusemi")
          return if scope.try(:[], :utusemi)
          Rails.logger.warn "[Utusemi:WARNING] \"#{association_type} :#{name}\" is duplicated in #{self.name}."
        end

        def utusemi_association(association_type, name, *args)
          if args.empty?
            yield name, *args
            return define_utusemi_association_reader(name)
          end
          scope = args.shift
          check_deplicated_association_warning(association_type, name, scope)
          utusemi_flag = scope.try(:delete, :utusemi)
          scope = utusemi_association_scope(association_type, name, scope) if utusemi_flag
          yield name, scope, *args if !utusemi_flag || !method_defined?(name)
          define_utusemi_association_reader(name, utusemi_flag => true)
        end

        def utusemi_association_scope(method_name, name, scope)
          utusemi_map = Utusemi.config.map(name.to_s.singularize)
          default_scope = { class_name: utusemi_map.class_name }
          default_scope[:foreign_key] = utusemi_map.foreign_key if method_name == :belongs_to
          default_scope.merge(scope)
        end

        def define_utusemi_association_reader(name, options = {})
          return if method_defined?("#{name}_with_utusemi")
          define_method "#{name}_with_utusemi" do |*args|
            association = send("#{name}_without_utusemi", *args)
            return unless association
            return association unless association.is_a? ActiveRecord::Base
            utusemi_for_association(name, association, options)
          end
          alias_method_chain name, :utusemi
        end
      end
    end
  end
end
