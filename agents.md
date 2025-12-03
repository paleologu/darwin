# Agent Notes for Darwin Repo

This project is a Rails engine that builds runtime ActiveRecord models from DB-stored blocks. Key workflow and booby traps for helpers/LLMs:

## Environment / Tooling
- Use Ruby 3.3.5 with rbenv shims (e.g., `/Users/eugen/.rbenv/shims/bundle exec ...`). System Ruby (2.6) will not satisfy bundler 2.5.16.
- Bundler: 2.5.16. If `bundle` complains, explicitly call the shim path.
- Database: SQLite only. `pg` is removed; migrations use `json`, not `jsonb`.

## Migrations and Tests
- Engine migration lives at `db/migrate/20250926150200_create_darwin_tables.rb` (JSON columns for `darwin_models.columns`, `darwin_blocks.args/options`).
- `spec/rails_helper.rb` runs migrations from `db/migrate`; there are no dummy migrations. Don’t add conflicting migration names.
- Preparing DBs manually:
  - `cd spec/dummy && BUNDLE_WITHOUT=development bundle exec rails db:prepare`
  - `cd spec/dummy && BUNDLE_WITHOUT=development bundle exec rails db:prepare RAILS_ENV=test`
- Run tests from root: `bundle exec rspec` (uses engine migrations only).

## Runtime / Interpreter
- Association args are normalized **before save** in `Darwin::Block` (has_many → plural underscore, belongs_to/has_one → singular underscore). Interpreter assumes persisted args are already normalized; do not “fix” them again.
- `Darwin::SchemaManager` avoids SQLite-only issues (`change_column` without `using:`) and derives foreign keys from underscored belongs_to args.
- `Darwin::Column` implements `dump/load` for serialized `columns` JSON.
- Runtime reload order: classes first, then blocks sorted by priority in `Darwin::Runtime.block_priority`.

## Routing / Forms
- Engine routes are wrapped with `constraints format: /html|turbo_stream/` to avoid asset hits; `/icon.svg` should not reach controllers.
- Model builder: `Darwin::Model` accepts nested attributes for `blocks` only (not `columns`).

## Known Gotchas
- Using bare `rails` in repo root may invoke the generator; use `bundle exec rails ...` (via shim) instead.
- Tidewave was removed; keep `BUNDLE_WITHOUT=development` for test env prep to avoid that gem.
- If DB errors mention missing `columns` field, ensure engine migration ran and SQLite DBs aren’t stale (delete `spec/dummy/db/*.sqlite3` and re-prepare).
- Development stack requires both the web server and Solid Queue worker. Run `cd spec/dummy && PORT=3000 bundle exec foreman start -f Procfile.dev` to start `bin/rails server` and `bin/jobs start` together. Do not run `bin/dev` or `rails server` by themselves because the Solid Queue process will be missing and jobs won’t run.

## Quick Debug Commands
- Reload runtime after editing blocks: `Darwin::Runtime.reload_all!(builder: true)`.
- Inspect nested attributes on a runtime class: `Model.runtime_constant.nested_attributes_options.keys`.
- Check stored block args: `Darwin::Model.find_by(name: 'Phone').blocks.pluck(:method_name, :args)`.
