# Bulk Data Methods

This gem allows:

MixIn used to extend ActiveRecord::Base classes implementing bulk insert and update operations
through {#create_many} and {#update_many}.

Extend methods to your class which inherits from the ActiveRecord::Base

```ruby
  class Company < ActiveRecord::Base
    extend BulkMethodsMixin
  end
```

## BULK creation of many rows:

When :statement_builder option is GenericBulkInsertStatementBuilder:

example no options used

```ruby
  rows = [
             { :name => 'Keith', :salary => 1000 },
             { :name => 'Alex', :salary => 2000 }
         ]
  Employee.create_many(rows)
```

example with :returning option to returns key value

```ruby
  rows = [
             { :name => 'Keith', :salary => 1000 },
             { :name => 'Alex', :salary => 2000 }
         ]
  options = { :returning => [:id] }
  Employee.create_many(rows, options)
```

example with :slice_size option (will generate two insert queries)

```ruby
  rows = [
             { :name => 'Keith', :salary => 1000 },
             { :name => 'Alex', :salary => 2000 },
             { :name => 'Mark', :salary => 3000 }
       ]
  options = { :slice_size => 2 }
  Employee.create_many(rows, options)
```

When :statement_builder option is PostgresCopyStatementBuilder:

example no options used

```ruby
  Employee.create_many('path_to_file')
```

example with :delimiter option set as ';'

```ruby
  Employee.create_many('path_to_file', { :delimiter => ';' })
```

## BULK updates of many rows:

example using "set_array" to add the value of "salary" to the specific employee's salary the default where clause matches IDs so, it works here.

```ruby
  rows = [
             { :id => 1, :salary => 1000 },
             { :id => 10, :salary => 2000 },
             { :id => 23, :salary => 2500 }
       ]
  options = { :set_array => '"salary = datatable.salary"' }
  Employee.update_many(rows, options)
```

example using where clause to match salary.

```ruby
  rows = [
             { :id => 1, :salary => 1000, :company_id => 10 },
             { :id => 10, :salary => 2000, :company_id => 12 },
             { :id => 23, :salary => 2500, :company_id => 5 }
       ]
  options = {
              :set_array => '"company_id = datatable.company_id"',
              :where => '"#{table_name}.salary = datatable.salary"'
            }
  Employee.update_many(rows, options)
```

  example setting where clause to the KEY of the hash passed in and the set_array is generated from the VALUES

```ruby
  rows = {
             { :id => 1 } => { :salary => 100000, :company_id => 10 },
             { :id => 10 } => { :salary => 110000, :company_id => 12 },
             { :id => 23 } => { :salary => 90000, :company_id => 5 }
       }
  Employee.update_many(rows)
```