require 'spec_helper'
require "#{File.dirname(__FILE__)}/../support/tables_spec_helper"

describe "GenericBulkInsertStatementBuilder" do
  include TablesSpecHelper

  before do
    class Employee < ActiveRecord::Base
      extend BulkMethodsMixin
    end
    create_tables
  end

  let!(:subject) { ::BulkDataMethods::GenericBulkInsertStatementBuilder }
  let!(:options) { BulkMethodsMixin.set_options(:statement_builder => 'BulkDataMethods::GenericBulkInsertStatementBuilder') }

  describe "#create_many" do

    context "when try to create records with the given id" do
      it "records created" do
        subject.create_many(
                             [{ :id => Employee.connection.next_sequence_value(Employee.sequence_name),
                                :name => 'Keith',
                                :company_id => 2
                              },
                              { :id => Employee.connection.next_sequence_value(Employee.sequence_name),
                                :name => 'Mike',
                                :company_id => 3
                              },
                              { :id => Employee.connection.next_sequence_value(Employee.sequence_name),
                                :name => 'Alex',
                                :company_id => 1
                             }],
                             options,
                             Employee
                            )
        Employee.all.map{ |r| r.name }.should == ["Keith", "Mike", "Alex"]
      end
    end # when try to create records with the given id

    context "when try to create records without the given id" do
      it "records created" do
        subject.create_many(
                             [{ :name => 'Keith', :company_id => 2 },
                             { :name => 'Mike', :company_id => 3 },
                             { :name => 'Alex', :company_id => 1 }],
                             options,
                             Employee
                            )
        Employee.all.map{ |r| r.name }.should == ["Keith", "Mike", "Alex"]
      end
    end # when try to create records without the given id

    context "when try to create records with a mixture of given ids and non-given ids" do
      it "records created" do
        subject.create_many(
                             [{ :name => 'Keith', :company_id => 2 },
                              { :id => Employee.connection.next_sequence_value(Employee.sequence_name),
                                :name => 'Mike',
                                :company_id => 3
                              },
                              { :name => 'Mark', :company_id => 1 },
                              { :id => Employee.connection.next_sequence_value(Employee.sequence_name),
                                :name => 'Alex',
                                :company_id => 1
                              }],
                              options,
                              Employee
                            )
        Employee.all.map{ |r| r.name }.should == ["Keith", "Mike", "Mark", "Alex"]
      end
    end # when try to create records with a mixture of given ids and non-given ids

    context "when try to create records with the given created_at" do
      it "records created" do
        subject.create_many(
                              [{ :name => 'Keith',
                                :company_id => 2,
                                :created_at => Time.zone.parse('2012-01-02')
                              },
                              { :name => 'Mike',
                                :company_id => 3,
                                :created_at => Time.zone.parse('2012-01-03')
                              },
                              { :name => 'Alex',
                                :company_id => 1,
                                :created_at => Time.zone.parse('2012-01-04')
                              }],
                              options,
                              Employee
                            )
        Employee.all.map{ |r| r.created_at }.should == [
                                                         Time.zone.parse('2012-01-02'),
                                                         Time.zone.parse('2012-01-03'),
                                                         Time.zone.parse('2012-01-04')
                                                        ]
      end
    end # when try to create records with the given created_at

    context "when try to create records without the given created_at" do
      it "records created" do
        subject.create_many(
                             [{ :name => 'Keith', :company_id => 2 },
                              { :name => 'Mike', :company_id => 3 },
                              { :name => 'Alex', :company_id => 1 }],
                              options,
                              Employee
                            )
        Employee.all.each{ |r| r.created_at.between?(Time.now - 3.minute, Time.now + 3.minute) }.
            should be_true
      end
    end # when try to create records without the given created_at

    context "when try to create records without options" do
      it "generates one insert queries" do
        Employee.should_receive(:find_by_sql).once.and_return([])
        subject.create_many(
                            [{ :name => 'Keith', :company_id => 2 },
                             { :name => 'Alex', :company_id => 1 },
                             { :name => 'Mark', :company_id => 2 },
                             { :name => 'Phil', :company_id => 3 }],
                             options,
                             Employee
                            )
      end
    end # when try to create records without options

    context "when call method with option 'slice_size' equal 2" do
      it "generates two insert queries" do
        options[:slice_size] = 2
        Employee.should_receive(:find_by_sql).twice.and_return([])
        subject.create_many(
                             [{ :name => 'Keith', :company_id => 2 },
                              { :name => 'Alex', :company_id => 1 },
                              { :name => 'Mark', :company_id => 2 },
                              { :name => 'Phil', :company_id => 3 }],
                              options,
                              Employee
                            )
      end
    end # when call method with option 'slice_size' equal 2

    context "when create two records with options 'returning' equal id" do
      it "returns last records id" do
        options[:returning] = [:id]
        subject.create_many(
                             [{ :name => 'Keith', :company_id => 2 },
                              { :name => 'Alex', :company_id => 3 }],
                              options,
                              Employee
                            ).last.id.should == 2
      end
    end # when create two records with options 'returning' equal id

    context "when try to create two records and doesn't
             the same number of keys and options check_consistency equal false" do
      it "records created, last salary is nil" do
        options[:check_consistency] = false
        subject.create_many(
                             [{ :company_id => 2, :name => 'Keith', :salary => 1002 },
                              { :name => 'Alex', :company_id => 3 }],
                              options,
                              Employee
                            )
        Employee.find(2).salary.should == nil
      end
    end # when try to create two records and doesn't
        # the same number of keys and options check_consistency equal false

    context "when try to create two records and doesn't the same number of keys" do
      it "raises BulkUploadDataInconsistent" do
        lambda { subject.create_many(
                                      [{ :company_id => 2, :name => 'Keith', :salary => 1002  },
                                       { :name => 'Alex', :company_id => 3}],
                                       options,
                                       Employee
                                     )
        }.should raise_error(BulkMethodsMixin::BulkUploadDataInconsistent)
      end
    end # when try to create two records and doesn't the same number of keys

    context "when try to create records in the table that has all the different sql types" do

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
          lambda { subject.create_many(
                                        [{ :name => 'Keith',
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
                                         }],
                                         options,
                                         Employee
                                      ) }.should_not raise_error
          Employee.all.size.should == 1
        end
      end # non-null values

      context "null values" do
        it "returns record with all sql types" do
          lambda { subject.create_many(
                                        [{ :name => 'Keith',
                                           :company_id => 2,
                                           :created_at => nil,
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
                                        }],
                                        options,
                                        Employee
                                       ) }.should_not raise_error
          Employee.all.size.should == 1
        end
      end # null values

    end # when try to create records in the table that has all the different sql types

  end # #create_many

end # GenericBulkInsertStatementBuilder