require "bulk_data_methods/engine"
require 'bulk_data_methods/configuration'
require "bulk_data_methods/version"
require "bulk_data_methods/bulk_methods_mixin"
require "bulk_data_methods/monkey_patch_postgres"
require "bulk_data_methods/generic_bulk_insert_statement_builder"
require "bulk_data_methods/postgres_copy_statement_builder"

module BulkDataMethods

  class << self

    def configuration
      @configuration ||= Configuration.new
    end

    def statement_builder
      configuration.statement_builder.constantize
    end

    def statement_builder=(statement_builder)
      configuration.statement_builder = statement_builder
    end

    def slice_size
      configuration.slice_size
    end

    def slice_size=(slice_size)
      configuration.slice_size = slice_size
    end

    def check_consistency
      configuration.check_consistency
    end

    def check_consistency=(check_consistency)
      configuration.check_consistency = check_consistency
    end

    def returning
      configuration.returning
    end

    def returning=(returning)
      configuration.returning = returning
    end

    def file_format
      configuration.file_format
    end

    def file_format=(file_format)
      configuration.file_format = file_format
    end

  end

end
