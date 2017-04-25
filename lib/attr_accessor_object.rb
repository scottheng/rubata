class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      instance_var_name = "@#{name}".to_sym
      define_method(name) do 
        instance_variable_get(instance_var_name)
      end
      
      define_method("#{name}=") do |value|
        instance_variable_set(instance_var_name, value)
      end
    end

  end
end
