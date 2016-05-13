require_relative 'associatable'

module Associatable
  
  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)
    first_assoc = self.assoc_options[through_name]
    through_assoc = through_name.to_s.classify.constantize.assoc_options[source_name]
    final_table = get_table_name(through_assoc)
    through_table = get_table_name(first_assoc)
    define_method(name) do
      final_table.classify
                 .constantize
                 .parse_all(DBConnection.execute(<<-SQL)).first
      SELECT
        #{final_table}.*
      FROM
        #{through_table}
      JOIN
        #{final_table} ON #{through_table}.#{through_assoc.foreign_key} = #{final_table}.#{through_assoc.primary_key}
      WHERE
        #{through_table}.#{first_assoc.primary_key} = #{self.send(first_assoc.foreign_key)}
      SQL
    end
  end
end
