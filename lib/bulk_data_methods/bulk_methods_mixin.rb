# MixIn used to extend ActiveRecord::Base classes implementing bulk insert and update operations
# through {#create_many} and {#update_many}.
# @example to use:
#   class Company < ActiveRecord::Base
#     extend BulkMethodsMixin
#   end
#
module BulkMethodsMixin
  # exception thrown when row data structures are inconsistent between rows in single call to {#create_many} or {#update_many}
  class BulkUploadDataInconsistent < StandardError
    def initialize(model, table_name, expected_columns, found_columns, while_doing)
      super("#{model.name}: for table: #{table_name}; #{expected_columns} != #{found_columns}; #{while_doing}")
    end
  end

  # BULK creation of many rows
  #
  # When :statement_builder option is GenericBulkInsertStatementBuilder:
  # @example no options used
  #   rows = [
  #         { :name => 'Keith', :salary => 1000 },
  #         { :name => 'Alex', :salary => 2000 }
  #   ]
  #   Employee.create_many(rows)
  #
  # @example with :returning option to returns key value
  #   rows = [
  #         { :name => 'Keith', :salary => 1000 },
  #         { :name => 'Alex', :salary => 2000 }
  #   ]
  #   options = { :returning => [:id] }
  #   Employee.create_many(rows, options)
  #   [#<Employee id: 1>, #<Employee id: 2>]
  #
  # @example with :slice_size option (will generate two insert queries)
  #   rows = [
  #         { :name => 'Keith', :salary => 1000 },
  #         { :name => 'Alex', :salary => 2000 },
  #         { :name => 'Mark', :salary => 3000 }
  #   ]
  #   options = { :slice_size => 2 }
  #   Employee.create_many(rows, options)
  #
  # @param [Array<Hash>] rows ([]) data to be inserted into database
  # @param [Hash] options ({}) options for bulk inserts
  # @option options [Class] :statement_builder determines from which class will called create_many method
  # @option options [Integer] :slice_size (1000) how many records will be created in a single SQL query
  # @option options [Boolean] :check_consistency (true) ensure some modicum of sanity on the incoming dataset, specifically: does each row define the same set of key/value pairs
  # @option options [Array or String] :returning (nil) list of fields to return.
  # @return [Array<Hash>] rows returned from DB as option[:returning] requests
  # @raise [BulkUploadDataInconsistent] raised when key/value pairs between rows are inconsistent (check disabled with option :check_consistency)
  #
  # When :statement_builder option is PostgresCopyStatementBuilder:
  # @example no options used
  #   Employee.create_many('path_to_file')
  #
  # @example with :delimiter option set as ';'
  #   Employee.create_many('path_to_file', { :delimiter => ';' })
  #
  # @param [String] rows path to file with data
  # @option options [Array<String>] :column_names names of each column which should be set
  # @option options [Class] :statement_builder determines from which class will called create_many method
  # @option options [String] :delimiter specifies the character that separates columns within each row (line) of the file. The default is a tab character in text format,
  #   a comma in CSV format
  # @option options [String] :null specifies the string that represents a null value. The default is \N (backslash-N) in text format, and an unquoted empty string in CSV format
  # @option options [Boolean] :header specifies that the file contains a header line with the names of each column in the file, the first line is ignored
  # @option options [String] :quote specifies the quoting character to be used when a data value is quoted. The default is double-quote. This must be a single one-byte character
  # @option options [String] :escape specifies the character that should appear before a data character that matches the QUOTE value.
  #   The default is the same as the QUOTE value (so that the quoting character is doubled if it appears in the data)
  # @option options [Array<String>] :force_not_null do not match the specified columns' values against the null string. In the default case where the null string is empty,
  #   this means that empty values will be read as zero-length strings rather than nulls, even when they are not quoted
  # @option options [String] :encoding specifies that the file is encoded in the encoding_name. If this option is omitted, the current client encoding is used
  # @option options [String] :file_format ('CSV' or 'TEXT') format of loaded file
  def create_many(rows, options = {})
    return [] if rows.blank?
    options = BulkMethodsMixin.set_options(options)
    options[:statement_builder].create_many(rows, options, self)
  end

  #
  # BULK updates of many rows
  #
  # @return [Array<Hash>] rows returned from DB as option[:returning] requests
  # @raise [BulkUploadDataInconsistent] raised when key/value pairs between rows are inconsistent (check disabled with option :check_consistency)
  # @param [Hash] options ({}) options for bulk inserts
  # @option options [Integer] :slice_size (1000) how many records will be created in a single SQL query
  # @option options [Boolean] :check_consistency (true) ensure some modicum of sanity on the incoming dataset, specifically: does each row define the same set of key/value pairs
  # @option options [Array] :returning (nil) list of fields to return.
  # @option options [String] :returning (nil) single field to return.
  #
  # @overload update_many(rows = [], options = {})
  #   @param [Array<Hash>] rows ([]) data to be updated
  #   @option options [String] :set_array (built from first row passed in) the set clause
  #   @option options [String] :where ('"#{table_name}.id = datatable.id"') the where clause
  #
  # @overload update_many(rows = {}, options = {})
  #   @param [Hash<Hash, Hash>] rows ({}) data to be updated
  #   @option options [String] :set_array (built from the values in the first key/value pair of `rows`) the set clause
  #   @option options [String] :where (built from the keys in the first key/value pair of `rows`) the where clause
  #
  # @example using "set_array" to add the value of "salary" to the specific employee's salary the default where clause matches IDs so, it works here.
  #   rows = [
  #     { :id => 1, :salary => 1000 },
  #     { :id => 10, :salary => 2000 },
  #     { :id => 23, :salary => 2500 }
  #   ]
  #   options = { :set_array => '"salary = datatable.salary"' }
  #   Employee.update_many(rows, options)
  #
  # @example using where clause to match salary.
  #   rows = [
  #     { :id => 1, :salary => 1000, :company_id => 10 },
  #     { :id => 10, :salary => 2000, :company_id => 12 },
  #     { :id => 23, :salary => 2500, :company_id => 5 }
  #   ]
  #   options = {
  #     :set_array => '"company_id = datatable.company_id"',
  #     :where => '"#{table_name}.salary = datatable.salary"'
  #   }
  #   Employee.update_many(rows, options)
  #
  # @example setting where clause to the KEY of the hash passed in and the set_array is generated from the VALUES
  #   rows = {
  #     { :id => 1 } => { :salary => 100000, :company_id => 10 },
  #     { :id => 10 } => { :salary => 110000, :company_id => 12 },
  #     { :id => 23 } => { :salary => 90000, :company_id => 5 }
  #   }
  #   Employee.update_many(rows)
  #
  # @note Remember that you should probably set updated_at using "updated = datatable.updated_at"
  #   or "updated_at = now()" in the set_array if you want to follow
  #   the standard active record model for time columns (and you have an updated_at column)
  def update_many(rows, options = {})
    return [] if rows.blank?
    options = BulkMethodsMixin.set_options(options)
    if rows.is_a?(Hash)
      options[:where] = '"' + rows.keys[0].keys.map{|key| '#{table_name}.' + "#{key} = datatable.#{key}"}.join(' and ') + '"'
      options[:set_array] = '"' + rows.values[0].keys.map{|key| "#{key} = datatable.#{key}"}.join(',') + '"' unless options[:set_array]
      r = []
      rows.each do |key,value|
        r << key.merge(value)
      end
      rows = r
    end
    unless options[:set_array]
      column_names =  rows[0].keys
      columns_to_remove = [:id]
      columns_to_remove += partition_keys.flatten.map{|k| k.to_sym} if respond_to?(:partition_keys)
      options[:set_array] = '"' + (column_names - columns_to_remove).map{|cn| "#{cn} = datatable.#{cn}"}.join(',') + '"'
    end
    returning_clause = ""
    if options[:returning]
      if options[:returning].is_a?(Array)
        returning_list = options[:returning].map{|r| '#{table_name}.' + r.to_s}.join(',')
      else
        returning_list = options[:returning]
      end
      returning_clause = "\" returning #{returning_list}\""
    end
    options[:where] = '"#{table_name}.id = datatable.id"' unless options[:where]

    returning = []

    rows.group_by do |row|
      respond_to?(:partition_table_name) ? partition_table_name(*partition_key_values(row)) : table_name
    end.each do |table_name, rows_for_table|
      column_names = rows_for_table[0].keys.sort{|a,b| a.to_s <=> b.to_s}
      rows_for_table.each_slice(options[:slice_size]) do |update_slice|
        datatable_rows = []
        update_slice.each_with_index do |row,i|
          if options[:check_consistency]
            row_column_names = row.keys.sort{|a,b| a.to_s <=> b.to_s}
            if column_names != row_column_names
              raise BulkUploadDataInconsistent.new(self, table_name, column_names, row_column_names, "while attempting to build update statement")
            end
          end
          datatable_rows << row.map do |column_name,column_value|
            column_name = column_name.to_s
            columns_hash_value = columns_hash[column_name]
            if i == 0
              "#{quote_value(column_value, columns_hash_value)}::#{columns_hash_value.sql_type} as #{column_name}"
            else
              quote_value(column_value, columns_hash_value)
            end
          end.join(',')
        end
        datatable = datatable_rows.join(' union select ')

        sql_update_string = <<-SQL
          update #{table_name} set
            #{eval(options[:set_array])}
          from
          (select
            #{datatable}
          ) as datatable
          where
            #{eval(options[:where])}
          #{eval(returning_clause)}
        SQL
        returning += find_by_sql(sql_update_string)
      end
    end

    return returning
  end

  #
  # Merge default options with the custom options
  #
  # @option options [Class] :statement_builder determines from which class will called create_many method
  # @option options [Integer] :slice_size (1000) how many records will be created in a single SQL query
  # @option options [Boolean] :check_consistency (true) ensure some modicum of sanity on the incoming dataset, specifically: does each row define the same set of key/value pairs
  # @option options [Array or String] :returning (nil) list of fields to return
  # @option options [String] :file_format ('CSV' or 'TEXT') format of loaded file
  # @return [<Hash>] options
  def BulkMethodsMixin.set_options(options)
    options[:statement_builder] = options[:statement_builder].try(:constantize) || BulkDataMethods.statement_builder
    options[:slice_size] ||= BulkDataMethods.slice_size
    options[:check_consistency] = BulkDataMethods.check_consistency unless options.has_key?(:check_consistency)
    options[:returning] ||= BulkDataMethods.returning
    options[:file_format] ||= BulkDataMethods.file_format

    options
  end

end
