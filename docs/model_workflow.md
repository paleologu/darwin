# Working with Darwin Models

Use this playbook when you need to create or troubleshoot runtime models from the console, seeds, or background jobs. Everything below is derived from Deepwiki’s *Getting Started* + *Working with Darwin* sections and the code in `app/models/darwin/model.rb`.

## 1. Define Models and Blocks

```ruby
author   = Darwin::Model.create!(name: "Author")
article  = Darwin::Model.create!(name: "Article")
comment  = Darwin::Model.create!(name: "Comment")

author.blocks.create!(method_name: "attribute", args: ["name", "string"])
author.blocks.create!(method_name: "has_many", args: ["articles"], options: { dependent: "destroy" })

article.blocks.create!(method_name: "attribute", args: ["title", "string"])
article.blocks.create!(method_name: "has_many", args: ["comments"], options: { inverse_of: "article" })
article.blocks.create!(method_name: "accepts_nested_attributes_for", args: ["comments"])

comment.blocks.create!(method_name: "attribute", args: ["message", "text"])
comment.blocks.create!(method_name: "validates", args: ["message"], options: { presence: true })
```

Association args are normalized before persistence (e.g., `has_many :Comment` persists as `"comments"`), so you can accept user input as-is.

## 2. Reload Runtime

```ruby
Darwin::Runtime.reload_all!(builder: true)
```

- Builder mode ensures `Darwin::SchemaManager` adds/updates backing tables before classes are hydrated.
- The reload runs in two passes (define shells, then evaluate blocks by priority) to avoid circular dependency issues.

## 3. Bind Constants

```ruby
Author  = Darwin::Model.find_by(name: "Author").runtime_constant
Article = Darwin::Model.find_by(name: "Article").runtime_constant
Comment = Darwin::Model.find_by(name: "Comment").runtime_constant
```

`runtime_constant` retrieves the class shell; use `runtime_class` if you need to ensure recursively-associated models are loaded alongside it.

## 4. Use Like Standard ActiveRecord

```ruby
author = Author.create!(name: "Jane Doe")
article = Article.create!(title: "My Post", author: author)
article.comments.create!(message: "Great read!")
```

Everything ActiveRecord normally provides (validations, callbacks, scopes, nested attributes, associations) works here because the interpreter applies the same DSL methods directly to the runtime classes.

## 5. Debug Checklist

1. **Reload runtime:** `Darwin::Runtime.reload_all!(builder: true)`
2. **Inspect DSL:** `model.blocks.pluck(:method_name, :args, :options, :position)`
3. **Inspect runtime associations:** `Model.runtime_constant.reflect_on_all_associations.map { |a| [a.macro, a.name] }`
4. **Nested attributes:** `Model.runtime_constant.nested_attributes_options.keys`
5. **Schema drift:** If SQLite complains about missing columns, delete `spec/dummy/db/*.sqlite3` then rerun `BUNDLE_WITHOUT=development bundle exec rails db:prepare` (dev + test)

## 6. Cleaning Up

- Destroying a `Darwin::Model` automatically drops the backing `darwin_*` table and reloads runtime classes.
- Run `Darwin::SchemaManager.cleanup!` to drop orphaned tables from deleted models (e.g., after manual DB edits).

## References

- `README.md` – quick demo + frontend pointers.
- `docs/runtime_architecture.md` – deep dive into block priority + multi-pass init.
- Deepwiki pages: *Working with Darwin*, *Multi-Pass Initialization Pattern*, *Testing Darwin Applications*.
