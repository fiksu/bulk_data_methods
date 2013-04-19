require 'spec_helper'
require "#{File.dirname(__FILE__)}/../support/tables_spec_helper"

describe "BulkMethodsMixin" do
  include TablesSpecHelper

  before do
    class Employee < ActiveRecord::Base
      extend BulkMethodsMixin
    end
    create_tables
  end

  describe "create_many" do

    context "when call method with empty rows" do
      it "returns empty array" do
        Employee.create_many("").should == []
      end
    end # when call method with empty rows

    context "when call method with the :statement_builder = '::BulkDataMethods::GenericBulkInsertStatementBuilder'" do
      it "receives BulkDataMethods::GenericBulkInsertStatementBuilder.create_many method" do
        ::BulkDataMethods::GenericBulkInsertStatementBuilder.should_receive(:create_many)
        Employee.create_many(
                              [{ :name => 'Keith', :company_id => 2 }],
                              :statement_builder => '::BulkDataMethods::GenericBulkInsertStatementBuilder'
                            )
      end
    end # when call method with the :statement_builder = '::BulkDataMethods::GenericBulkInsertStatementBuilder'

    context "when call method with the :statement_builder = '::BulkDataMethods::PostgresCopyStatementBuilder'" do
      it "receives BulkDataMethods::PostgresCopyStatementBuilder.create_many method" do
        ::BulkDataMethods::PostgresCopyStatementBuilder.should_receive(:create_many)
        Employee.create_many(
                              [{ :name => 'Keith', :company_id => 2 }],
                              :statement_builder => '::BulkDataMethods::PostgresCopyStatementBuilder'
                            )
      end
    end # when call method with the :statement_builder = '::BulkDataMethods::PostgresCopyStatementBuilder'

  end # create_many

  describe "update_many" do

    before do
      Employee.create_many([{ :name => 'Keith', :company_id => 2 },
                            { :name => 'Alex', :company_id => 1 },
                            { :name => 'Mark', :company_id => 2 },
                            { :name => 'Phil', :company_id => 3 }])
    end

    context "when call method with empty rows" do
      it "returns empty array" do
        Employee.update_many("").should == []
      end
    end # when call method with empty rows

    context "when try to update records without options" do

      context "input parameters is hash" do
        it "records updated" do
          Employee.update_many({ { :id => 1 } => {
                                   :name => 'Elvis'
                                 },
                                 { :id => 2 } => {
                                   :name => 'Freddi'
                                 } })
          Employee.find(1).name.should == "Elvis"
          Employee.find(2).name.should == "Freddi"
        end
      end # input parameters is hash

      context "input parameters is array" do
        it "records updated" do
          Employee.update_many([{ :id => 1,
                                  :name => 'Elvis'
                                },
                                { :id => 2,
                                  :name => 'Freddi'
                                }])
          Employee.find(1).name.should == "Elvis"
          Employee.find(2).name.should == "Freddi"
        end
      end # input parameters is array

      context "when try to update two records and doesn't the same number of keys" do
        it "raises BulkUploadDataInconsistent" do
          lambda { Employee.update_many([{ :id => 1, :name => 'Elvis', :salary => 1002  },
                                         { :name => 'Freddi', :id => 2}])
          }.should raise_error(BulkMethodsMixin::BulkUploadDataInconsistent)
        end
      end # when try to update two records and doesn't the same number of keys

      context "when try to update records with the given updated_at" do
        it "records created" do
          Employee.update_many([{ :id => 1,
                                  :updated_at => Time.zone.parse('2012-01-02')
                                },
                                { :id => 2,
                                  :updated_at => Time.zone.parse('2012-01-03')
                                },
                                { :id => 3,
                                  :updated_at => Time.zone.parse('2012-01-04')
                                },
                                { :id => 4,
                                  :updated_at => Time.zone.parse('2012-01-05')
                                }])
          Employee.all.map{ |r| r.updated_at }.should == [
                                                           Time.zone.parse('2012-01-02'),
                                                           Time.zone.parse('2012-01-03'),
                                                           Time.zone.parse('2012-01-04'),
                                                           Time.zone.parse('2012-01-05')
                                                          ]
        end
      end # when try to update records with the given updated_at

    end # when try to update records without options

    context "when call method with option :slice_size set is default" do
      it "generates one insert queries" do
        Employee.should_receive(:find_by_sql).once.and_return([])
        Employee.update_many([{ :id => 1, :name => 'Elvis' },
                              { :id => 2, :name => 'Freddi'},
                              { :id => 3, :name => 'Patric'},
                              { :id => 4, :name => 'Jane'}])
      end
    end # when call method with option :slice_size set is default


    context "when call method with option :slice_size = 2" do
      it "generates two insert queries" do
        Employee.should_receive(:find_by_sql).twice.and_return([])
        Employee.update_many([{ :id => 1, :name => 'Elvis' },
                              { :id => 2, :name => 'Freddi'},
                              { :id => 3, :name => 'Patric'},
                              { :id => 4, :name => 'Jane'}],
                              { :slice_size => 2})
      end
    end # when call method with option :slice_size = 2

    context "when try to update two records and doesn't
             the same number of keys and options check_consistency equal false" do
      it "raises ActiveRecord::StatementInvalid" do
        lambda {
          Employee.update_many([{ :id => 1, :name => 'Elvis', :salary => 1002  },
                                { :name => 'Freddi', :id => 2}],
                                { :check_consistency => false })
        }.should raise_error(ActiveRecord::StatementInvalid)
      end
    end # when try to update two records and doesn't
        # the same number of keys and options check_consistency equal false

    context "when update two records with options 'returning' equal :name" do
      it "returns last records name" do
        Employee.update_many([{ :id => 1, :name => 'Elvis' },
                              { :id => 2, :name => 'Freddi'}],
                              { :returning => [:name] }).
                   last.name.should == 'Freddi'
      end
    end # when update two records with options 'returning' equal :name

    context "when update method with options :set_array equal 'salary = datatable.salary'" do
      it "updates only salary column" do
        Employee.update_many([{ :id => 1, :name => 'Elvis', :salary => 12 },
                              { :id => 2, :name => 'Freddi',:salary => 22}],
                              { :set_array => '"salary = datatable.salary"' })
        Employee.find(1).name.should_not == "Elvis"
        Employee.find(1).salary.should == 12
        Employee.find(2).name.should_not == "Freddi"
        Employee.find(2).salary.should == 22
      end
    end # when update method with options :set_array equal 'salary = datatable.salary'

    context "when update method with options :where" do
      it "updates only name column, where salary equal input values" do
        Employee.update_many([{ :id => 1, :name => 'Elvis', :salary => 12 },
                              { :id => 2, :name => 'Freddi',:salary => 22}],
                              { :where => '"#{table_name}.salary = datatable.salary"' })
        Employee.find(1).name.should_not == "Elvis"
        Employee.find(1).salary.should == 3
        Employee.find(2).name.should_not == "Freddi"
        Employee.find(2).salary.should == 3
      end
    end # when update method with options :where

    context "when try to update records in the table that has all the different sql types" do

      before do
        ActiveRecord::Base.connection.execute <<-SQL
          ALTER TABLE employees ADD COLUMN test_string character varying;
          ALTER TABLE employees ADD COLUMN test_float float;
          ALTER TABLE employees ADD COLUMN test_decimal decimal;
          ALTER TABLE employees ADD COLUMN test_time time;
          ALTER TABLE employees ADD COLUMN test_time_string time;
          ALTER TABLE employees ADD COLUMN test_date date;
          ALTER TABLE employees ADD COLUMN test_date_string date;
          ALTER TABLE employees ADD COLUMN test_bytea bytea;
          ALTER TABLE employees ADD COLUMN test_boolean boolean;
          ALTER TABLE employees ADD COLUMN test_xml xml;
          ALTER TABLE employees ADD COLUMN test_tsvector tsvector;
        SQL
        Employee.reset_column_information
      end

      after do
        ActiveRecord::Base.connection.reset!
      end

      context "non-null values" do
        it "returns record with all sql types" do
          lambda { Employee.update_many([{ :id => 1,
                                           :name => 'Keith',
                                           :company_id => 2,
                                           :created_at => Time.zone.parse('2012-12-21'),
                                           :updated_at => '2012-12-21 00:00:00',
                                           :test_string => "string",
                                           :test_float => 12.34,
                                           :test_decimal => 123456789101112,
                                           :test_time => Time.now,
                                           :test_time_string => '00:00:00',
                                           :test_date => Date.parse('2012-12-21'),
                                           :test_date_string => '2012-12-21',
                                           :test_bytea => "text".bytes.to_a,
                                           :test_boolean => false,
                                           :test_xml => ["text"].to_xml,
                                           :test_tsvector => "test string",
                                         }]) }.should_not raise_error
          Employee.find(1).test_boolean.should == false
          Employee.find(1).test_tsvector.should == "'string' 'test'"
        end
      end # non-null values

      context "null values" do
        it "returns record with all sql types" do
          lambda { Employee.update_many([{ :id => 1,
                                           :name => 'Keith',
                                           :company_id => 2,
                                           :updated_at => nil,
                                           :salary => nil,
                                           :test_string => nil,
                                           :test_float => nil,
                                           :test_decimal => nil,
                                           :test_time => nil,
                                           :test_time_string => nil,
                                           :test_date => nil,
                                           :test_date_string => nil,
                                           :test_bytea => nil,
                                           :test_boolean => nil,
                                           :test_xml => nil,
                                           :test_tsvector => nil,
                                         }]) }.should_not raise_error
          Employee.find(1).test_boolean.should == nil
          Employee.find(1).test_tsvector.should == nil
        end
      end # null values

    end # when try to update records in the table that has all the different sql types

  end # update_many

  describe "set_options" do

    context "when options set as an empty hash" do
      it "returns default values that were set in the initializer" do
        options = {}
        opt = BulkMethodsMixin.set_options(options)
        opt[:statement_builder].should == BulkDataMethods.statement_builder
        opt[:slice_size].should == BulkDataMethods.slice_size
        opt[:check_consistency].should == BulkDataMethods.check_consistency
        opt[:returning].should == BulkDataMethods.returning
      end
    end # when options set as an empty hash

    context "when we pass the custom options" do
      it "returns values which we passed" do
        options = {
                    :statement_builder => "BulkDataMethods::PostgresCopyStatementBuilder",
                    :slice_size => 12345,
                    :check_consistency => false,
                    :returning => :id
                  }
        opt = BulkMethodsMixin.set_options(options)
        opt[:statement_builder].should == options[:statement_builder]
        opt[:slice_size].should == options[:slice_size]
        opt[:check_consistency].should == options[:check_consistency]
        opt[:returning].should == options[:returning]
      end
    end # when we pass the custom options

  end # set_options

end # BulkMethodsMixin