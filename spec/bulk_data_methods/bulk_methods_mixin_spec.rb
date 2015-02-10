require 'spec_helper'
require "#{File.dirname(__FILE__)}/../support/tables_spec_helper"

describe "BulkMethodsMixin" do
  include TablesSpecHelper

  before do
    class Employee < ActiveRecord::Base
      extend BulkMethodsMixin
    end
    create_tables

    class Name < ActiveRecord::Base
      extend BulkMethodsMixin
    end
    create_tables_without_ids_or_created
  end

  describe "create_many" do

    context "when call method with empty rows" do
      it "returns empty array" do
        expect(Employee.create_many("")).to be_empty
      end
    end # when call method with empty rows

    context "when try to create records with the given id" do
      it "records created" do
        Employee.create_many([{ :id => Employee.connection.next_sequence_value(Employee.sequence_name),
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
                              }])
        expect(Employee.all.map{ |r| r.name }).to match_array ["Keith", "Mike", "Alex"]
      end
    end # when try to create records with the given id

    context "when try to create records without the given id" do
      it "records created" do
        Employee.create_many([{ :name => 'Keith', :company_id => 2 },
                              { :name => 'Mike', :company_id => 3 },
                              { :name => 'Alex', :company_id => 1 }])
        expect(Employee.all.map{ |r| r.name }).to match_array ["Keith", "Mike", "Alex"]
      end
    end # when try to create records without the given id

    context "when try to create records with a mixture of given ids and non-given ids" do
      it "records created" do
        Employee.create_many([{ :name => 'Keith', :company_id => 2 },
                              { :id => Employee.connection.next_sequence_value(Employee.sequence_name),
                                :name => 'Mike',
                                :company_id => 3
                              },
                              { :name => 'Mark', :company_id => 1 },
                              { :id => Employee.connection.next_sequence_value(Employee.sequence_name),
                                :name => 'Alex',
                                :company_id => 1
                              }])
        expect(Employee.all.map{ |r| r.name }).to match_array ["Keith", "Mike", "Mark", "Alex"]
      end
    end # when try to create records with a mixture of given ids and non-given ids

    context "when try to create records with the given created_at" do
      it "records created" do
        Employee.create_many([{ :name => 'Keith',
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
                              }])
        expect(Employee.all.map{ |r| r.created_at }).to match_array (
                                                                     [
                                                                       Time.zone.parse('2012-01-02'),
                                                                       Time.zone.parse('2012-01-03'),
                                                                       Time.zone.parse('2012-01-04')
                                                                     ]
                                                                     )
      end
    end # when try to create records with the given created_at

    context "when try to create records without the given created_at" do
      it "records created" do
        Employee.create_many([{ :name => 'Keith', :company_id => 2 },
                              { :name => 'Mike', :company_id => 3 },
                              { :name => 'Alex', :company_id => 1 }])
        expect(Employee.all.map{ |r| r.created_at.between?(Time.now - 3.minute, Time.now + 3.minute) }).to match_array [true, true, true]
      end
    end # when try to create records without the given created_at

    context "when try to create records without options" do
      it "generates one insert queries" do
        expect(Employee).to receive(:find_by_sql).once.and_return([])
        Employee.create_many([{ :name => 'Keith', :company_id => 2 },
                              { :name => 'Alex', :company_id => 1 },
                              { :name => 'Mark', :company_id => 2 },
                              { :name => 'Phil', :company_id => 3 }])
      end
    end # when try to create records without options

    context "when call method with option 'slice_size' equal 2" do
      it "generates two insert queries" do
        expect(Employee).to receive(:find_by_sql).twice.and_return([])
        Employee.create_many([{ :name => 'Keith', :company_id => 2 },
                              { :name => 'Alex', :company_id => 1 },
                              { :name => 'Mark', :company_id => 2 },
                              { :name => 'Phil', :company_id => 3 }],
                              { :slice_size => 2})
      end
    end # when call method with option 'slice_size' equal 2

    context "when create two records with options 'returning' equal id" do
      it "returns last records id" do
        expect(Employee.create_many([{ :name => 'Keith', :company_id => 2 },
                                      { :name => 'Alex', :company_id => 3 }],
                                    { :returning => [:id] }).last.id).to eq 2
      end
    end # when create two records with options 'returning' equal id

    context "when try to create two records and doesn't
             the same number of keys and options check_consistency equal false" do
      it "records created, last salary is nil" do
        Employee.create_many([{ :company_id => 2, :name => 'Keith', :salary => 1002 },
                              { :name => 'Alex', :company_id => 3 }],
                              { :check_consistency => false })
        expect(Employee.find(2).salary).to be_nil
      end
    end # when try to create two records and doesn't
        # the same number of keys and options check_consistency equal false

    context "when try to create two records and doesn't the same number of keys" do
      it "raises BulkUploadDataInconsistent" do
        expect(lambda { Employee.create_many([{ :company_id => 2, :name => 'Keith', :salary => 1002  },
                                       { :name => 'Alex', :company_id => 3}])
        }).to raise_error(BulkMethodsMixin::BulkUploadDataInconsistent)
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
          # NOTE(hofer): Expectation is that this will not raise an error.
          Employee.create_many([{ :name => 'Keith',
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
                                 }])
          expect(Employee.all.size).to eq 1
        end
      end # non-null values

      context "null values" do
        it "returns record with all sql types" do
          # NOTE(hofer): Expectation is that this will not raise an error.
          Employee.create_many([{ :name => 'Keith',
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
                                 }])
          expect(Employee.all.size).to eq 1
        end
      end # null values

    end # when try to create records in the table that has all the different sql types

    describe "without ids or created_at" do

      context "when call method with empty rows" do
        it "returns empty array" do
          expect(Name.create_many("")).to be_empty
        end
      end # when call method with empty rows

      context "when try to create records without ids or createds" do
        it "records created" do
          Name.create_many([{ :name => 'Keith' },
                            { :name => 'Mike' },
                            { :name => 'Alex' }])
          expect(Name.all.map{ |r| r.name }).to match_array ["Keith", "Mike", "Alex"]
        end
      end

    end

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
        expect(Employee.update_many("")).to be_empty
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
          expect(Employee.find(1).name).to eq "Elvis"
          expect(Employee.find(2).name).to eq "Freddi"
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
          expect(Employee.find(1).name).to eq "Elvis"
          expect(Employee.find(2).name).to eq "Freddi"
        end
      end # input parameters is array

      context "when try to update two records and doesn't the same number of keys" do
        it "raises BulkUploadDataInconsistent" do
          expect(lambda { Employee.update_many([{ :id => 1, :name => 'Elvis', :salary => 1002  },
                                         { :name => 'Freddi', :id => 2}])
          }).to raise_error(BulkMethodsMixin::BulkUploadDataInconsistent)
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
          expect(Employee.all.map{ |r| r.updated_at }).to match_array [
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
        expect(Employee).to receive(:find_by_sql).once.and_return([])
        Employee.update_many([{ :id => 1, :name => 'Elvis' },
                              { :id => 2, :name => 'Freddi'},
                              { :id => 3, :name => 'Patric'},
                              { :id => 4, :name => 'Jane'}])
      end
    end # when call method with option :slice_size set is default


    context "when call method with option :slice_size = 2" do
      it "generates two insert queries" do
        expect(Employee).to receive(:find_by_sql).twice.and_return([])
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
        expect(lambda {
          Employee.update_many([{ :id => 1, :name => 'Elvis', :salary => 1002  },
                                { :name => 'Freddi', :id => 2}],
                                { :check_consistency => false })
        }).to raise_error(ActiveRecord::StatementInvalid)
      end
    end # when try to update two records and doesn't
        # the same number of keys and options check_consistency equal false

    context "when update two records with options 'returning' equal :name" do
      it "returns last records name" do
        expect(Employee.update_many([{ :id => 1, :name => 'Elvis' },
                                      { :id => 2, :name => 'Freddi'}],
                                    { :returning => [:name] }).last.name).to eq 'Freddi'
      end
    end # when update two records with options 'returning' equal :name

    context "when update method with options :set_array equal 'salary = datatable.salary'" do
      it "updates only salary column" do
        Employee.update_many([{ :id => 1, :name => 'Elvis', :salary => 12 },
                              { :id => 2, :name => 'Freddi',:salary => 22}],
                              { :set_array => '"salary = datatable.salary"' })
        expect(Employee.find(1).name).not_to eq "Elvis"
        expect(Employee.find(1).salary).to eq 12
        expect(Employee.find(2).name).not_to eq "Freddi"
        expect(Employee.find(2).salary).to eq 22
      end
    end # when update method with options :set_array equal 'salary = datatable.salary'

    context "when update method with options :where_constraint" do
      it "updates only name column, where salary equal input values" do
        Employee.update_many([{ :id => 1, :name => 'Elvis', :salary => 12 },
                              { :id => 2, :name => 'Freddi',:salary => 22},
                              { :id => 3, :name => 'Robert', :salary => 13}],
                              { :where_constraint => '"#{table_name}.salary = datatable.salary AND datatable.salary < 13"' })
        expect(Employee.find(1).name).not_to eq "Elvis"
        expect(Employee.find(1).salary).to eq 3
        expect(Employee.find(2).name).not_to eq "Freddi"
        expect(Employee.find(2).salary).to eq 3
        expect(Employee.find(3).name).not_to eq "Robert"
        expect(Employee.find(3).salary).to eq 3
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
          # NOTE(hofer): Expectation is that this will not raise an error.
          Employee.update_many([{ :id => 1,
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
                                 }])
          expect(Employee.find(1).test_boolean).to eq false
          expect(Employee.find(1).test_tsvector).to eq "'string' 'test'"
        end
      end # non-null values

      context "null values" do
        it "returns record with all sql types" do
          # NOTE(hofer): Expectation is that this will not raise an error.
          Employee.update_many([{ :id => 1,
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
                                 }])
          expect(Employee.find(1).test_boolean).to be_nil
          expect(Employee.find(1).test_tsvector).to be_nil
        end
      end # null values

    end # when try to update records in the table that has all the different sql types

  end # update_many

end # BulkMethodsMixin
