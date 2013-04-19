module BulkDataMethods
  class PostgresCopyStatementBuilder

    # BULK creation of many rows from CSV file
    #
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
    # @option options [String] :file_format ('CSV' or 'TEXT' or 'BINARY') format of loaded file
    def self.create_many(path, options, obj)
      return [] unless File.exist?(path)

      column_names = if options[:column_names] && options[:column_names].is_a?(Array)
        options[:column_names]
      else
        obj.column_names
      end
      column_names = (column_names - ["id"]).join(',')

      case options[:file_format].to_s.upcase
        when "CSV"
          copy_opt = ["CSV"]
          copy_opt << ["HEADER"] if options[:header]
          copy_opt << ["QUOTE", "'#{options[:quote]}'"] if options[:quote]
          copy_opt << ["ESCAPE", "'#{options[:escape]}'"] if options[:escape]
          if options[:force_not_null] && options[:force_not_null].is_a?(Array)
            copy_opt << ["FORCE NOT NULL", "#{options[:force_not_null].join(',')}"]
          end
        when "BINARY"
          copy_opt = ["BINARY"]
        else
          copy_opt = ["(FORMAT TEXT)"]
      end

      unless copy_opt.first == "BINARY"
        copy_opt << ["DELIMITER", "'#{options[:delimiter]}'"] if options[:delimiter]
        copy_opt << ["NULL", "'#{options[:null]}'"] if options[:null]
        copy_opt << ["ENCODING", "'#{options[:encoding]}'"] if options[:encoding]
      end

      sql_copy_string = <<-SQL
        COPY #{obj.table_name}(#{(column_names)}) FROM '#{path}' WITH #{copy_opt.join(' ')};
      SQL

      begin
        ActiveRecord::Base.transaction do
          obj.find_by_sql(sql_copy_string)
        end
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.info "Error happened #{e}"
      end

    end

  end
end