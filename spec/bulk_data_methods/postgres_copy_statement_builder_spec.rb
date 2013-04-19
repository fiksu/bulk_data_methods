require 'spec_helper'
require "#{File.dirname(__FILE__)}/../support/tables_spec_helper"
require "#{File.dirname(__FILE__)}/../support/files_spec_helper"

describe "PostgresCopyStatementBuilder" do
  include TablesSpecHelper
  include FilesSpecHelper

  before do
    class Employee < ActiveRecord::Base
      extend BulkMethodsMixin
    end
    Employee.reset_column_information
    create_tables
  end

  let!(:subject) { ::BulkDataMethods::PostgresCopyStatementBuilder }
  let!(:options) { BulkMethodsMixin.set_options(:statement_builder => 'BulkDataMethods::PostgresCopyStatementBuilder') }

  describe "#create_many" do

    context "when file doesn't exist" do
      it "returns empty array" do
        subject.create_many(
                             "/fake_path",
                             options,
                             Employee
                           ).should == []
      end
    end # when file doesn't exist

    context "when file format is csv" do

      it "creates the record" do
        str = "02/04/13 01:20 PM,02/04/13 01:20 PM,Mike,1000,1,32"
        path_to_file = create_file('csv', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.should have(1).item
      end

    end # when file format is csv

    context "when file format is text" do

      before do
        options[:file_format] = "TEXT"
      end

      it "creates the record" do
        str = "2013-04-19 18:07:13.336681	2013-04-19 18:07:13.336681	Alex	100	1	12"
        path_to_file = create_file('text', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.should have(1).item
      end

    end # when file format is text

    context "when column_names option is set" do

      before do
        options[:column_names] = ["created_at","updated_at","name","salary",:company_id]
      end

      it "creates the record" do
        str = "02/04/13 01:20 PM,02/04/13 01:20 PM,Mike,1000,1"
        path_to_file = create_file('csv', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.should have(1).item
      end

    end # when column_names option is set

    context "when column_names option isn't set" do

      it "creates the record" do
        str = "02/04/13 01:20 PM,02/04/13 01:20 PM,Mike,1000,1,32"
        path_to_file = create_file('csv', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.should have(1).item
      end

    end # when column_names option isn't' set

    context "when delimiter option is set" do

      before do
        options[:delimiter] = ';'
      end

      it "creates the record" do
        str = "02/04/13 01:20 PM;02/04/13 01:20 PM;Mike;1000;1;32"
        path_to_file = create_file('csv', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.should have(1).item
      end

    end # when delimiter option is set

    context "when null option is set" do

      before do
        options[:null] = 1000
      end

      it "salary is nil" do
        str = "02/04/13 01:20 PM,02/04/13 01:20 PM,Mike,1000,1,32"
        path_to_file = create_file('csv', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.first.salary.should be_nil
      end

    end # when null option is set

    context "when encoding option is set" do

      before do
        options[:encoding] = "KOI8R"
      end

      it "creates the record" do
        str = "02/04/13 01:20 PM,02/04/13 01:20 PM,Mike,1000,1,32"
        path_to_file = create_file('csv', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.should have(1).item
      end

    end # when encoding option is set

    context "when header option is set" do

      before do
        options[:header] = true
      end

      it "creates the record" do
        str = "header\n02/04/13 01:20 PM,02/04/13 01:20 PM,Mike,1000,1,32"
        path_to_file = create_file('csv', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.should have(1).item
      end

    end # when header option is set

    context "when quote option is set" do

      before do
        options[:quote] = "*"
      end

      it "creates the record" do
        str = "02/04/13 01:20 PM,02/04/13 01:20 PM,Mike,*1000*,1,32"
        path_to_file = create_file('csv', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.should have(1).item
      end

    end # when quote option is set

    context "when force_not_null option is set" do

      before do
        options[:force_not_null] = ["salary"]
      end

      it "doesn't create the record" do
        str = "02/04/13 01:20 PM,02/04/13 01:20 PM,Mike,,1,32"
        path_to_file = create_file('csv', str)
        subject.create_many(
                             path_to_file,
                             options,
                             Employee
                            )
        delete_file(path_to_file)
        Employee.all.should be_blank
      end

    end # when force_not_null option is set

  end # #create_many

end # PostgresCopyStatementBuilder