# JSONAssert

A fluent API for querying and asserting JSON content in Godot Engine tests using the gdUnit4 testing framework.

At the time of writing, the code was tested to work with gdUnit 5.1.0.

## Overview

JSONAssert provides 4 broad categories of operations:

- **Selectors** like `at()` and `with_objects()` navigate and transform the current candidate set by selecting new values
- **Filters** like `containing()` and `matching()` narrow down the candidate set by applying selection criteria without performing assertions (filter method names end with -ing)
- **Assertions** such as `must_*`, `is_*`, and `has_*` methods evaluate candidates against expectations and fail if conditions are not met
- **Finalizers** like `verify()`, `exactly(n)`, `at_most(n)`, and `at_least(n)` execute the evaluation chain and report final results

**Important**: A finalizer method must be called to execute the assertion chain. Use `verify()` for basic validation, or `exactly(n)`, `at_least(n)`, `at_most(n)` for count-based assertions. Without a finalizer, no assertions or queries are performed and a failure is reported.

## Quick Start

You can add this to your test suites:
```gdscript
extends GdUnitTestSuite

func assert_json(json: Variant) -> JSONAssert:
  return JSONAssert.new(json)
```

Alternatively, you can use static helper which does the same:
```gdscript
JSONAssert.assert_json(content)
```

```gdscript
# Basic usage
assert_json('{"name": "Alice", "age": 25}') \
    .must_contain("name", "Alice") \
    .verify()

# Navigation and filtering
assert_json('{"users": [{"role": "admin"}, {"role": "user"}]}') \
    .at("/users") \
    .with_objects() \
    .containing("role", "admin") \
    .exactly(1)

# Type checking
assert_json('{"count": 42}') \
    .at("/count") \
    .is_number() \
    .must_be(42) \
    .verify()

# Conditional assertions and branching: either() - or_else() - end()
assert_json('{"users": [{"name": "Alice", "role": "admin"}, {"name": "Bob", "role": "user"}]}') \
    .at("/users") \
    .with_objects() \
    .either() \
      .containing("role", "admin") \
      .must_contain("name", "Alice") \
    .or_else() \
      # note: branching fully supports multiple chained steps
      .containing("role", "moderator") \
      .must_contain("name", "Charlie") \
    .end() \
    .verify()
```

Check unit tests for more examples.

## Important Notes

- Always call a finalizer (`verify()`, `exactly()`, etc.) to execute assertions
- Paths use forward slashes: `/users/0/name`
- Array indices support negative indexing: `/items/-1` - fetch the last item
- Filter methods (ending with -ing) don't fail, they narrow the candidate set
- Use `either().or_else().end()` for conditional assertions

For more information, see source code and JSONAssert class in Godot help.
