require_relative 'db_connection'
require 'active_support/inflector'
require 'pry'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns || @columns = DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT *
      FROM #{table_name}
      LIMIT 0
    SQL
  end

  def self.finalize!
    columns.each do |name|
      define_method(name) { self.attributes[name] }
      define_method("#{name}=") { |value| self.attributes[name] = value }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    hashes = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL
    parse_all(hashes)
  end

  def self.parse_all(results)
    results.map { |hash| self.new(hash) }
  end

  def self.find(id)
    hash = DBConnection.execute(<<-SQL, id).first
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
    self.new(hash) if hash
  end

  def initialize(params = {})
    params.each do |key, value|
      key = key.to_sym
      raise ("unknown attribute '#{key}'") unless self.respond_to?(key)

      self.send("#{key}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |attribute| self.send(attribute) }
  end

  def insert
    columns = self.class.columns
    question_marks = (['?'] * columns.length).join(', ')
    query = <<-SQL
      INSERT INTO
          #{self.class.table_name} (#{columns.join(', ')})
        VALUES
          (#{question_marks})
    SQL
    DBConnection.execute(query, *attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns.drop(1)
    set_clause = columns.map { |attr| "#{attr} = ?" }.join(', ')
    query = <<-SQL
      UPDATE #{self.class.table_name}
      SET #{set_clause}
      WHERE id = ?
    SQL
    DBConnection.execute(query, *attribute_values.drop(1), self.id)
  end

  def save
    self.id ? update : insert
  end
end
