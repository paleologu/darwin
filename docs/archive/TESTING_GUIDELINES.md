# Darwin Testing Guidelines

This document outlines the testing philosophy and technical setup for the Darwin gem. Adhering to these guidelines is crucial for maintaining a stable and reliable codebase.

## 1. Core Philosophy: Self-Contained, In-Memory Testing

Our testing strategy is built around a **self-contained, in-memory test environment**. We do **not** use a dummy Rails application. This approach was chosen after significant challenges with load order and environment mismatches that a dummy app introduced.

The key benefits of this approach are:
- **Speed**: In-memory SQLite is extremely fast.
- **Reliability**: Tests are consistent and not dependent on the state of an external application or database.
- **Simplicity**: The entire test environment is configured in a single file (`spec/rails_helper.rb`), making it easy to understand and manage.

## 2. The Test Environment (`spec/rails_helper.rb`)

The `spec/rails_helper.rb` file is the heart of our test setup. It is responsible for:
1.  **Loading Rails and RSpec**: It boots a minimal Rails environment.
2.  **Loading the Darwin Engine**: It directly requires the `darwin` gem.
3.  **Defining the Database Schema**: It uses `ActiveRecord::Schema.define` to create the necessary `darwin_models` and `darwin_blocks` tables in an in-memory SQLite database.
4.  **Mimicking Production**: The schema is defined to be as close as possible to the production PostgreSQL environment. For example, it uses the `json` column type as a stand-in for `jsonb`.
5.  **Manual Loading**: It manually requires the engine's models to ensure the correct load order.

## 3. How to Write New Tests

When adding new tests, follow these guidelines:

-   **Test Files**:
    -   Tests for models should go in `spec/models/darwin/`.
    -   Tests for library code (like the runtime or interpreter) should go in `spec/lib/darwin/`.
-   **Test Data**: Use the `setup_test_data!` helper method in `spec/support/test_helpers.rb` to create a consistent set of `Darwin::Model` and `Darwin::Block` records for your tests. This method is automatically included in all specs.
-   **Assertions**: Use standard RSpec expectations to assert the behavior of your code.

## 4. How to Run the Tests

To run the entire test suite, execute the following command from the root of the repository:

```bash
bundle exec rspec
```

To run a specific file, pass the file's path to the `rspec` command:

```bash
bundle exec rspec spec/models/darwin/model_spec.rb
```

## 5. Common Pitfalls and Troubleshooting

-   **`NameError: uninitialized constant`**: If you encounter this error, it likely means that a model or class is not being loaded correctly. Ensure that the file is being required in `spec/rails_helper.rb` or that the load path is configured correctly.
-   **Database Mismatches**: If a test passes locally but fails in the host application, the most likely cause is a difference between the test schema in `spec/rails_helper.rb` and the production schema. Ensure that the column types and constraints are as closely aligned as possible.