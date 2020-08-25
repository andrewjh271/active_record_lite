require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @primary_key = options[:primary_key] || :id
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @class_name = options[:class_name] || name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @primary_key = options[:primary_key] || :id
    @foreign_key = options[:foreign_key] || "#{self_class_name.underscore}_id".to_sym
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    association = BelongsToOptions.new(name, options)
    assoc_options[name] = association
    define_method(name) do
      association
        .model_class
        .where(association.primary_key => self.send(association.foreign_key))
        .first
    end
  end

  def has_many(name, options = {})
    association = HasManyOptions.new(name, self.to_s, options)
    assoc_options[name] = association
    define_method(name) do
      association
        .model_class
        .where(association.foreign_key => self.send(association.primary_key))
    end
  end

  def assoc_options
    @assoc_options || @assoc_options = {}
  end
end

class SQLObject
  extend Associatable
end
