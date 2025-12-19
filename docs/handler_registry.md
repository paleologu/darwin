# Darwin block handler registry

This PR introduces a pluggable handler architecture for persisted Darwin blocks so lifecycle callbacks can delegate to a dedicated object rather than inline case statements. Each handler wraps a specific `method_name` and is responsible for assembling, normalizing, and validating block arguments.

## What changed
- **Handler registry:** `Darwin::Blocks::Registry` now resolves a handler class for the current block `method_name`, allowing `Darwin::Block` callbacks to delegate to `handler` consistently instead of branching on `method_name`.
- **Dedicated handlers:** Attribute, association (including nested attributes), and validation blocks each have their own handler classes under `app/models/darwin/blocks/` implementing `assemble_args`, `normalize_args`, and `validate!` as appropriate for the block type.
- **Callback delegation:** `Darwin::Block` lifecycle hooks call `assemble_args`, `normalize_args`, and `validate!` on the resolved handler while keeping shared JSON coercion and positioning logic within the model.
- **Focused specs:** Specs cover the responsibilities of each handler in isolation (argument assembly, normalization rules, and validations) to keep the behavior explicit and testable.

## Why it matters
Centralizing block-specific behavior behind handlers keeps `Darwin::Block` small and makes it easier to extend support for new block types without modifying callback logic. It also makes each responsibility testable in isolation, which should reduce regressions when normalization or validation rules evolve.
