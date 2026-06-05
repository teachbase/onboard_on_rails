require_relative "lib/onboard_on_rails/version"

Gem::Specification.new do |spec|
  spec.name        = "onboard_on_rails"
  spec.version     = OnboardOnRails::VERSION
  spec.authors     = ["Aleksandr Svajkin"]
  spec.summary     = "Universal onboarding tour engine for Rails"
  spec.description = "A Rails engine that adds an admin panel for creating and managing onboarding tours with visual element picker, advanced targeting, and A/B testing."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "csv"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "pg"
end
