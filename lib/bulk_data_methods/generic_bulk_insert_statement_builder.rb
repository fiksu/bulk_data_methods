module BulkDataMethods
  class GenericBulkInsertStatementBuilder

    # BULK creation of many rows
    #
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
    # @option options [Integer] :slice_size (1000) how many records will be created in a single SQL query
    # @option options [Boolean] :check_consistency (true) ensure some modicum of sanity on the incoming dataset, specifically: does each row define the same set of key/value pairs
    # @option options [Array or String] :returning (nil) list of fields to return.
    # @param [Class] obj class which calls create_many method
    # @return [Array<Hash>] rows returned from DB as option[:returning] requests
    # @raise [BulkUploadDataInconsistent] raised when key/value pairs between rows are inconsistent (check disabled with option :check_consistency)

    def self.create_many(rows, options, obj)
      returning_clause = ""
      if options[:returning]
        if options[:returning].is_a? Array
          returning_list = options[:returning].join(',')
        else
          returning_list = options[:returning]
        end
        returning_clause = " returning #{returning_list}"
      end
      returning = []

      created_at_value = Time.zone.now

      num_sequences_needed = rows.reject{|r| r[:id].present?}.length
      if num_sequences_needed > 0
        row_ids = obj.connection.next_sequence_values(obj.sequence_name, num_sequences_needed)
      else
        row_ids = []
      end
      rows.each do |row|
        # set the primary key if it needs to be set
        row[:id] ||= row_ids.shift
      end.each do |row|
        # set :created_at if need be
        row[:created_at] ||= created_at_value
      end.group_by do |row|
        obj.respond_to?(:partition_table_name) ? obj.partition_table_name(*obj.partition_key_values(row)) : obj.table_name
      end.each do |table_name, rows_for_table|
        column_names = rows_for_table[0].keys.sort{ |a,b| a.to_s <=> b.to_s }
        sql_insert_string = "insert into #{table_name} (#{column_names.join(',')}) values "
        rows_for_table.map do |row|
          if options[:check_consistency]
            row_column_names = row.keys.sort{ |a,b| a.to_s <=> b.to_s }
            if column_names != row_column_names
              raise ::BulkMethodsMixin::BulkUploadDataInconsistent.new(self, table_name, column_names, row_column_names, "while attempting to build insert statement")
            end
          end
          column_values = column_names.map do |column_name|
            obj.quote_value(row[column_name], obj.columns_hash[column_name.to_s])
          end.join(',')
          "(#{column_values})"
        end.each_slice(options[:slice_size]) do |insert_slice|
          returning += obj.find_by_sql(sql_insert_string + insert_slice.join(',') + returning_clause)
        end
      end

      returning
    end

  end
end