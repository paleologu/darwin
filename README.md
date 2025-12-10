# Darwin: A Dynamic Runtime Modeling Engine for Rails

Darwin is a Rails engine that allows you to define ActiveRecord models, attributes, validations, and associations at runtime. These definitions are stored in the database and evaluated into live Ruby classes, providing a powerful way to build highly dynamic, data-driven applications.

## Architecture Cheat Sheet

- **Universal DSL** – every macro call (`attribute`, `has_many`, `validates`, etc.) is persisted as `method_name`, `args`, `options`, and optional `body` in `darwin_blocks`. That uniform shape is what makes the runtime deterministic.
- **Multi-Pass Initialization** – runtime reloads run in two passes: Pass 1 defines empty classes under `Darwin::Runtime`, Pass 2 sorts blocks by [`Darwin::Runtime.block_priority`](docs/runtime_architecture.md#block-priority) and evaluates them via the interpreter so dependencies (columns → associations → validations) are satisfied.
- **Schema Sync** – builder-mode operations (`builder: true`) call `Darwin::SchemaManager` to create/alter backing tables before runtime-only reloads (`builder: false`) hydrate classes.
- **Servus Services** – complex workflows live in Servus service objects (`app/services/**`), generated via `rails g servus:service`. See [docs/servus.md](docs/servus.md) for conventions.

For the full runtime walkthrough (flow diagrams, block types, troubleshooting), read [docs/runtime_architecture.md](docs/runtime_architecture.md).

## 1. Core Concept: Dynamic Runtime

Darwin's primary feature is its ability to construct ActiveRecord models dynamically based on schema definitions stored in the database. This allows for immense flexibility but introduces a unique architectural pattern to handle model interdependencies.

### The Multi-Pass Initialization Pattern

To ensure stability, Darwin's runtime employs a **Multi-Pass Initialization Pattern** to safely load all dynamic models, especially when there are circular dependencies (e.g., `Author` -> `Articles`, `Article` -> `Author`). This pattern guarantees that model dependencies are met before they are needed.

The loading process is broken into several distinct passes:
1.  **Class Definition**: The runtime first defines all model classes as empty "shells."
2.  **Attribute Evaluation**: It populates the shells with their database columns.
3.  **`belongs_to` Association Evaluation**: It defines the "child-to-parent" side of relationships.
4.  **`has_many` / `has_one` Association Evaluation**: It defines the "parent-to-child" side of relationships.
5.  **Other Blocks Evaluation**: Finally, it adds remaining behaviors like validations and callbacks.

A deep understanding of this pattern is crucial for any developer working on this gem. For a detailed explanation, please read the **[Darwin Runtime Architecture Documentation](docs/runtime_architecture.md)**.

## 2. Installation

Add this line to your application's Gemfile:

```ruby
gem 'darwin', path: '../darwin' # Or the appropriate gem source
```

And then execute:

```bash
$ bundle
```

Darwin currently targets SQLite for the engine and dummy app. PostgreSQL adapters have been removed; migrations use `json` columns (not `jsonb`).

Install the migrations and run them:

```bash
$ rails darwin:install:migrations
# OR
$ bundle exec rake railties:install:migrations FROM=darwin

$ rails db:migrate
```

## 3. Usage Guide

This guide will walk you through defining and using a set of dynamic models: `Author`, `Article`, and `Comment`.

### Step 1: Define the Models in the Database

The first step is to create records in the `darwin_models` and `darwin_blocks` tables. These records define the structure and behavior of your runtime models.

Association block arguments are normalized before persistence (`has_many :comment` is stored as `"comments"`, `belongs_to :Phone` as `"phone"`), so user-entered casing/pluralization is fixed at save time. The interpreter assumes stored values are already normalized.

You can do this programmatically, for example in a Rails console (`rails c`):

```ruby
# Clear any existing models
Darwin::Model.destroy_all


  author_model = Darwin::Model.create!(name: "Author")
  article_model = Darwin::Model.create!(name: "Article")
  comment_model = Darwin::Model.create!(name: "Comment")

  # Author attributes and validations
  author_model.blocks.create!(method_name: "attribute", args: ["name", "string"])
  author_model.blocks.create!(method_name: "validates", args: ["name"], options: { presence: true })
  author_model.blocks.create!(method_name: "has_many", args: ["articles"])

  # Article attributes, validations, and associations
  article_model.blocks.create!(method_name: "attribute", args: ["title", "string"])
  article_model.blocks.create!(method_name: "validates", args: ["title"], options: { presence: true })
  article_model.blocks.create!(method_name: "has_many", args: ["comments"], options: { inverse_of: "article" })
  article_model.blocks.create!(method_name: "accepts_nested_attributes_for", args: ["comments"])


  # Comment attributes, validations, and associations
  comment_model.blocks.create!(method_name: "attribute", args: ["message", "text"])
  comment_model.blocks.create!(method_name: "validates", args: ["message"], options: { presence: true })


```

### Step 2: Load the Runtime Models

Once the definitions are in the database, you need to tell the Darwin runtime to load them.

```ruby
Darwin::Runtime.reload_all!
```

> 💡 **Builder vs Runtime mode**: UI interactions and seed scripts that mutate schema should call `Darwin::Runtime.reload_all!(builder: true)` so `Darwin::SchemaManager` stays in sync. Application boot typically runs without the flag (defaults to `builder: false`) because the schema is already prepared.

### Step 3: Assign the Runtime Classes to Constants

To use the newly defined models as you would any other ActiveRecord class, assign them to constants.

```ruby
Author  = Darwin::Model.find_by(name: "Author").runtime_constant
Article = Darwin::Model.find_by(name: "Article").runtime_constant
Comment = Darwin::Model.find_by(name: "Comment").runtime_constant
```

### Step 4: Use Your Dynamic Models!

You can now use `Author`, `Article`, and `Comment` just like regular ActiveRecord models.

```ruby
# Create instances
author = Author.create!(name: "Jane Doe")
article = Article.create!(title: "My First Post", author: author)
comment = article.comments.create!(message: "Great post!")

# Access associations
puts article.author.name # => "Jane Doe"
puts author.articles.first.title # => "My First Post"

# Use nested attributes
nested_article = Article.create!(
  title: "Nested Attributes Test",
  author: author,
  comments_attributes: [{ message: "First comment!" }, { message: "Second comment!" }]
)
puts nested_article.comments.size # => 2
```

## 4. Testing

The Darwin gem uses a self-contained, in-memory RSpec test suite. To run the tests, execute the following command from the root of the repository:

```bash
bundle exec rspec
```

To prep the dummy app databases locally:

```bash
cd spec/dummy
BUNDLE_WITHOUT=development bundle exec rails db:prepare
BUNDLE_WITHOUT=development bundle exec rails db:prepare RAILS_ENV=test
```


## 5. Running the Dummy App in Development

Use the Procfile runner to boot both the Rails server and Solid Queue worker so background jobs such as `Darwin::DemoJob` can process.

```bash
cd spec/dummy
PORT=3000 bundle exec foreman start -f Procfile.dev
```

This command launches `./bin/rails server` and `./bin/jobs start` together. Do not rely on `bin/dev` or `rails server` alone because they won’t start the Solid Queue worker and queued jobs will sit idle.

## 6. Frontend stack (Stimulus, Turbo, importmap, ViewComponent, Tailwind)

Darwin ships editor and client importmaps managed inside the engine. Load them from your host layout:

Asset compilation:
```erb
rails darwin:tailwindcss:build 
```

```erb
<%= stylesheet_link_tag "darwin/tailwind", "data-turbo-track": "reload" %>
<%= darwin_editor_javascript_tags %>
```

Stimulus controllers live in `app/assets/javascripts/darwin/editor` and are pinned via `config/editor_importmap.rb`. Components follow the ViewComponent pattern under `app/components/darwin/**`, so engine-provided UI can ship co-located Stimulus controllers and Tailwind styles without depending on the host app’s asset pipeline.

## 7. Debugging Cheat Sheet

Here are some useful commands for debugging the Darwin runtime in a Rails console.

## 8. Services 
Business logic & non-standard operations are delegated to Servus services. Read the **[servus documentation](docs/servus.md)** (and use Deepwiki) before adding new workflows.

- Generate scaffolding with `rails g servus:service namespace/action args` so the service, spec, and JSON schemas stay in sync.
- Entry points inherit from `Servus::Base`, take keyword args only, and expose a zero-argument `#call` that returns a `Servus::Support::Response` via `success(...)` / `failure(...)` helpers.
- Always call services and downstream services via `.call` (or `.call_async`) to get logging, schema validation, benchmarking, and consistent error handling.
- Support classes live under `app/services/.../support` and should never inherit from `Servus::Base` nor be invoked directly.

### Reset Runtime Environment

```ruby
# Remove stale runtime constants
%w[Author Article Comment].each do |const|
  Object.send(:remove_const, const.to_sym) rescue nil
end

# Reload all runtime models from the database
Darwin::Runtime.reload_all!

# Rebind constants to live runtime classes
Author  = Darwin::Model.find_by(name: "Author").runtime_constant
Article = Darwin::Model.find_by(name: "Article").runtime_constant
Comment = Darwin::Model.find_by(name: "Comment").runtime_constant
```

### Inspect Associations

```ruby
# List all associations for a model
Article.reflect_on_all_associations.map { |a| [a.macro, a.name] }
# => [[:belongs_to, :author], [:has_many, :comments]]

# Count how many times an association is defined (should be 1)
Article.reflect_on_all_associations(:has_many).count { |a| a.name == :comments }
```

### Inspect Callbacks

```ruby
# View destroy callbacks
Article._destroy_callbacks.map(&:filter)

# Count them (should not increase after a reload)
Article._destroy_callbacks.count
```

### Explore Runtime Classes

```ruby
# Check attributes
Article.attribute_names

# Check column metadata
Article.columns_hash.keys
```

### Author
My name is John.

## 9. Further Reading

- [docs/runtime_architecture.md](docs/runtime_architecture.md) – how multi-pass reloads, block priority, and schema sync interplay.
- [docs/model_workflow.md](docs/model_workflow.md) – step-by-step cookbook for defining and using runtime models.
- [docs/servus.md](docs/servus.md) – service layer conventions, generators, and error-handling helpers.
