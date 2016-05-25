require_relative 'db_connection'

class Relation
  def initialize(clase, conditions = Hash.new(""))
    @clase = clase
    @conditions = conditions
  end

  def all
    todos = @clase.parse_all(DBConnection.execute(<<-SQL))
      SELECT
        *
      FROM
        #{@clase.table_name}
      WHERE
        #{where_conditions}
    SQL
    @clase.reset_relation
    todos
  end

  def first
    hashesque = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{@clase.table_name}
      WHERE
        #{where_conditions}
      LIMIT
        1
     SQL
     premier = @clase.new(hashesque[0])
     @clase.reset_relation
     premier
  end

  def last
    hashesque = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{@clase.table_name}
      WHERE
        #{where_conditions}
      ORDER BY
        id DESC
      LIMIT
        1
     SQL
     ultimo = @clase.new(hashesque[0])
     @clase.reset_relation
     ultimo
  end

  def [](index)
    all[index]
  end

  def ==(array)
    all == array
  end

  def count
    hash_count = DBConnection.execute(<<-SQL)
      SELECT
        COUNT(*) AS length
      FROM
        #{@clase.table_name}
      WHERE
        #{where_conditions}
     SQL
     hash_count[0]["length"]
  end

  alias_method :length, :count

  def add_condition(type, param_string)
    @conditions[type] += " AND " unless @conditions[type].empty?
    @conditions[type] += param_string
  end

  def where_conditions
    @conditions[:where]
  end
end
