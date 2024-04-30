require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    # this way has one extra query
    # define_method(name) do
    #   self.send(through_name).send(source_name)
    # end

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      source_table = source_options.table_name
      through_table = through_options.table_name

      source_pk = source_options.primary_key
      source_fk = source_options.foreign_key
      through_pk = through_options.primary_key
      through_fk = through_options.foreign_key

      query = (<<-SQL)
        SELECT #{source_table}.*
        FROM #{source_table}
        INNER JOIN #{through_table}
          ON #{through_table}.#{source_fk} = #{source_table}.#{source_pk}
        WHERE #{through_table}.#{through_pk} = #{self.send(through_fk)}
      SQL

      result = DBConnection.execute(query)
      source_options.model_class.parse_all(result).first
    end
  end
end
