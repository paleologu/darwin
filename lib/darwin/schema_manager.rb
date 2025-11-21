# frozen_string_literal: true

module Darwin
  class SchemaManager
    def self.sync!(model)
      table_name = "darwin_#{model.name.to_s.tableize}"
      connection = ActiveRecord::Base.connection

      ensure_table!(table_name)

      expected_columns = {}
      model.blocks.where(method_name: 'attribute').each do |block|
        name, type = block.args
        expected_columns[name] = type.to_sym
      end
      model.blocks.where(method_name: 'belongs_to').each do |block|
        assoc_name = block.args.first.to_sym
        options = Darwin::Interpreter.deep_symbolize_keys(block.options)
        foreign_key = options[:foreign_key] || "#{assoc_name}_id"
        expected_columns[foreign_key.to_s] = :integer
      end

      existing_columns = connection.columns(table_name).index_by { |c| c.name.to_s }

      # Add or change columns
      expected_columns.each do |col_name, col_type|
        if existing_columns[col_name]
          # Column exists, check type
          if existing_columns[col_name].type != col_type
            connection.change_column(table_name, col_name, col_type, using: "CAST(#{col_name} AS #{col_type})")
          end
        else
          # Column doesn't exist, add it
          connection.add_column(table_name, col_name, col_type)
        end
      end

      # Remove old columns
      (existing_columns.keys - expected_columns.keys - %w[id created_at updated_at]).each do |col_name|
        connection.remove_column(table_name, col_name)
      end
      connection.reset!
    end

    def self.drop!(model)
      table_name = "darwin_#{model.name.to_s.tableize}"
      connection = ActiveRecord::Base.connection
      connection.drop_table(table_name, if_exists: true)
      connection.reset!
    end

    def self.ensure_table!(table_name)
      connection = ActiveRecord::Base.connection
      return if connection.table_exists?(table_name)

      connection.create_table(table_name) do |t|
        t.timestamps
      end
      connection.reset!
    end

    def self.ensure_column!(table_name, column_name, type)
      ensure_table!(table_name)
      connection = ActiveRecord::Base.connection
      return if connection.column_exists?(table_name, column_name)

      connection.add_column(table_name, column_name, type.to_sym)
      connection.reset!
    end

    def self.cleanup!
      connection = ActiveRecord::Base.connection
      connection.schema_cache.clear!

      models = Darwin::Model.all.to_a
      expected_tables = models.map { |m| "darwin_#{m.name.to_s.tableize}" }
      existing_tables = ActiveRecord::Base.connection.tables.grep(/^darwin_/)

      tables_to_drop = existing_tables - expected_tables - %w[darwin_models darwin_blocks]
      return if tables_to_drop.empty?

      tables_to_drop.each do |table|
        ActiveRecord::Base.connection.drop_table(table, if_exists: true)
      end
      ActiveRecord::Base.connection.reset!
    end

    def sync_schema!
      Darwin::Model.all.each do |model|
        self.class.sync!(model)
      end
    end
  end
end
