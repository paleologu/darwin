# Darwin Runtime Architecture: The Multi-Pass Initialization Pattern
# Task 1.
## 1. Overview

The Darwin gem dynamically constructs ActiveRecord models at runtime based on definitions stored in the database. This dynamic nature presents a unique challenge, especially when models have circular dependencies (e.g., an `Author` has many `Articles`, and an `Article` belongs to an `Author`).

To ensure stability and prevent critical loading errors like `ActiveModel::UnknownAttributeError` or `NameError: uninitialized constant`, the runtime employs a **Multi-Pass Initialization Pattern**. This document outlines this architectural principle, which is fundamental for any developer working on or with the Darwin gem.

## 2. The Core Problem: Circular Dependencies and Loading Order

When models are defined in static `.rb` files, Rails' autoloading mechanisms can typically resolve dependencies. However, in Darwin, models are built from the database. A naive, single-pass approach where each model is fully built one by one will fail.

For example, if the system tries to build the `Article` class and its `belongs_to :author` association, it needs the `Author` class to exist. Conversely, if it defines `Author` first, its `has_many :articles` association needs the `Article` class. This creates a classic circular dependency problem that requires a more sophisticated loading strategy.

## 3. The Solution: Multi-Pass Initialization

To solve this, the loading process is broken into several distinct, sequential passes, orchestrated by `Darwin::Runtime.reload_all!`. This ensures that dependencies are available before they are needed.

### Pass 1: Class Definition

-   **Goal**: Define the basic "shell" for every single runtime model.
-   **Method**: `Darwin::Model#define_runtime_constant`
-   **Process**: The system iterates through all `Darwin::Model` records and creates a new class in the `Darwin::Runtime` namespace (e.g., `Darwin::Runtime::Article`). This class inherits from `ApplicationRecord` and has its `table_name` set.
-   **Crucially, no blocks (attributes, associations, etc.) are evaluated in this phase.**

At the end of this phase, all model constants exist and are available for reference, but they are empty shells.

### Pass 2: Attribute Evaluation

-   **Goal**: Populate the shells with their database columns.
-   **Method**: `Darwin::Model#evaluate_runtime_blocks(attributes_only: true)`
-   **Process**: The system iterates through all models a second time, evaluating only the `attribute` blocks. This ensures that all models are aware of their own columns before any relationships are built.

### Pass 3: `belongs_to` Association Evaluation

-   **Goal**: Define the "child-to-parent" side of relationships.
-   **Method**: `Darwin::Model#evaluate_runtime_blocks(belongs_to_only: true)`
-   **Process**: The system evaluates all `belongs_to` associations. This is a critical step, as it typically involves adding foreign key columns (`author_id`) to the child model's table.

### Pass 4: `has_many` and `has_one` Association Evaluation

-   **Goal**: Define the "parent-to-child" side of relationships.
-   **Method**: `Darwin::Model#evaluate_runtime_blocks(has_many_only: true)`
-   **Process**: With all classes and foreign keys in place, the system can now safely create `has_many` and `has_one` associations.

### Pass 5: Other Blocks Evaluation

-   **Goal**: Add remaining behaviors like validations and callbacks.
-   **Method**: `Darwin::Model#evaluate_runtime_blocks(other_blocks_only: true)`
-   **Process**: The final pass evaluates all remaining blocks, such as `validates`, `scope`, and `accepts_nested_attributes_for`.

## 4. Guideline for Future Developers

When working with the Darwin runtime, always keep this multi-pass pattern in mind. If you encounter loading errors, the root cause is likely a violation of this dependency order.

-   The primary entry point for this process is `Darwin::Runtime.reload_all!`. Start your debugging and analysis there.
-   The `Darwin::Interpreter` is responsible for translating a single block into an ActiveRecord macro call.
-   The `Darwin::Model#evaluate_runtime_blocks` method is responsible for filtering which blocks to evaluate during each pass.