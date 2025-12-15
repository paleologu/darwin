# # frozen_string_literal: true

# module Darwin
#   # Serializes schema sync/drop and runtime reload behind a per-model file lock.
#   class SchemaSyncJob < ApplicationJob
#     queue_as :darwin_default

#     def self.inline?
#       Rails.env.test? || ENV['DARWIN_SCHEMA_SYNC_INLINE'] == '1'
#     end

#     def self.run(model_id:, action: 'sync', builder: true, model_name: nil, table_name: nil)
#       if inline?
#         perform_now(model_id, action:, builder:, model_name:, table_name:)
#       else
#         perform_later(model_id, action:, builder:, model_name:, table_name:)
#       end
#     end

#     def perform(model_id, action: 'sync', builder: true, model_name: nil, table_name: nil)
#       model = Darwin::Model.find_by(id: model_id)

#       lock_key = model&.id || model_id || model_name || table_name || 'global'
#       with_lock(lock_key) do
#         case action.to_s
#         when 'sync'
#           return unless model
#           Darwin::SchemaManager.sync!(model)
#           Darwin::Runtime.reload_all!(current_model: model, builder:)
#         when 'drop'
#           target_table = table_name || (model ? "darwin_#{model.name.to_s.tableize}" : nil)
#           next unless target_table
#           Darwin::SchemaManager.drop_table!(target_table)
#           Darwin::Runtime.reload_all!(builder:)
#         else
#           Rails.logger.warn("[Darwin::SchemaSyncJob] unknown action=#{action.inspect}")
#         end
#       end
#     end

#     private

#     def with_lock(key)
#       lock_path = Rails.root.join('tmp', 'darwin_locks', "lock_#{key}.lock")
#       FileUtils.mkdir_p(lock_path.dirname)
#       File.open(lock_path, 'w') do |f|
#         f.flock(File::LOCK_EX)
#         yield
#       ensure
#         f.flock(File::LOCK_UN) if f
#       end
#     end
#   end
# end
