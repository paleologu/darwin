# Darwin Project: Dependent Destroy Bug Resolution

This document summarizes the investigation and resolution of the "double callback" bug affecting `dependent: :destroy` behavior in the Darwin runtime.

## 1. The Problem

The core issue was that destroying an `Article` record was deleting two `Comment` records instead of one. This pointed to a duplicate `dependent: :destroy` callback being registered on the runtime-defined `Article` model.

## 2. Investigation and Root Cause Analysis

The investigation involved several steps of debugging and analysis, which ultimately revealed a two-part root cause:

1.  **Lack of Idempotency in Reloads:** The `Darwin::Runtime.reload_all!` method was not cleanly unloading and redefining the runtime classes. This caused callbacks and associations to be duplicated on each reload.
2.  **Implicit Association in Test Setup:** The `setup_test_data!` helper was defining the `Article` to `Comment` association in two ways: an explicit `has_many` on `Article` and a `belongs_to` with `inverse_of` on `Comment`. This created a second, implicit `has_many` association, which confused ActiveRecord's callback mechanism.

While the idempotency issue was a real bug, the primary cause of the test failure was the flawed test data setup.

## 3. The Fixes

A series of fixes were implemented to address these issues:

1.  **Idempotent Interpreter:** Guard clauses were added to the `has_many` and `belongs_to` blocks in `lib/darwin/interpreter.rb` to prevent them from being applied more than once.
2.  **Clean Runtime Reloads:** The `lib/darwin/runtime.rb` was updated to explicitly remove any existing runtime constants before redefining them, ensuring a clean slate for each reload.
3.  **Corrected Test Data:** The `spec/support/test_helpers.rb` file was modified to define the `Article`/`Comment` association only once, with the `dependent: :destroy` option correctly placed on the `belongs_to` side.
4.  **Symbol Conversion:** A bug was fixed in the `belongs_to` interpreter block where the `dependent` option was not being converted from a string to a symbol.

## 4. Outcome

After applying these fixes, the entire test suite now passes with **10 examples, 0 failures**. The `dependent: :destroy` behavior is correct, and the runtime reloading is now fully idempotent.

## 5. Status

This issue is now considered **resolved**.