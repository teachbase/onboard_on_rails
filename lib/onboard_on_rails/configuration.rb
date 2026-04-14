module OnboardOnRails
  class Configuration
    attr_accessor :user_class, :admin_auth, :current_user_method, :user_locale
    attr_reader :registered_attributes

    def initialize
      @user_class = "User"
      @admin_auth = ->(controller) { true }
      @current_user_method = :current_user
      @user_locale = ->(user) { "ru" }
      @registered_attributes = {}
    end

    def register_attribute(key, type:, label:, description: nil, values: nil, &block)
      raise ArgumentError, "Block required for attribute #{key}" unless block_given?

      @registered_attributes[key] = AttributeDefinition.new(
        key: key, type: type, label: label, description: description, values: values, resolver: block
      )
    end

    def resolve_attributes(user)
      registered_attributes.each_with_object({}) do |(key, attr_def), hash|
        hash[key] = attr_def.resolver.call(user)
      end
    end

    def attributes_schema
      registered_attributes.values.map do |attr_def|
        { key: attr_def.key, type: attr_def.type, label: attr_def.label,
          description: attr_def.description, values: attr_def.values }
      end
    end
  end
end
