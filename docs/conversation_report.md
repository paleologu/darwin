# Conversation & Exploration Report

## Context & Goal
- Task: analyze `docs/builder_planning.md` suggestions against the actual codebase, assess feasibility and opportunity costs, and outline a safe form-builder refactor path.
- Later request: produce a detailed report of findings/explorations (this file).
- Tools: rails-mcp (project info, file reads) per AGENTS.md guidance; no runtime code edits beyond this doc.

## Exploration Log (what was read)
- Project info tree via rails-mcp.
- Key files:  
  - Runtime/Interpreter/Schema: `lib/darwin/runtime.rb`, `lib/darwin/interpreter.rb`, `lib/darwin/v2/interpreter.rb`, `lib/darwin/schema_manager.rb`  
  - Models: `app/models/darwin/block.rb`, `app/models/darwin/model.rb`, `app/models/darwin/column.rb`  
  - Services: `app/services/darwin/model_builder/{build,create,update,destroy}/service.rb`, `app/services/darwin/block_builder/{create,destroy}/service.rb`, `app/services/darwin/runtime_accessor/service.rb`  
  - Controllers: `app/controllers/darwin/models_controller.rb`, `app/controllers/darwin/blocks_controller.rb`  
  - Views/Helpers: `app/views/darwin/models/edit.html.erb`, `app/views/darwin/blocks/_block.html.erb`, `app/helpers/darwin/models_helper.rb`  
  - Docs: `docs/builder_planning.md`, `docs/runtime_architecture.md`

## Architecture Findings
- Runtime: multi-pass loader with priority map (`block_priority`) and builder flag. Pass 1 defines class shells; Pass 2 evaluates blocks (sorted) via interpreter. SchemaManager handles DDL, including inverse association handling in builder flows.
- Interpreter: builder mode ensures columns/foreign keys; adds inverses; guards for malformed blocks. V2 interpreter exists but omits builder logic.
- SchemaManager: `sync!` derives expected columns from attribute + belongs_to blocks, deletes extras; `ensure_column!`/`ensure_table!` helpers used by builder flows.
- Models: `Darwin::Block` normalizes association args before save (don’t re-normalize later). Uniform block storage (`method_name`, `args`, `options`, `body`, `position`). `Darwin::Model` accepts nested blocks. `Darwin::Column` validates `type` (bug: migration uses `column_type`).
- Services: Model/Block builders sync schema and reload runtime (`builder: true`). RuntimeAccessor reloads if needed.
- Views: Edit page uses multiple forms; blocks partial is display + delete only; available_method_names forces runtime reloads per request.

## Assessment of Suggestion in `docs/builder_planning.md`
- Strategy/handlers split for Block model: Feasible but high churn; current model ~120 lines and only a handful of block types. Benefit comes only when adding many new methods; risk is disturbing pre-save normalization and callbacks used by services/interpreter.
- Runtime loader/factory replacement: Not advisable. Would lose schema sync, inverse association auto-creation, and priority ordering; high opportunity cost for minimal gain.
- Form builder idea: Worth doing incrementally for view cleanliness and per-method field centralization. Must preserve param shapes, Stimulus hooks, Turbo frames, and avoid nested forms. Missing constants and Column/type mismatch must be handled first if used.

## Form Builder Plan (incremental)
- Add `app/form_builders/darwin_form_builder.rb` with block-specific helpers:
  - `block_header(block)` for badge/args.
  - `block_fields(block)` branching on `method_name`, emitting existing params (`args_name`, `args_type`, `validation_type`, `options[...]`, `body` fallback).
  - `block_actions(block, model)` for save + delete (delete in its own small form).
- Refactor `_block.html.erb` to a single `form_with` per block using the builder; keep Turbo frame IDs via `dom_id(block)`; no nested forms.
- Optional: keep column/add-block helpers, but core value is moving block UI logic out of the partial.

## Risks / Open Issues
- Column model bug: validates `type` while migration defines `column_type`; align before exposing column-type options/constants.
- Runtime reload cost from `available_method_names`; consider caching if it becomes a bottleneck.
- Ensure builder-generated fields match `BlocksController#block_params`; exposing more validation options requires updating permitted params.
- Add-column action (existing): adds DB column without persisted metadata; next `SchemaManager.sync!` will drop it. Any UI for adding columns must persist via attribute blocks or stored metadata to survive sync.

## Current State of Work
- No code changes beyond this documentation file. The report captures findings, risks, and recommended incremental builder path.
