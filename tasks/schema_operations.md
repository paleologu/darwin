You're asking for an explicit implementation plan to refactor Darwin's schema operations from synchronous callbacks to an async queue-based pattern using SolidQueue, with the four specific goals: (1) replace synchronous callbacks with dirty flags, (2) enqueue background jobs, (3) add validation before type changes, and (4) wrap DDL in transactions. [1](#8-0) 

## Implementation Plan

### Phase 1: Add Schema State Tracking

**1.1 Create Migration for Schema State Columns**

Add columns to track schema synchronization state:

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_schema_state_to_darwin_models.rb
class AddSchemaStateToDarwinModels < ActiveRecord::Migration[7.1]
  def change
    add_column :darwin_models, :schema_version, :integer, default: 0, null: false
    add_column :darwin_models, :schema_dirty, :boolean, default: false, null: false
    add_column :darwin_models, :last_schema_sync_at, :datetime
    
    add_index :darwin_models, :schema_dirty
  end
end
```

**1.2 Create Darwin::SchemaMigration Model**

Track individual schema operations with status and rollback capability:

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_darwin_schema_migrations.rb
class CreateDarwinSchemaMigrations < ActiveRecord::Migration[7.1]
  def change
    create_table :darwin_schema_migrations do |t|
      t.references :darwin_model, null: false, foreign_key: { to_table: :darwin_models }
      t.integer :schema_version, null: false
      t.string :status, null: false, default: 'pending' # pending, processing, applied, failed
      t.text :operations # JSON array of DDL operations to perform
      t.text :rollback_operations # JSON array of DDL operations to rollback
      t.text :error_message
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
      
      t.index [:darwin_model_id, :schema_version], unique: true
      t.index :status
    end
  end
end
```

**1.3 Define Darwin::SchemaMigration Model**

```ruby
# app/models/darwin/schema_migration.rb
module Darwin
  class SchemaMigration < ApplicationRecord
    self.table_name = 'darwin_schema_migrations'
    
    belongs_to :darwin_model, class_name: 'Darwin::Model'
    
    enum status: {
      pending: 'pending',
      processing: 'processing',
      applied: 'applied',
      failed: 'failed'
    }
    
    serialize :operations, JSON
    serialize :rollback_operations, JSON
    
    validates :schema_version, presence: true
    validates :status, presence: true
  end
end
```

### Phase 2: Replace Synchronous Callbacks

**2.1 Update Darwin::Model Callbacks**

Replace immediate sync with dirty flag marking: [1](#8-0) 

```ruby
# app/models/darwin/model.rb
module Darwin
  class Model < ::ApplicationRecord
    # Remove these lines:
    # after_commit :sync_schema_and_reload_runtime_constant, on: %i[create update]
    # after_commit :drop_table_and_reload_runtime_constant, on: :destroy
    
    # Replace with:
    after_commit :mark_schema_dirty, on: %i[create update]
    after_commit :enqueue_schema_drop, on: :destroy
    
    private
    
    def mark_schema_dirty
      return if schema_dirty? # Already marked
      
      increment!(:schema_version)
      update_column(:schema_dirty, true)
      
      # Enqueue job to process schema changes
      Darwin::SyncSchemaJob.perform_later(id, schema_version)
    end
    
    def enqueue_schema_drop
      Darwin::DropSchemaJob.perform_later(id, name)
    end
  end
end
```

**2.2 Update Darwin::Block to Mark Parent Dirty**

When blocks change, mark the parent model as dirty:

```ruby
# app/models/darwin/block.rb
module Darwin
  class Block < ApplicationRecord
    belongs_to :darwin_model, class_name: 'Darwin::Model'
    
    after_commit :mark_model_schema_dirty, on: %i[create update destroy]
    
    private
    
    def mark_model_schema_dirty
      darwin_model.mark_schema_dirty if darwin_model
    end
  end
end
```

### Phase 3: Create Background Jobs

**3.1 Create SyncSchemaJob** [2](#8-1) 

```ruby
# app/jobs/darwin/sync_schema_job.rb
module Darwin
  class SyncSchemaJob < ApplicationJob
    queue_as :darwin_schema
    
    retry_on ActiveRecord::StatementInvalid, wait: 5.seconds, attempts: 3
    
    def perform(model_id, schema_version)
      model = Darwin::Model.find(model_id)
      
      # Check if already processed
      return unless model.schema_dirty?
      return unless model.schema_version == schema_version
      
      # Create migration record
      migration = Darwin::SchemaMigration.create!(
        darwin_model: model,
        schema_version: schema_version,
        status: :pending
      )
      
      # Calculate operations
      operations = Darwin::SchemaPlanner.plan_operations(model)
      migration.update!(
        operations: operations[:forward],
        rollback_operations: operations[:rollback]
      )
      
      # Execute migration
      Darwin::SchemaExecutor.execute_migration(migration)
      
      # Mark model as clean
      model.update_columns(
        schema_dirty: false,
        last_schema_sync_at: Time.current
      )
      
      # Reload runtime
      Darwin::Runtime.reload_all!(current_model: model)
      
    rescue => e
      migration&.update!(
        status: :failed,
        error_message: "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      )
      raise
    end
  end
end
```

**3.2 Create DropSchemaJob**

```ruby
# app/jobs/darwin/drop_schema_job.rb
module Darwin
  class DropSchemaJob < ApplicationJob
    queue_as :darwin_schema
    
    def perform(model_id, model_name)
      table_name = "darwin_#{model_name.to_s.tableize}"
      
      ActiveRecord::Base.connection.transaction do
        ActiveRecord::Base.connection.drop_table(table_name, if_exists: true)
        ActiveRecord::Base.connection.reset!
      end
      
      Darwin::Runtime.reload_all!
    end
  end
end
```

### Phase 4: Add Validation Layer

**4.1 Create SchemaPlanner**

Plan operations and validate data compatibility:

```ruby
# lib/darwin/schema_planner.rb
module Darwin
  class SchemaPlanner
    def self.plan_operations(model)
      table_name = "darwin_#{model.name.to_s.tableize}"
      connection = ActiveRecord::Base.connection
      
      SchemaManager.ensure_table!(table_name)
      
      expected_columns = collect_expected_columns(model)
      existing_columns = connection.columns(table_name).index_by(&:name)
      
      forward_ops = []
      rollback_ops = []
      
      # Plan additions
      expected_columns.each do |col_name, col_type|
        if existing_columns[col_name]
          # Column exists - check if type change needed
          if existing_columns[col_name].type != col_type
            # Validate type change is safe
            if validate_type_change(table_name, col_name, col_type)
              forward_ops << { type: :change_column, table: table_name, column: col_name, new_type: col_type }
              rollback_ops << { type: :change_column, table: table_name, column: col_name, new_type: existing_columns[col_name].type }
            else
              raise Darwin::UnsafeTypeChangeError, 
                "Cannot safely convert #{col_name} from #{existing_columns[col_name].type} to #{col_type}. Existing data is incompatible."
            end
          end
        else
          # Column doesn't exist - add it
          forward_ops << { type: :add_column, table: table_name, column: col_name, column_type: col_type }
          rollback_ops << { type: :remove_column, table: table_name, column: col_name }
        end
      end
      
      # Plan removals
      columns_to_remove = existing_columns.keys - expected_columns.keys - %w[id created_at updated_at]
      columns_to_remove.each do |col_name|
        col = existing_columns[col_name]
        forward_ops << { type: :remove_column, table: table_name, column: col_name }
        rollback_ops << { type: :add_column, table: table_name, column: col_name, column_type: col.type }
      end
      
      { forward: forward_ops, rollback: rollback_ops.reverse }
    end
    
    private
    
    def self.collect_expected_columns(model)
      expected = {}
      
      model.blocks.where(block_type: 'attribute').each do |block|
        name, type = block.args
        expected[name] = type.to_sym
      end
      
      model.blocks.where(block_type: 'belongs_to').each do |block|
        assoc_name = block.args.first.to_sym
        options = Darwin::Interpreter.deep_symbolize_keys(block.options)
        foreign_key = options[:foreign_key] || "#{assoc_name}_id"
        expected[foreign_key.to_s] = :integer
      end
      
      expected
    end
    
    def self.validate_type_change(table_name, column_name, new_type)
      connection = ActiveRecord::Base.connection
      
      # Try casting a sample of data
      connection.execute(
        "SELECT #{connection.quote_column_name(column_name)}::#{new_type} 
         FROM #{connection.quote_table_name(table_name)} 
         LIMIT 100"
      )
      true
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn("Type change validation failed: #{e.message}")
      false
    end
  end
  
  class UnsafeTypeChangeError < StandardError; end
end
```

### Phase 5: Wrap DDL in Transactions

**5.1 Create SchemaExecutor** [3](#8-2) 

Execute operations transactionally with rollback capability:

```ruby
# lib/darwin/schema_executor.rb
module Darwin
  class SchemaExecutor
    def self.execute_migration(migration)
      migration.update!(status: :processing, started_at: Time.current)
      
      connection = ActiveRecord::Base.connection
      
      # PostgreSQL supports transactional DDL
      connection.transaction do
        migration.operations.each do |op|
          execute_operation(op)
        end
        
        # Reset schema cache after all operations
        connection.reset!
        
        migration.update!(
          status: :applied,
          completed_at: Time.current
        )
      end
      
    rescue => e
      # Transaction will auto-rollback
      migration.update!(
        status: :failed,
        error_message: "#{e.class}: #{e.message}",
        completed_at: Time.current
      )
      raise
    end
    
    def self.rollback_migration(migration)
      return unless migration.applied?
      
      connection = ActiveRecord::Base.connection
      
      connection.transaction do
        migration.rollback_operations.each do |op|
          execute_operation(op)
        end
        
        connection.reset!
        
        migration.update!(status: :pending)
      end
    end
    
    private
    
    def self.execute_operation(op)
      connection = ActiveRecord::Base.connection
      
      case op[:type].to_sym
      when :add_column
        connection.add_column(op[:table], op[:column], op[:column_type])
      when :remove_column
        connection.remove_column(op[:table], op[:column])
      when :change_column
        connection.change_column(
          op[:table], 
          op[:column], 
          op[:new_type],
          using: "CAST(#{op[:column]} AS #{op[:new_type]})"
        )
      else
        raise "Unknown operation type: #{op[:type]}"
      end
    end
  end
end
```

### Phase 6: Configure SolidQueue

**6.1 Add Queue Configuration** [4](#8-3) 

```yaml
# config/queue.yml (or add to existing config)
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: darwin_schema
      threads: 1  # Single thread to avoid concurrent DDL conflicts
      processes: 1
      polling_interval: 1
```

### Phase 7: Migration Path

**7.1 Gradual Rollout Steps**

1. **Deploy Phase 1-2**: Add columns and new callbacks (keep old callbacks temporarily)
2. **Monitor**: Verify jobs are being enqueued correctly
3. **Deploy Phase 3-5**: Remove old callbacks, enable async processing
4. **Backfill**: Mark all existing models as dirty and process them
5. **Monitor**: Watch for failed migrations and fix data issues

**7.2 Backfill Script**

```ruby
# lib/tasks/darwin.rake
namespace :darwin do
  desc "Backfill schema migrations for existing models"
  task backfill_schema_migrations: :environment do
    Darwin::Model.find_each do |model|
      model.mark_schema_dirty
      puts "Enqueued schema sync for #{model.name}"
    end
  end
end
```

## Summary

This plan decouples schema operations from the request cycle by:

1. **Dirty flags** (`schema_version`, `schema_dirty`) track when models need sync [1](#8-0) 
2. **Background jobs** (`SyncSchemaJob`, `DropSchemaJob`) process changes asynchronously via SolidQueue [5](#8-4) 
3. **Validation layer** (`SchemaPlanner.validate_type_change`) prevents data loss on type changes
4. **Transactional DDL** (`SchemaExecutor`) wraps operations for automatic rollback on failure
5. **Migration records** (`Darwin::SchemaMigration`) provide audit trail and rollback capability

The current `SchemaManager` logic is preserved but moved into `SchemaPlanner` and `SchemaExecutor`, maintaining compatibility while adding safety and performance. [6](#8-5) 

Wiki pages you might want to explore:
- [API Reference (paleologu/darwin)](/wiki/paleologu/darwin#12)
- [Working with Darwin (paleologu/darwin)](/wiki/paleologu/darwin#7)

### Citations

**File:** app/models/darwin/model.rb (L14-15)
```ruby
    after_commit :sync_schema_and_reload_runtime_constant, on: %i[create update]
    after_commit :drop_table_and_reload_runtime_constant, on: :destroy
```

**File:** spec/dummy/config/environments/production.rb (L49-51)
```ruby
  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
```

**File:** lib/darwin/schema_manager.rb (L5-43)
```ruby
    def self.sync!(model)
      table_name = "darwin_#{model.name.to_s.tableize}"
      connection = ActiveRecord::Base.connection

      ensure_table!(table_name)

      expected_columns = {}
      model.blocks.where(block_type: 'attribute').each do |block|
        name, type = block.args
        expected_columns[name] = type.to_sym
      end
      model.blocks.where(block_type: 'belongs_to').each do |block|
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
```

**File:** spec/dummy/db/queue_schema.rb (L29-45)
```ruby
  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "active_job_id" ], name: "index_solid_queue_jobs_on_active_job_id"
    t.index [ "class_name" ], name: "index_solid_queue_jobs_on_class_name"
    t.index [ "finished_at" ], name: "index_solid_queue_jobs_on_finished_at"
    t.index [ "queue_name", "finished_at" ], name: "index_solid_queue_jobs_for_filtering"
    t.index [ "scheduled_at", "finished_at" ], name: "index_solid_queue_jobs_for_alerting"
  end
```


Full conversation: 
https://deepwiki.com/search/could-you-evaluate-the-db-tabl_f967b727-0aa0-4861-a796-0978a686a2d9