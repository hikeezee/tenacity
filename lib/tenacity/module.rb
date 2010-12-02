require 'active_support/inflector'

module Tenacity
  def self.included(model)
    raise "Tenacity does not support the ORM used by #{model}" unless model.respond_to?(:_t_find)
    model.extend(ClassMethods)
  end 

  module ClassMethods
    def t_belongs_to(association_id, args={})
      redefine_method(association_id) do
      end

      redefine_method("#{association_id}=") do
      end

      redefine_method("#{association_id}_id") do
      end
    end

    def t_has_many(association_id, args={})
      redefine_method(association_id) do
        []
      end

      redefine_method("#{association_id}=") do
      end

      redefine_method("#{ActiveSupport::Inflector.singularize(association_id.to_s)}_ids") do
      end

      redefine_method("#{ActiveSupport::Inflector.singularize(association_id.to_s)}_ids=") do
      end
    end
  end

end
