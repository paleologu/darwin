# frozen_string_literal: true

require 'darwin/block_handler_registry'

module Darwin
  class SchemaManager
    def self.sync!(model)
      table_name = "darwin_#{model.name.to_s.tableize}"
      connection = ActiveRecord::Base.connection

      Rails.logger.info "[Darwin::SchemaManager] sync! table=#{table_name} model=#{model.name}"

      ensure_table!(table_name)

      expected_columns = column_specs_from_metadata(model)
      # HEAD
      Darwin::BlockHandlerRegistry.schema_columns_for(model).each do |name, spec|
        expected_columns[name] ||= spec
      end
      # REPLACES OR EXTENDS
      # merge_column_specs!(expected_columns, column_specs_from_attribute_blocks(model))
      # merge_column_specs!(expected_columns, column_specs_from_belongs_to_blocks(model))

      existing_columns = connection.columns(table_name).index_by { |c| c.name.to_s }

      # Add or change columns
      expected_columns.each do |col_name, spec|
        col_type = spec[:type]
        col_options = spec[:options]
        if existing_columns[col_name]
          if column_changed?(existing_columns[col_name], col_type, col_options)
            connection.change_column(table_name, col_name, col_type, **col_options)
            Rails.logger.info "[Darwin::SchemaManager] change_column #{table_name}.#{col_name} -> #{col_type} #{col_options.inspect}"
          end
        else
          # Column doesn't exist, add it
          connection.add_column(table_name, col_name, col_type, **col_options)
          Rails.logger.info "[Darwin::SchemaManager] add_column #{table_name}.#{col_name} #{col_type} #{col_options.inspect}"
        end
      end

      # Remove old columns
      (existing_columns.keys - expected_columns.keys - %w[id created_at updated_at]).each do |col_name|
        connection.remove_column(table_name, col_name)
        Rails.logger.info "[Darwin::SchemaManager] remove_column #{table_name}.#{col_name}"
      end
      connection.reset!
    end

    def self.drop!(model)
      table_name = "darwin_#{model.name.to_s.tableize}"
      connection = ActiveRecord::Base.connection
      connection.drop_table(table_name, if_exists: true)
      connection.reset!
    end

    def self.drop_table!(table_name)
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

      tables_to_drop = existing_tables - expected_tables - %w[darwin_models darwin_blocks darwin_columns]
      return if tables_to_drop.empty?

      tables_to_drop.each do |table|
        ActiveRecord::Base.connection.drop_table(table, if_exists: true)
      end
      ActiveRecord::Base.connection.reset!
    end


    def self.column_specs_from_metadata(model)
      model.columns.each_with_object({}) do |column, specs|
        next if column.name.blank? || column.column_type.blank?

        specs[column.name.to_s] = {
          type: column.column_type.to_sym,
          options: column_options_from_metadata(column)
        }
      end
    end

    def self.column_options_from_metadata(column)
      {
        default: column.default,
        null: column.null.nil? ? true : column.null,
        limit: column.limit,
        precision: column.precision,
        scale: column.scale
      }.compact
    end

    def self.merge_column_specs!(target, new_specs)
      new_specs.each do |col_name, spec|
        next if target.key?(col_name)

        target[col_name] = spec
      end
    end

    def self.column_changed?(existing, type, options)
      return true if existing.type != type

      comparisons = {
        default: existing.default,
        null: existing.null,
        limit: existing.limit,
        precision: existing.precision,
        scale: existing.scale
      }

      options.any? do |key, value|
        comparisons[key] != value
      end
    end
  end
end
