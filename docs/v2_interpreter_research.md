# Darwin v2 Interpreter Research

Context: planning a refactor to separate database/schema work and model creation from the runtime interpreter, and to move the current callback-driven flow in `app/models/darwin/model.rb` into explicit services/form builders.

## Current Runtime Architecture (Deepwiki)
- Multi-pass load: `Darwin::Runtime.reload_all!` defines shells then evaluates blocks sorted by `block_priority` so attributes -> associations -> attachments -> validations -> nested attributes -> other blocks load in order (Deepwiki: Runtime Architecture / Block Priority).
- Universal DSL: every block persists `method_name`, `args`, `options`, `body`, `position`, enabling deterministic evaluation by `Darwin::Interpreter.evaluate_block` (Deepwiki: Overview).
- Builder flag: `builder: true` paths call `Darwin::SchemaManager` to create/alter tables and reset schema cache; `builder: false` skips DDL for boot-time reloads (Deepwiki: Runtime Architecture).
- Idempotency safeguards: `unload_runtime_constants!` clears runtime classes before reload; interpreter guards skip associations already reflected to avoid duplicated callbacks/associations (Deepwiki: Troubleshooting + task_report_20251024 lessons).
- Data coercion: interpreter uses deep symbolization and integer casting to turn stored JSON back into Ruby types; `dependent` must be a symbol, validation options are deep-casted (Deepwiki: Historical issues).
- Normalization contract: association args are normalized before persistence; interpreter assumes args are already underscored/pluralized as needed (Deepwiki: Overview / SchemaManager notes).

## Callback Coupling Today
- `Darwin::Model` lifecycle callbacks trigger `SchemaManager.sync!`/`drop!` and `Runtime.reload_all!(builder: true)` after commit to keep schema + runtime aligned (Deepwiki: Overview).
- Risks if callbacks are removed without replacement: stale schema, stale runtime constants, duplicate associations/callbacks if reloads skip `unload_runtime_constants!`, and boot-time `UnknownAttributeError`/`NameError` when block priority is bypassed.
- Builder mode is slower due to DDL; production/runtime refreshes should stay `builder: false` once schema is in sync (Deepwiki: Runtime Architecture).

## What Must Move Out of `Darwin::Model`
- Callbacks extracted: `after_commit :sync_schema_and_reload_runtime_constant` on create/update and `after_commit :drop_table_and_reload_runtime_constant` on destroy (removed). These wrapped `SchemaManager.sync!`/`drop!` and `Runtime.reload_all!(builder: true)`.
- Runtime helpers removed: `define_runtime_constant` / `runtime_class` were responsible for creating runtime shells and evaluating blocks; runtime now defines shells directly in `Darwin::Runtime` and controllers/services use `Darwin::RuntimeAccessor`.
- Associated model discovery helpers were tied to the old runtime_class flow; services can reintroduce dependency discovery if needed.

## Controller Surface (current)
- `Darwin::ModelsController` creates/updates/destroys models directly; it relies on model callbacks for schema + runtime side effects (app/controllers/darwin/models_controller.rb:6-48).
- Strong params permit `blocks_attributes` including `args_name/args_type`, options for validations, and `_destroy` (app/controllers/darwin/models_controller.rb:63-73).
- No explicit builder/runtime branching in the controller; all side effects are implicit via callbacks.

## Block Handling + Normalization Contract
- `Darwin::Block` assembles `args` from form fields and normalizes association args (underscore + pluralize/singularize as needed) before validation (app/models/darwin/block.rb:24-67).
- Validation guards: attribute blocks require name/type; validation blocks require args and options; options for validations are cleaned to the selected `validation_type` (app/models/darwin/block.rb:69-99).
- Position is auto-assigned on create; `touch: true` on the model keeps timestamps in sync (app/models/darwin/block.rb:11-21, 101-113).

## Requirements for a Model Builder Service (to replace callbacks)
- Placement: keep services under `app/services/darwin/**` (per decision) using Servus conventions (`Darwin::…::Service` entrypoints, support classes in `support/`).
- Persist model + nested blocks via form builder; ensure normalization still runs (either keep `Darwin::Block` callbacks/validations or replicate them).
- After successful create/update: invoke `SchemaManager.sync!(model)` then `Runtime.reload_all!(current_model: model, builder: true)` to keep schema + runtime current. Ensure `unload_runtime_constants!` is respected to avoid duplicate associations/callbacks (Deepwiki: duplicate-callback fix).
- On destroy: invoke `SchemaManager.drop!(model)` then `Runtime.reload_all!(builder: true)` to purge schema + runtime constant.
- Builder flag discipline: use `builder: true` only for flows that mutate schema; production/runtime-only reloads should call `builder: false` once schema is consistent (Deepwiki: builder mode cautions).
- Dependency-aware eval: continue sorting blocks by `block_priority` before evaluation; any service-driven reload must preserve this ordering.
- Type coercion: ensure options passed to interpreter are symbolized/cast (e.g., `dependent`, numeric validation limits) to prevent `ArgumentError`.
- Idempotency: do not skip `SchemaManager.ensure_table!`/`ensure_column!` behavior currently baked into `define_runtime_constant` + interpreter builder paths; service must keep DDL idempotent to avoid repeated migrations.
- Error handling: surface `SchemaManager`/`Runtime.reload_all!` failures back to the controller (likely via Servus response) so UI can render errors instead of raising.

## Controller/Form Builder Implications
- Controllers (`new`/`edit`/`create`/`update`/`destroy`) should call the model-builder service instead of `save!/update!` so DDL + runtime reloads happen explicitly and errors are returned via service responses.
- `new`/`edit` should initialize via the model builder service to preload nested blocks and present normalization-friendly fields.
- `create`/`update` should use the service instead of `save!/update!`, and render errors from the service response when validations/DDL/reload fail.
- Ensure `attribute_type` helper still resolves via runtime constants; may need to call runtime after service-triggered reload to avoid stale schema.

## Runtime Accessors (replace model helpers)
- Deepwiki cautions: `runtime_constant` only returns a shell; `runtime_class` evaluates blocks for the model + associations but can become stale if `reload_all!` was not called. Controllers should use a service-driven accessor that ensures the runtime is fresh.
- Plan: replace `Darwin::Model#runtime_constant`/`#runtime_class` usage in controllers with a dedicated runtime accessor service under `app/services/darwin` that can (a) ensure a recent reload or call `Runtime.reload_all!` if required, (b) return the fully-evaluated class, and (c) avoid hidden DDL.
- Records controller currently depends on `runtime_class` for CRUD and nested attributes; update to call the accessor service instead, so stale schema/associations are avoided after the callbacks are removed.

## Proposed Service Surface (Servus, under `app/services/darwin/**`)
- Model building (DDL + runtime reload):
  - `darwin/model_builder/create/service.rb`: build `Darwin::Model` + nested blocks, enforce validations/normalization, call `SchemaManager.sync!`, then `Runtime.reload_all!(current_model:, builder: true)`. Return the saved model; surface validation/DDL errors via `failure`.
  - `darwin/model_builder/update/service.rb`: same flow for updates, reusing the same DDL + reload path.
  - `darwin/model_builder/destroy/service.rb`: destroy model, call `SchemaManager.drop!`, then `Runtime.reload_all!(builder: true)`.
  - `darwin/model_builder/build/service.rb`: convenience to build/find a model for forms (`new`/`edit`).
- Runtime accessor (no DDL):
  - `darwin/runtime_accessor/service.rb`: given model name/record, ensure a recent reload (optional cache TTL?), then return fully evaluated runtime class; never performs DDL; can call `Runtime.reload_all!(builder: false)` if cache is stale.
  - Used by controllers (`RecordsController`, `ModelsController#attribute_type`, etc.) instead of direct `runtime_class` calls.
- Shared support helpers:
  - Persist/normalize blocks: reuse `Darwin::Block` callbacks for now; if we bypass AR callbacks, replicate `assemble_args` + `normalize_association_args` + validation logic in support classes.
  - Block ordering: shared helper to sort blocks via `Runtime.block_priority` before interpreter calls if a service needs targeted reloads.
- Error strategy: services return `failure` with schema/DDL/runtime reload errors so controllers can render forms with messages instead of raising.

## Validation UI + fernandes/ui Select (12 Dec 2025)
- The fernandes `ui/select` component renders `role=\"option\"` items without `data-ui--select-target=\"item\"` or `data-value`; `block_form_controller` now treats any option with `data-allowed-types` as an item and falls back to the lowercased text as the value.
- Validation items now receive explicit `data-value`, `data-allowed-types`, and `data-ui--select-target=\"item\"` to let `showValidationOptions` filter by column type and update the hidden input.
- When an attribute is chosen, `populateValidationTypes` hits the attribute_type endpoint and disables irrelevant validations (`data-disabled`/`aria-disabled` + `hidden`), then keeps the hidden input in sync and toggles the matching validation field.
- Manual walk (localhost:3000/blogPost/edit): Add Validates → pick `Dob` → validation list filters; choosing `Uniqueness` updates the hidden input, reveals the uniqueness switch, and Save persists `validates dob`.
- System spec `spec/system/validations_spec.rb` stays `skip` because headless Selenium cannot bind a port in this harness; run locally with a real browser to exercise the flow.

## Open Questions
- Where should service boundaries live (Servus namespace?) for create/update/delete flows that currently rely on callbacks.
- How to expose builder vs runtime reload choice in the form builder/UI without allowing accidental DDL in production paths.
- Whether V2 interpreter should own schema sync calls or remain DSL-only with services handling DDL upfront.
