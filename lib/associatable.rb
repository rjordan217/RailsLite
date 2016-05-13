require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || name.to_s.dup.concat("_id").to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.dup.camelize
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || self_class_name.to_s.underscore.concat("_id").to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.classify
  end
end

module Associatable

  def get_table_name(association)
    begin
      association.class_name.constantize.table_name
    rescue
      association.class_name.tableize
    end
  end

  def belongs_to(name, options = {})
    propriete = BelongsToOptions.new(name, options)
    @assoc_options ||= {}
    @assoc_options[name] = propriete
    define_method(name) do
      joining = self.class.get_table_name(propriete)
      propriete.class_name
               .constantize
               .parse_all(DBConnection.execute(<<-SQL)).first
        SELECT
          #{joining}.*
        FROM
          #{self.class.table_name}
        JOIN
          #{joining} ON #{joining}.#{propriete.primary_key} = #{self.class.table_name}.#{propriete.foreign_key}
        WHERE
          #{self.class.table_name}.#{propriete.primary_key} = #{self.id}
      SQL
    end
  end

  def has_many(name, options = {})
    dueno = HasManyOptions.new(name, self.to_s, options)
    @assoc_options ||= {}
    @assoc_options[name] = dueno
    define_method(name) do
      joining = self.class.get_table_name(dueno)
      dueno.class_name
           .constantize
           .parse_all(DBConnection.execute(<<-SQL))
        SELECT
          #{joining}.*
        FROM
          #{self.class.table_name}
        JOIN
          #{joining} ON #{joining}.#{dueno.foreign_key} = #{self.class.table_name}.#{dueno.primary_key}
        WHERE
          #{self.class.table_name}.#{dueno.primary_key} = #{self.id}
      SQL
    end
  end
end

class SQLObject
  extend Associatable
end
