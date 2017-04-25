require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    return @columns_info if @columns_info
    cols = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
      LIMIT
        0
    SQL
    cols.map!(&:to_sym)
    @columns_info = cols
  end

  def self.finalize!
    self.columns.each do |el|
      define_method(el) do 
        attributes[el]
      end
      define_method("#{el}=") do |value|
        attributes[el] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name = self.name.tableize if @table_name.nil?
    @table_name
  end

  def self.all
    hashes = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    self.parse_all(hashes)
  end

  def self.parse_all(results)
    objects = []
    results.map do |result|
      objects << self.new(result)
    end
    objects
  end

  def self.find(id)
    one = DBConnection.execute(<<-SQL).first
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = #{id}
    SQL
    return nil if one.nil?
    self.new(one)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=", value)
    end
    
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |attr| self.send(attr) }
  end

  def insert
    col_names = self.class.columns.join(",")
    n = self.class.columns.count
    question_marks = (["?"]*n).join(",")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    update_col = self.class.columns.map {|attr| "#{attr} = ?" }.join(",")
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{update_col}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
