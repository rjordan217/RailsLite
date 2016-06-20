# RailsLite
This project is a framework for generating a backend server with relational database and basic request/response features.

## About RailsLite
RailsLite is a framework built in Ruby and inspired by, surprising though it may seem, the Rails framework developed by DHH. The core functionality is established in two main portions of the library. One chunk is dedicated to dealing with database querying and translating query results into Ruby objects in a manner reminiscent of Rails' ActiveRecord class. The other portion essentially implements the controller and view components of an MVC architecture. Rack middleware and ERB are integrated into the project to enable simple HTTP request processing and dynamic view generation.

### ActiveRecord "Lite"

The ActiveRecord Lite library contains classes and modules built to allow Ruby-style manipulation of data stored in a SQLite database. The SQLObject class is comparable to Rails' ActiveRecord::Base class, constructing and returning Ruby objects from rows of data stored in a database table corresponding to the SQLObject::table_name. This class includes and extends the following modules: Associatable, Searchable, and Validatable. Searchable methods return Relation objects, which feature lazy-loading and stacking of SQL queries, preventing unnecessary database queries.

#### Associatable

The Associatable module allows users to easily access objects that are associated with the current SQLObject subclass by a `:foreign_key == :id` mapping in the database. The module stores an AssocOptions object in an instance variable, which is initialized or appended to via the class methods ::belongs_to and ::has_many. The BelongsToOptions class, which inherits from the AssocOptions class, is shown below to demonstrate association option storage.
```ruby
class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || name.to_s.dup.concat("_id").to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.dup.camelize
  end
end
```
Like Rails, my module will automatically build logical defaults for these options based on the original and associated class names. When a `::belongs_to(:associated_class)` association is specified, my program uses Ruby's ::define_method to generate an `:associated_class` instance method for the SQLObject subclass, which runs the following query:
```SQL
SELECT
  #{joining}.*
FROM
  #{self.class.table_name}
JOIN
  #{joining} ON #{joining}.#{propriete.primary_key} = #{self.class.table_name}.#{propriete.foreign_key}
WHERE
  #{self.class.table_name}.#{propriete.primary_key} = #{self.id}
```
Here, `joining` represents the table that "owns" the current SQLObject, while `propriete` represents a BelongsToOptions object constructed based on developer input. The result of this query is parsed by the SQLObject subclass corresponding to the join table and returns an instance of that class. An similar process occurs in reverse for a ::has_many relation.

#### Searchable

The Searchable module, though fairly lightweight in code, carries a very heavyweight function.
```ruby
# The entirety of the Searchable module.

module Searchable
  def where(params)
    unless params.is_a?(String)
      cols = params.keys
      vals = nest_strings(params.values)
      to_map = cols.zip(vals)
      joined_pairs = to_map.map do |pair|
        pair.join(" = ")
      end
      where_line = joined_pairs.join(" AND ")
    else
      where_line = params
    end
    relation.add_condition(:where, where_line)
    relation
  end
end
```
This module is built on the ActiveRecordLite::Relation class, which saves specified query options in a `@conditions` hash instance variable. Saving where conditions to an instance variable is what allows stacking and lazy-loading of SQLObject#where queries. The Relation object will not query the database unless #all, #count, #first, #last, or #[] is called.

#### Validatable

The Validatable module is responsible for defining both class and instance methods that allow validation callbacks to be run before a save is attempted. The module defines the `@callbacks` variable on the class in which it is implemented, while the `@errors` instance variable holds any error messages that occur when the validation callbacks are run. The following code snippet shows the `ClassMethods` submodule that are metaprogrammed onto classes implementing Validatable using the Ruby's Class#included method. This code snippet is what allows validations to be written in the same format as Rails, using the word `validates`.
```ruby
module ClassMethods
  def validates(*attrs, options)
    options.each do |key, val|
      callbacks << case key
      when :presence
        Proc.new { |this| this.validate_presence(attrs,val) }
      when :absence
        Proc.new { |this| this.validate_absence(attrs, val) }
      when :inclusion
        Proc.new { |this| this.validate_inclusion(attrs,val) }
      when :length
        Proc.new { |this| this.validate_length(attrs,val) }
      when :uniqueness
        Proc.new { |this| this.validate_uniqueness(attrs,val) }
      end
    end
  end

  def callbacks
    @callbacks ||= []
  end
end
```
This snippet also shows that the `@callbacks` variable stores an array of Procs to call later when the `:before_save` action is called. The methods that these Procs call will then either validate the SQLObject on which they are called, or add an error message to the `@errors` instance variable.

<!-- ### Views, Controllers, and Middleware
 -->


## Moving Forward

Future directions for the RailsLite project are numerous and would result in a more robust library. An important step forward would be to add database-constructing functionality to the bash script, so a database could be constructed using a schema of the tables and any migrations that modify table structure or properties. This would also add another layer of data verification below the Validatable module to prevent faulty data insertion. The ActiveRecord Lite Searchable module could also be expanded with more robust querying capabilities, including implementation of `ORDER BY`, `JOIN... ON` and more! Application controllers could greatly benefit from addition of hooks homologous to Rails' `::before_action`, `::around_action`, and `::after_action` filters. Finally, further layers of middleware could improve server functionality by adding features like HTML caching and a CAS. The possibilities for improvement are nearly endless!
