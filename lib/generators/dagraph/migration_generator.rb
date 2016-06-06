
require 'rails/generators'
require 'rails/generators/active_record'
require 'rails/generators/base'

module Dagraph 
  class MigrationGenerator < Rails::Generators::Base 

    source_root File.expand_path("../templates", __FILE__) 

    include Rails::Generators::Migration 

    def create_migration_file 
      migration_template "create_dagraph_edges.rb", "db/migrate/create_dagraph_edges.rb" 
    end 

    def self.next_migration_number(dirname) 
      ActiveRecord::Generators::Base.next_migration_number(dirname) 
    end 
  end 
end
