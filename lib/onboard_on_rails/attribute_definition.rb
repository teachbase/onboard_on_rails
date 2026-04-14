module OnboardOnRails
  AttributeDefinition = Struct.new(:key, :type, :label, :description, :values, :resolver, keyword_init: true)
end
