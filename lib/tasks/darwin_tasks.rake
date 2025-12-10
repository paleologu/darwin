# frozen_string_literal: true

if Rake::Task.task_defined?('assets:precompile')
  Rake::Task['assets:precompile'].enhance(['darwin:tailwindcss:build'])
else
  Rake::Task.define_task("assets:precompile": ['darwin:tailwindcss:build'])
end
