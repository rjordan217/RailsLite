require_relative 'db_connection'
require_relative 'searchable'
require_relative 'validatable'
require_relative 'associatable'
require 'hooks'
require 'active_support/inflector'

class SQLObject
  extend Searchable
  extend Associatable

  include Hooks
  define_hook :before_save

  include Validatable

  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT
        *
      FROM
        #{self.table_name};
    SQL
    @columns
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) { attributes[column] }
      define_method("#{column}=") {|value| attributes[column] = value}
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
    @table_name
  end

  def self.all
    parse_all(DBConnection.execute(<<-SQL))
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
  end

  def self.parse_all(results)
    results.map {|individual| self.new(individual)}
  end

  def self.find(id)
    table = self.table_name
    parse_all(DBConnection.execute(<<-SQL)).first
      SELECT
        *
      FROM
        #{table}
      WHERE
        #{table}.id = #{id}
    SQL
  end

  def self.relation
    @relation ||= Relation.new(self)
  end

  def self.reset_relation
    @relation = Relation.new(self)
  end

  def self.nest_strings(arr)
    arr.map do |atr|
      if atr.is_a?(String)
        atr.insert(0,"\'")
        atr.insert(-1,"\'")
      else
        atr
      end
    end
  end

  def initialize(params = {})
    self.class.finalize!
    params.each do |k,v|
      if self.class.columns.include?(k.to_sym)
        self.send("#{k}=",v)
      else
        raise "unknown attribute '#{k}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
    @attributes
  end

  def attribute_values
    @attributes.values
  end

  def insert
    atributos = attribute_values.map do |atr|
      if atr.is_a?(String)
        atr.insert(0,"\'")
        atr.insert(-1,"\'")
      else
        atr
      end
    end
    table_name = self.class.table_name
    string_of_attrs = attributes.keys.join(",")
    string_safe_vals = atributos.join(",")
    DBConnection.execute(<<-SQL)
      INSERT INTO
        #{table_name} (#{string_of_attrs})
      VALUES
        (#{string_safe_vals})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    attr_wo_id = attributes.dup
    attr_wo_id.delete(:id)
    cols = attr_wo_id.keys
    vals = nest_strings(attr_wo_id.values)
    to_map = cols.zip(vals)
    joined_pairs = to_map.map do |pair|
      pair.join("=")
    end
    args = [
      self.class.table_name,
      joined_pairs.join(","),
      self.class.table_name,
      self.id
    ]
    DBConnection.execute(<<-SQL)
      UPDATE
        #{args[0]}
      SET
        #{args[1]}
      WHERE
        #{args[2]}.id = #{args[3]};
    SQL
  end

  def save
    self.run_hook :before_save
    if errors.full_messages.empty?
      if id.nil?
        insert
      else
        update
      end
    else
      puts "Validation failed"
    end
  end

  private
  def nest_strings(arr)
    self.class.nest_strings(arr)
  end
end
