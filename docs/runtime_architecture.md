# Runtime Architecture

This cheat sheet distills the Deepwiki runtime docs plus the implementation in `lib/darwin/runtime.rb`, `lib/darwin/interpreter.rb`, and `app/models/darwin/model.rb` so you can keep the moving pieces straight without rereading the entire codebase.

## Universal DSL Storage

- Every block stored in `darwin_blocks` uses the same payload: `method_name`, `args` (JSON array), `options` (JSON hash), optional `body`, and `position`.
- Example: `has_many :posts, dependent: :destroy` is saved as `method_name="has_many"`, `args=["posts"]`, `options={"dependent":"destroy"}`.
- Because the shape is uniform, the interpreter can evaluate blocks without conditional persistence logic.

## Multi-Pass Initialization Pattern

1. `Darwin::Runtime.reload_all!` clears the `Darwin::Runtime` namespace and eager-loads every `Darwin::Model` with its blocks.
2. **Pass 1 – Define shells:** runtime defines empty ActiveRecord subclasses under `Darwin::Runtime` with `table_name = "darwin_#{model.name.tableize}"` (no model callbacks involved).
3. **Pass 2 – Evaluate blocks:** collect every block, sort by priority, then pipe them through `Darwin::Interpreter.evaluate_block`.
- This guarantees that every association/validation runs against an already-defined class and a prepared schema (see below).

## Block Priority

`Darwin::Runtime.block_priority` enforces evaluation order. Lower numbers run first.

| Priority | Block types | Why |
| --- | --- | --- |
| 0 | `attribute` | Columns must exist before anything references them. |
| 1 | `belongs_to`, `has_one`, `has_many` | Associations need the owning classes and columns. |
| 2 | `has_one_attached`, `has_many_attached` | Attachments expect associations to be wired. |
| 3 | `validates` | Validations should run only after attributes/associations exist. |
| 4 | `accepts_nested_attributes_for` | Depends on association definitions. |
| 5+ | callbacks, scopes, everything else | Run last; safe default is `99` for unknown methods. |

If you add new block types, update this table **and** the method in `lib/darwin/runtime.rb`.

## Builder vs Runtime Mode

- The interpreter takes a `builder:` flag. Builder mode (`true`) ensures columns/tables via `Darwin::SchemaManager` before applying DSL calls.
- UI/model-editor flows should call `Darwin::Runtime.reload_all!(builder: true)` so schema and runtime stay in sync.
- Boot-time reloads normally omit the flag (defaults to `false`) to avoid redundant DDL inside app servers.

## Schema Sync Path

`Darwin::SchemaManager` centralizes DDL operations:

1. `sync!(model)` ensures the runtime table exists, inspects expected columns from attribute + belongs_to blocks, and adds/changes/removes columns accordingly.
2. Association helpers auto-create inverse `belongs_to` blocks (e.g., defining `has_many :articles` on Author ensures Article receives/maintains `belongs_to :author`).
3. Attachments and nested attributes rely on associations existing first, so schema changes piggyback on the earlier block priorities.

## Debug Flow

1. `Darwin::Runtime.reload_all!(builder: true)` – clean slate for both schema + runtime constants.
2. Inspect runtime associations: `Model.runtime_constant.reflect_on_all_associations`.
3. Inspect serialized DSL: `Darwin::Model.find_by(name: ...).blocks.pluck(:method_name, :args, :options)`.
4. If schema errors mention missing columns, delete stale SQLite DBs under `spec/dummy/db` and rerun `BUNDLE_WITHOUT=development bundle exec rails db:prepare` (dev + test) per AGENTS.md.

## Further Reading

- `lib/darwin/runtime.rb` – orchestration and block priority map.
- `lib/darwin/interpreter.rb` – interpreter cases for each block type + guard clauses.
- `lib/darwin/schema_manager.rb` – SQLite-friendly DDL helpers.
- Deepwiki pages: *Overview*, *Multi-Pass Initialization Pattern*, *Runtime System*, *Block Priority and Evaluation Order*.
