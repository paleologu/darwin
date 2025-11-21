Here’s a clear, complete `README_FOR_ROO.md` that you can drop into your repo — it explains *everything Roo needs to know* about the Darwin project, its moving parts, debugging history, and next steps.

---

# 🧠 `README_FOR_ROO.md`

## 1. Overview

**Darwin** is a dynamic runtime modeling engine for Rails.
It lets you **define models, attributes, validations, and associations at runtime**, store those definitions in the database, and **evaluate them into live ActiveRecord classes**.

The core idea:
`Darwin::Model` records represent runtime models (e.g. `Article`, `Author`, `Comment`),
and `Darwin::Block` records describe what that model should contain (`attribute`, `belongs_to`, `has_many`, etc.).
`Darwin::Runtime` interprets those blocks to define real Ruby classes.

---

## 2. Key Components

### `app/models/darwin/model.rb`

Represents a single dynamic model definition.
It has many `Darwin::Block`s, which describe individual parts of its behavior.

Key methods:

* `define_runtime_constant` — creates or fetches the runtime `Class` object for this model.
* `evaluate_runtime_blocks` — walks through all its `blocks` and applies them (via the interpreter) to the class.

### `app/models/darwin/block.rb`

Represents a building instruction for a runtime model.
Each block has:

* `method_name` — e.g. `"attribute"`, `"belongs_to"`, `"has_many"`, `"validates"`, etc.
* `args` — the arguments to the macro (e.g. attribute name).
* `options` — options hash (e.g. `{ dependent: :destroy }`).

Blocks are executed by the **interpreter**.

### `lib/darwin/interpreter.rb`

Translates each `Darwin::Block` into actual Ruby/Rails calls.
Example:

```ruby
case method_name
when "attribute"
  klass.attribute *args
when "has_many"
  klass.has_many *args, **options
when "belongs_to"
  klass.belongs_to *args, **options
end
```

This file is also where **association duplication** and **callback accumulation** can occur if reloads are not idempotent.

### `lib/darwin/runtime.rb`

Orchestrates all runtime models:

* `reload_all!` — rebuilds all runtime classes and applies their blocks in the right order.
* `suspend` — temporarily disables runtime reload hooks when creating models programmatically.

### `spec/support/test_helpers.rb`

Defines `setup_test_data!` — builds a realistic Author/Article/Comment setup inside Darwin for testing:

* `Author` has many `articles`
* `Article` belongs to `author` and has many `comments`
* `Comment` belongs to `article`
* Includes validations and nested attributes.

This is used by nearly all specs.

---

## 3. Known Issues and Context

### 🔥 Core Bug

The **`dependent: :destroy` callback fires twice** when destroying an `Article`.

**Root cause:**
When `Darwin::Runtime.reload_all!` runs multiple times, it re-applies association macros (like `has_many`) on the same runtime class **without clearing or guarding** existing definitions.

This leads Rails to register multiple destroy callbacks for the same association, so `dependent: :destroy` executes twice.

**Evidence:**

* Destroying an article deletes **two comments** instead of one.
* Re-running `reload_all!` increases callback counts.
* Inspecting callbacks shows duplicates.

---

## 4. Goals of the Current Work

### ✅ Completed

* Fixed serialization bug (`serialize :args, coder: YAML`).
* Confirmed that runtime reloading works.
* Reproduced dependent destroy issue.
* Verified that the issue persists across reloads.

### 🧩 In Progress

1. **Add diagnostic introspection** to confirm duplication:

   ```ruby
   Article.reflect_on_all_associations(:has_many)
   Article._destroy_callbacks.size
   ```
2. **Apply idempotent guard** to interpreter association macros:

   ```ruby
   unless klass.reflect_on_association(:comments)
     klass.has_many :comments, dependent: :destroy
   end
   ```
3. **Add regression tests** to ensure idempotency and correct dependent behavior.

### 🧱 Next Steps

* Run diagnostics to confirm the duplication hypothesis.
* Apply the guard fix in `lib/darwin/interpreter.rb`.
* Re-run `dependent_destroy_spec`.
* Add specs to test multiple reloads and idempotency.

---

## 5. The Testing Environment

### `spec/models/darwin/dependent_destroy_spec.rb`

Purpose: ensure destroying an `Article` removes its dependent `Comment`s exactly once.

Structure:

```ruby
before(:each) do
  setup_test_data!
  Darwin::Runtime.reload_all!
  # redefine Author, Article, Comment constants
end

it "destroys dependent comments when an article is destroyed" do
  author = Author.create!(name: "Jane Doe")
  article = Article.create!(title: "Post", author: author)
  article.comments.create!(message: "Test")
  expect { article.destroy }.to change { Comment.count }.by(-1)
end
```

Common failure modes:

* `expected -1 but got -2` → duplicate callbacks.
* `UnknownAttributeError: author` → association not defined (caused by stale reload).

### `spec/models/darwin/model_spec.rb`

Verifies basic CRUD, validations, and nested attributes.

---

## 6. How to Debug This System

### Runtime Inspection Commands

To confirm model state:

```ruby
Darwin::Model.all.map(&:name)
# => ["Author", "Article", "Comment"]

Article.reflect_on_association(:comments)
Article.reflect_on_all_associations(:has_many).count { |a| a.name == :comments }

Article._destroy_callbacks.map(&:filter)
Article._destroy_callbacks.count
```

To manually reset environment:

```ruby
Object.send(:remove_const, :Article) rescue nil
Darwin::Runtime.reload_all!
Article = Darwin::Model.find_by(name: "Article").runtime_constant
```

---

## 7. Recommended Fix (Idempotent Association Guard)

Inside `lib/darwin/interpreter.rb`, wrap all association macros:

```ruby
when "has_many"
  name, *rest = args
  next if klass.reflect_on_association(name)
  klass.has_many(name, **options.symbolize_keys)
```

Repeat for:

* `has_one`
* `belongs_to`

This ensures macros are applied only once per reload cycle.

---

## 8. Follow-up Tests to Add

### 1. Association Idempotency

```ruby
it "does not duplicate has_many :comments on repeated reloads" do
  Darwin::Runtime.reload_all!
  count1 = Article.reflect_on_all_associations(:has_many).count { |a| a.name == :comments }
  Darwin::Runtime.reload_all!
  count2 = Article.reflect_on_all_associations(:has_many).count { |a| a.name == :comments }
  expect(count2).to eq(count1)
end
```

### 2. Single Callback Assertion

```ruby
it "registers only one dependent destroy callback" do
  Darwin::Runtime.reload_all!
  destroys = Article._destroy_callbacks.count
  Darwin::Runtime.reload_all!
  expect(Article._destroy_callbacks.count).to eq(destroys)
end
```

### 3. Dependent Destroy Behavior

```ruby
it "destroys only its own comments" do
  a1 = Article.create!(title: "A1", author: Author.first)
  a2 = Article.create!(title: "A2", author: Author.first)
  c1 = a1.comments.create!(message: "for a1")
  c2 = a2.comments.create!(message: "for a2")

  expect { a1.destroy }.to change { Comment.count }.by(-1)
  expect(Comment.exists?(c2.id)).to be true
end
```

---

## 9. Summary

| Area                              | Status         | Notes                          |
| --------------------------------- | -------------- | ------------------------------ |
| Serialization bug                 | ✅ Fixed        | Updated syntax                 |
| Dependent destroy                 | ❌ Failing      | Double callback issue          |
| Duplicate association definitions | 🧩 Confirmed   | Likely root cause              |
| Idempotent reloads                | 🧩 Pending fix | Add guard clause               |
| Test coverage                     | 🧩 Partial     | Needs reload/idempotency specs |

---

## 10. Next Actions for Roo

1. **Revert** `dependent_destroy_spec.rb` to the “destroying 2 comments” baseline.
2. **Insert diagnostics** (reflection and callback count).
3. **Confirm duplication** after two reloads.
4. **Patch interpreter** with guard clause.
5. **Re-run spec** and confirm fix.
6. **Add idempotency tests**.
7. **Report results** in TODO.md and mark as resolved.

---

Would you like me to append a “Developer Notes” section with quick Ruby console commands Roo can run interactively (like a cheat sheet for debugging Darwin internals)?
