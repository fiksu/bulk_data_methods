require 'spec_helper'

module TablesSpecHelper

  class Company < ActiveRecord::Base
    extend BulkMethodsMixin
    has_many :employees, :class_name => 'Company', :conditions => "companies.id = employees.companies_id"
  end

  def create_tables
    ActiveRecord::Base.connection.execute <<-SQL
      create table companies
      (
          id               serial not null primary key,
          created_at       timestamp not null default now(),
          updated_at       timestamp,
          name             text null
      );

      insert into companies (name) values ('Fluent Mobile, inc.');
      insert into companies (name) values ('Fiksu, inc.');
      insert into companies (name) values ('FreeMyApps, inc.');

      create table employees
      (
          id               serial not null primary key,
          created_at       timestamp not null default now(),
          updated_at       timestamp,
          name             text not null,
          salary           integer default 3,
          company_id       integer not null,
          integer_field    integer not null default 1
      );
    SQL
  end

  def drop_tables
    ActiveRecord::Base.connection.execute <<-SQL
      drop table employees;
      drop table companies;
    SQL
  end

end