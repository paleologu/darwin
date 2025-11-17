# Product Brief: Darwin

## 1. Vision

Darwin is a meta-framework for Ruby on Rails that enables the creation and management of ActiveRecord models at runtime. Instead of defining models in static `.rb` files, developers and administrators can define models, attributes, associations, and validations through a user interface or API. These definitions are stored in the database and are dynamically translated into live, fully-functional ActiveRecord classes.

The core vision is to create a "declarative ActiveRecord"—a system where the structure and behavior of a model are described as data, not code. This approach provides a powerful, flexible, and accessible way to build and evolve data models without requiring traditional code deployments, making it ideal for applications that require a high degree of customization, rapid prototyping, or user-defined data structures.

## 2. Features

The development of Darwin is planned in three phases:

### Phase 1: Core Model Engine (Current)

*   **Dynamic Model Definition:** Create, update, and delete `Darwin::Model` records, which represent the metadata for a runtime ActiveRecord model.
*   **Attribute Blocks:** Define attributes for each model with support for standard Rails data types (string, integer, text, boolean, etc.).
*   **Association Blocks:** Establish `belongs_to`, `has_many`, and `has_one` relationships between dynamic models.
*   **Validation Blocks:** Apply standard ActiveRecord validations (e.g., `presence`, `uniqueness`, `length`) to model attributes.
*   **Runtime Class Generation:** Dynamically create and load ActiveRecord classes in memory based on the database definitions.
*   **Dynamic Schema Management:** Automatically create, modify, and drop database tables and columns to match the `Darwin::Model` definitions.

### Phase 2: Advanced Features & UI

*   **User Interface for Model Building:** A web-based interface for non-developers to create and manage Darwin models, attributes, associations, and validations.
*   **Expanded Block Library:** Support for more advanced ActiveRecord features, including:
    *   `has_one_attached` / `has_many_attached` (ActiveStorage)
    *   `has_rich_text` (ActionText)
    *   `has_one, has_and_belongs_to_many, has_many through:` associations
    *   Callbacks (`before_save`, `after_create`, etc.)
    *   Scopes
*   **API for Model Management:** A RESTful or GraphQL API for programmatic management of Darwin models.

### Phase 3: Ecosystem & Integration

*   **Multitenancy:** Migrate to SQLite (with support for JSONB columns). Models & Runtimes scoped to tenants.
*   **Pluggable Interpreter Modules:** An extensible architecture that allows developers to add support for new block types and integrations (e.g., custom gems, third-party services).
*   **Import/Export:** Functionality to export Darwin model definitions to JSON or YAML, and import them into other Darwin-powered applications.
*   **Versioning:** The ability to version model definitions, allowing for rollbacks and a clear audit trail of changes.
*   **Enhanced Security & Permissions:** Granular control over who can create, modify, and delete Darwin models.
*   **Rails engine** Mountable into rails apps with the option to scope Darwin to tenants/owner (Users, Project, Site, Organization). Customizable UI (like Avo) and straightforward DSL for handling Darwin within host apps.