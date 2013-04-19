module BulkDataMethods
  class Configuration
    attr_accessor :statement_builder, :slice_size, :check_consistency, :returning, :file_format

    def initialize
      @statement_builder = "::BulkDataMethods::GenericBulkInsertStatementBuilder"
      @slice_size = 1000
      @file_format = 'CSV'
      @check_consistency = true
      @returning = nil
    end

  end
end