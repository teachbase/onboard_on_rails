module OnboardOnRails
  class Configuration
    attr_accessor :user_class, :admin_auth, :current_user_method, :user_locale, :resolve_context, :default_font
    attr_reader :registered_attributes

    def accent_color=(value)
      hex_to_rgb(value)
      @accent_color = value
    end

    attr_reader :accent_color

    def initialize
      @user_class = "User"
      @admin_auth = ->(controller) { true }
      @current_user_method = :current_user
      @accent_color = "#2d3436"
      @default_font = nil
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

    def accent_color_dark
      adjust_brightness(accent_color, -0.15)
    end

    def accent_color_light
      adjust_brightness(accent_color, 0.40)
    end

    def accent_color_rgba(alpha)
      r, g, b = hex_to_rgb(accent_color)
      "rgba(#{r}, #{g}, #{b}, #{alpha})"
    end

    private

    def hex_to_rgb(hex)
      normalized = hex.delete("#")
      raise ArgumentError, "Invalid hex color: #{hex}" unless normalized.match?(/\A[0-9a-fA-F]{6}\z/)
      [normalized[0..1].to_i(16), normalized[2..3].to_i(16), normalized[4..5].to_i(16)]
    end

    def adjust_brightness(hex, factor)
      r, g, b = hex_to_rgb(hex)
      if factor > 0
        r = (r + (255 - r) * factor).round.clamp(0, 255)
        g = (g + (255 - g) * factor).round.clamp(0, 255)
        b = (b + (255 - b) * factor).round.clamp(0, 255)
      else
        r = (r * (1 + factor)).round.clamp(0, 255)
        g = (g * (1 + factor)).round.clamp(0, 255)
        b = (b * (1 + factor)).round.clamp(0, 255)
      end
      "#%02x%02x%02x" % [r, g, b]
    end
  end
end
