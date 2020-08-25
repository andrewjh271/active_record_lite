require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_clause = params.keys.map { |attr| "#{attr} = ?" }.join(' AND ')
    query = <<-SQL
      SELECT *
      FROM #{table_name}
      WHERE #{where_clause}
    SQL
    result = DBConnection.execute(query, *params.values)
    parse_all(result)
  end
end

class SQLObject
  extend Searchable
end
