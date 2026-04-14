module OnboardOnRails
  class Configuration
    attr_accessor :user_class, :admin_auth, :user_attributes, :current_user_method, :accent_color

    def initialize
      @user_class = "User"
      @admin_auth = ->(controller) { true }
      @user_attributes = ->(user) { {} }
      @current_user_method = :current_user
      @accent_color = "#2d3436"
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
      hex = hex.delete("#")
      [hex[0..1].to_i(16), hex[2..3].to_i(16), hex[4..5].to_i(16)]
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
