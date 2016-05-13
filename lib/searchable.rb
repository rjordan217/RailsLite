require_relative 'db_connection'
require_relative 'relation'

module Searchable
  def where(params)
    unless params.is_a?(String)
      cols = params.keys
      vals = nest_strings(params.values)
      to_map = cols.zip(vals)
      joined_pairs = to_map.map do |pair|
        pair.join(" = ")
      end
      where_line = joined_pairs.join(" AND ")
    else
      where_line = params
    end
    relation.add_condition(:where, where_line)
    relation
  end
end
