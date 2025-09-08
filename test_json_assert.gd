extends GdUnitTestSuite
## Tests for JSONAssert class.


var fixture := """
{
	"ship_model": "Lucky 7",
	"id": 42,
	"components": ["mining_laser", "shield_mk1", "afterboosters"],
	"crew": [
		{"name": "Dan", "role": "engineer"},
		{"name": "Mona", "role": "gunner"},
		{"name": "Taras", "role": "pilot"}
	],
	"engine": {
		"max_speed": 200000,
		"type": "warp"
	}
}
"""


static func assert_json(json: Variant) -> JSONAssert:
	return JSONAssert.new(json)


func test_basic_navigation() -> void:
	assert_json(fixture).describe("root path should be accessible").at("/").verify()
	assert_json(fixture).describe("empty path should work like root").at("").verify()
	assert_json(fixture).describe("engine object should be found").at("/engine").verify()
	assert_json(fixture).describe("relative path to engine should work").at("engine").verify()

	assert_json(fixture).describe("nested path to engine type should work").at("/engine/type").verify()
	assert_json(fixture).describe("array index path should work").at("/crew/1/name").verify()

	assert_failure(func() -> void:
		assert_json(fixture).describe("non-existent path should fail").at("/not_found").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(fixture).describe("non-existent nested path should fail").at("/engine/not_found").verify()
	).is_failed()


func test_absolute_path_navigation() -> void:
	var test_data := '{"user": {"role": "admin", "profile": {"level": 5}}, "settings": {"theme": "dark"}}'

	assert_json(test_data).describe("absolute paths reset to root context") \
		.at("/user/role") \
		.must_be("admin") \
		.at("/settings/theme") \
		.must_be("dark") \
		.verify()

	# Test absolute path navigation after either/or_else
	assert_json(test_data).describe("absolute path navigation after branching") \
		.at("/user/role") \
		.either().must_be("admin") \
		.or_else().must_be("user") \
		.end() \
		.at("/user/profile/level") \
		.must_be(5) \
		.verify()


func test_array_operations() -> void:
	assert_json(fixture).describe("crew should be array").at("/crew").is_array().verify()
	assert_json(fixture).describe("components should be array").at("/components").is_array().verify()

	assert_failure(func() -> void:
		assert_json(fixture).describe("engine object should fail is_array").at("/engine").is_array().verify()
	).is_failed()

	assert_json(fixture).describe("crew array should contain 3 objects").at("/crew").with_objects().exactly(3)

	assert_failure(func() -> void:
		assert_json(fixture).describe("with_objects on non-array should fail").at("/engine").with_objects().verify()
	).is_failed()


func test_assertions() -> void:
	assert_json(fixture).describe("should contain ship_model key").must_contain("ship_model").verify()
	assert_json(fixture).describe("should contain id key").must_contain("id").verify()

	assert_json(fixture).describe("ship_model should be Lucky 7").must_contain("ship_model", "Lucky 7").verify()
	assert_json(fixture).describe("id should be 42").must_contain("id", 42).verify()

	assert_failure(func() -> void:
		assert_json(fixture).describe("should fail for non-existent key").must_contain("not_found").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(fixture).describe("should fail for wrong ship_model value").must_contain("ship_model", "Firefly").verify()
	).is_failed()

	assert_json(fixture).describe("should not contain non-existent key").must_not_contain("not_found").verify()
	assert_json(fixture).describe("ship_model should not be Firefly").must_not_contain("ship_model", "Firefly").verify()

	assert_failure(func() -> void:
		assert_json(fixture).describe("should fail when key exists").must_not_contain("ship_model").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(fixture).describe("should fail when value matches").must_not_contain("ship_model", "Lucky 7").verify()
	).is_failed()


func test_filtering() -> void:
	assert_json(fixture).describe("should find Dan with engineer role") \
		.at("/crew") \
		.with_objects() \
		.containing("name", "Dan") \
		.must_contain("role", "engineer") \
		.exactly(1)

	assert_json(fixture).describe("should find pilot named Taras") \
		.at("/crew") \
		.with_objects() \
		.containing("role", "pilot") \
		.must_contain("name", "Taras") \
		.exactly(1)

	assert_json(fixture).describe("should find no unknown crew members") \
		.at("/crew") \
		.with_objects() \
		.containing("name", "Unknown") \
		.exactly(0)

	assert_json(fixture).describe("should match Dan by name and role") \
		.at("/crew") \
		.with_objects() \
		.matching({"name": "Dan", "role": "engineer"}) \
		.exactly(1)

	assert_json(fixture).describe("should find gunner named Mona") \
		.at("/crew") \
		.with_objects() \
		.matching({"role": "gunner"}) \
		.must_contain("name", "Mona") \
		.exactly(1)


func test_finalizers() -> void:
	assert_json(fixture).describe("basic verify should pass").verify()

	assert_json(fixture).describe("should have exactly 1 root object").exactly(1)
	assert_json(fixture).describe("should have exactly 3 crew objects").at("/crew").with_objects().exactly(3)

	assert_failure(func() -> void:
		assert_json(fixture).describe("should fail with wrong exact count").at("/crew").with_objects().exactly(2)
	).is_failed()

	assert_json(fixture).describe("should have at least 3 crew objects").at("/crew").with_objects().at_least(3)
	assert_json(fixture).describe("should have at least 1 crew object").at("/crew").with_objects().at_least(1)
	assert_json(fixture).describe("should have at least 0 crew objects").at("/crew").with_objects().at_least(0)

	assert_failure(func() -> void:
		assert_json(fixture).describe("should fail with too high minimum").at("/crew").with_objects().at_least(4)
	).is_failed()

	assert_json(fixture).describe("should have at most 3 crew objects").at("/crew").with_objects().at_most(3)
	assert_json(fixture).describe("should have at most 5 crew objects").at("/crew").with_objects().at_most(5)

	assert_failure(func() -> void:
		assert_json(fixture).describe("should fail with too low maximum").at("/crew").with_objects().at_most(2)
	).is_failed()


func test_failing_to_finalize() -> void:
	assert_failure(func() -> void:
		assert_json(fixture).describe("should fail if not finalized (no branching)").at("/")
	).is_failed()

	assert_failure(func() -> void:
		assert_json(fixture).describe("should fail if not finalized (with branching)") \
			.either().at("/") \
			.or_else().at("/") \
			.end()
	).is_failed()


func test_chaining() -> void:
	assert_json(fixture).describe("complex chain should find pilot Taras") \
		.at("/crew") \
		.is_array() \
		.with_objects() \
		.containing("role", "pilot") \
		.must_contain("name", "Taras") \
		.exactly(1)

	assert_json(fixture).describe("multiple filters should find engineer Dan") \
		.at("/crew") \
		.with_objects() \
		.containing("role", "engineer") \
		.containing("name", "Dan") \
		.exactly(1)

	assert_json(fixture).describe("engine should have expected properties") \
		.at("/engine") \
		.must_contain("type", "warp") \
		.must_contain("max_speed", 200_000) \
		.must_not_contain("fuel_type") \
		.verify()

	assert_json(fixture).describe("must_selected should work in chain") \
		.at("/crew") \
		.must_selected(1) \
		.with_objects() \
		.must_selected(3) \
		.containing("name", "Dan") \
		.must_selected(1) \
		.verify()


func test_json_strings() -> void:
	var json_string := '{"test": "value", "number": 42}'
	assert_json(json_string).describe("JSON string should be parsed correctly") \
		.must_contain("test", "value") \
		.must_contain("number", 42) \
		.verify()

	assert_failure(func() -> void:
		assert_json('invalid json').describe("invalid JSON should fail").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json('{"invalid": json}').describe("malformed JSON should fail").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json('{"missing": "quote}').describe("unterminated string should fail").verify()
	).is_failed()

	assert_json('{"value": null}').describe("JSON with null should work") \
		.must_contain("value", null) \
		.verify()


func test_contain_assertions_with_different_types() -> void:
	var test_data := """
	{
		"string_val": "hello world",
		"int_val": 123,
		"float_val": 3.14,
		"bool_val": true,
		"null_val": null,
		"array_val": [1, 2, 3],
		"object_val": {"nested": "value"}
	}
	"""

	assert_json(test_data).describe("should contain all expected data types") \
		.must_contain("string_val", "hello world") \
		.must_contain("int_val", 123) \
		.must_contain("float_val", 3.14) \
		.must_contain("bool_val", true) \
		.must_contain("null_val", null) \
		.verify()

	assert_json(test_data).describe("nested object should contain expected value") \
		.at("/object_val") \
		.must_contain("nested", "value") \
		.verify()

	assert_json(test_data).describe("should not contain wrong typed values") \
		.must_not_contain("string_val", 56) \
		.must_not_contain("int_val", "123") \
		.must_not_contain("bool_val", "true") \
		.verify()


func test_array_indexing_and_edge_cases() -> void:
	assert_json(fixture).describe("first crew member should be Dan").at("/crew/0") \
		.must_contain("name", "Dan").verify()
	assert_json(fixture).describe("second crew member should be Mona").at("/crew/1") \
		.must_contain("name", "Mona").verify()
	assert_json(fixture).describe("third crew member should be Taras").at("/crew/2") \
		.must_contain("name", "Taras").verify()

	assert_json(fixture).describe("last crew member should be Taras").at("/crew/-1") \
		.must_contain("name", "Taras").verify()
	assert_json(fixture).describe("second to last should be Mona").at("/crew/-2") \
		.must_contain("name", "Mona").verify()
	assert_json(fixture).describe("third to last should be Dan").at("/crew/-3") \
		.must_contain("name", "Dan").verify()

	assert_json(fixture).describe("should contain engine object with numbers") \
		.at("/") \
		.must_contain("engine", 	{
			"max_speed": 200000,
			"type": "warp"
		}).verify()

	assert_failure(func() -> void:
		assert_json(fixture).describe("out of bounds index should fail").at("/crew/3").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(fixture).describe("negative out of bounds should fail").at("/crew/-4").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(fixture).describe("invalid index should fail").at("/crew/invalid").verify()
	).is_failed()


func test_path_resolution_edge_cases() -> void:
	assert_json(fixture).describe("relative path should work").at("crew/0/name").verify()
	assert_json(fixture).describe("path with trailing slash should work").at("/crew/0/name/").verify()
	assert_json(fixture).describe("path with extra slashes should work").at("//crew//0//name//").verify()

	var mixed := [
		"string", 42, true, null,
		{"type": "object", "value": 1}
	]

	assert_json(mixed).describe("should access first array element").at("/0").verify()
	assert_json(mixed).describe("should access nested object property").at("/4/type").verify()
	assert_json(mixed).describe("should find one object with type property").with_objects().containing("type", "object").exactly(1)

	var nested := {"levels": [[1, 2], [3, 4]]}
	assert_json(nested).describe("should access deeply nested array element").at("/levels/1/0").verify()


func test_null_vs_not_found() -> void:
	var test_data := {
		"existing_null": null,
		"nested": {
			"null_value": null,
			"string_value": "world"
		}
	}

	assert_json(test_data).describe("should find and assert on existing null") \
		.must_contain("existing_null", null) \
		.at("/existing_null") \
		.verify()

	assert_json(test_data).describe("should access nested null value").at("/nested/null_value").verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("non-existent key should fail").must_contain("non_existent").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("non-existent path should fail").at("/non_existent").verify()
	).is_failed()

	assert_json(test_data).describe("must_not_contain should work with null comparisons") \
		.must_not_contain("existing_null", "not_null") \
		.must_not_contain("non_existent", null) \
		.verify()


func test_error_conditions() -> void:
	# TODO: Should at() handle multiple candidates?
	assert_failure(func() -> void:
		assert_json(fixture).describe("at() with multiple candidates should fail") \
			.at("/crew") \
			.with_objects() \
			.at("/name") \
			.verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(fixture).describe("array indexing on object should fail").at("/engine/0").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(fixture).describe("deep non-existent path should fail").at("/engine/turbo/boost/level").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(fixture).describe("assertion on empty candidates should fail") \
			.at("/crew") \
			.with_objects() \
			.containing("name", "nonexistent") \
			.must_contain("field") \
			.verify()
	).is_failed()


func test_mixed_arrays() -> void:
	var mixed := ["string", 42, 3.14, true, false, null, {"valid": true}]

	assert_json(mixed).describe("should access string element").at("/0").verify()
	assert_json(mixed).describe("should access number element").at("/1").verify()
	assert_json(mixed).describe("should access nested object property").at("/6/valid").verify()

	assert_json(mixed).describe("should filter to one object").with_objects().exactly(1)
	assert_json(mixed).describe("should find object with valid=true").with_objects().containing("valid", true).exactly(1)


func test_empty_values() -> void:
	var test_data := {
		"empty_string": "",
		"empty_array": [],
		"empty_object": {},
		"zero": 0,
		"false_val": false
	}

	assert_json(test_data).describe("should handle empty and falsy values") \
		.must_contain("empty_string", "") \
		.must_contain("zero", 0) \
		.must_contain("false_val", false) \
		.verify()

	assert_json(test_data).describe("empty array should be valid array").at("/empty_array").is_array().verify()
	assert_json(test_data).describe("empty array should have no objects").at("/empty_array").with_objects().exactly(0)


func test_either_or_else_basic() -> void:
	var test_data := '{"type": "user", "role": "moderator"}'

	assert_json(test_data).describe("two-branch either/or_else should pass on first branch") \
		.at("/type") \
		.either().must_be("user") \
		.or_else().must_be("admin") \
		.end() \
		.verify()

	assert_json(test_data).describe("two-branch either/or_else should pass on second branch") \
		.at("/type") \
		.either().must_be("admin") \
		.or_else().must_be("user") \
		.end() \
		.verify()

	assert_json(test_data).describe("multiple branches should pass on third option") \
		.at("/role") \
		.either().must_be("admin") \
		.or_else().must_be("user") \
		.or_else().must_be("moderator") \
		.end() \
		.verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("all branches should fail when none match") \
			.at("/type") \
			.either().must_be("admin") \
			.or_else().must_be("guest") \
			.end() \
			.verify()
	).is_failed()


func test_either_or_else_with_filtering() -> void:
	var test_data := {
		"users": [
			{"name": "Alice", "role": "admin", "active": true},
			{"name": "Bob", "role": "user", "active": false},
			{"name": "Charlie", "role": "moderator", "active": true}
		]
	}

	assert_json(test_data).describe("either/or_else should work with object filtering") \
		.at("/users") \
		.with_objects() \
		.either() \
			.containing("role", "admin") \
		.or_else() \
			.containing("role", "moderator") \
		.end() \
		.exactly(2)

	assert_json(test_data).describe("should combine candidates from multiple passing branches") \
		.at("/users") \
		.with_objects() \
		.containing("active", true) \
		.either() \
			.containing("role", "admin") \
		.or_else() \
			.containing("role", "moderator") \
		.end() \
		.exactly(2)


func test_either_or_else_chaining() -> void:
	var test_data := '{"user": {"role": "admin", "level": 5}}'

	assert_json(test_data).describe("method chaining should continue after either/or_else/end") \
		.at("/user/role") \
		.either().must_be("admin") \
		.or_else().must_be("user") \
		.end() \
		.at("/user/level") \
		.must_be(5) \
		.verify()

	assert_json(test_data).describe("should handle mixed assertion types in branches") \
		.at("/user/level") \
		.either() \
			.is_string() \
		.or_else() \
			.is_number() \
			.must_be(5) \
		.end() \
		.verify()


func test_either_or_else_errors() -> void:
	var test_data := '{"test": "value"}'

	assert_failure(func() -> void:
		assert_json(test_data).describe("or_else without either should fail") \
			.at("/test") \
			.or_else().must_be("other") \
			.end() \
			.verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("end without either should fail") \
			.at("/test") \
			.end() \
			.verify()
	).is_failed()


func test_must_begin_with() -> void:
	var test_data := '{"url": "https://api.example.com", "empty": "", "name": "John Doe"}'

	assert_json(test_data).describe("string should begin with expected prefix") \
		.at("/url") \
		.must_begin_with("https://") \
		.verify()

	assert_json(test_data).describe("empty string should begin with empty prefix") \
		.at("/empty") \
		.must_begin_with("") \
		.verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("wrong prefix should fail") \
			.at("/name") \
			.must_begin_with("Jane") \
			.verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("non-string should fail type check") \
			.at("/") \
			.must_begin_with("test") \
			.verify()
	).is_failed()


func test_must_end_with() -> void:
	var test_data := '{"file": "config.json", "empty": "", "path": "/api/v1"}'

	assert_json(test_data).describe("string should end with expected suffix") \
		.at("/file") \
		.must_end_with(".json") \
		.verify()

	assert_json(test_data).describe("empty string should end with empty suffix") \
		.at("/empty") \
		.must_end_with("") \
		.verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("wrong suffix should fail") \
			.at("/path") \
			.must_end_with("/v2") \
			.verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("non-string should fail type check") \
			.at("/") \
			.must_end_with("test") \
			.verify()
	).is_failed()


func test_must_begin_with_and_must_end_with_chaining() -> void:
	var test_data := '{"url": "https://example.com/api/v1"}'

	assert_json(test_data).describe("URL should start and end with expected patterns") \
		.at("/url") \
		.must_begin_with("https://") \
		.must_end_with("/v1") \
		.verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("chain should fail on wrong suffix") \
			.at("/url") \
			.must_begin_with("https://") \
			.must_end_with("/v2") \
			.verify()
	).is_failed()


func test_type_checking_methods() -> void:
	var test_data := """
	{
		"null_val": null,
		"bool_val": true,
		"int_val": 42,
		"float_val": 3.14,
		"string_val": "hello",
		"array_val": [1, 2, 3],
		"object_val": {"key": "value"}
	}
	"""

	assert_json(test_data).describe("null value should be null type").at("/null_val").is_null().verify()
	assert_json(test_data).describe("boolean value should be bool type").at("/bool_val").is_bool().verify()
	assert_json(test_data).describe("integer should be number type").at("/int_val").is_number().verify()
	assert_json(test_data).describe("float should be number type").at("/float_val").is_number().verify()
	assert_json(test_data).describe("string should be string type").at("/string_val").is_string().verify()
	assert_json(test_data).describe("array should be array type").at("/array_val").is_array().verify()
	assert_json(test_data).describe("object should be object type").at("/object_val").is_object().verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("string should fail null type check").at("/string_val").is_null().verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("int should fail bool type check").at("/int_val").is_bool().verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("bool should fail string type check").at("/bool_val").is_string().verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("object should fail array type check").at("/object_val").is_array().verify()
	).is_failed()


func test_is_one_of_types() -> void:
	var test_data := '{"mixed": [null, true, 42, "text", [], {}]}'

	assert_json(test_data).describe("null should match null or string types").at("/mixed/0").is_one_of_types([JSONAssert.Type.NULL, JSONAssert.Type.STRING]).verify()
	assert_json(test_data).describe("bool should match bool or number types").at("/mixed/1").is_one_of_types([JSONAssert.Type.BOOL, JSONAssert.Type.NUMBER]).verify()
	assert_json(test_data).describe("number should match number or string types").at("/mixed/2").is_one_of_types([JSONAssert.Type.NUMBER, JSONAssert.Type.STRING]).verify()
	assert_json(test_data).describe("string should match string or array types").at("/mixed/3").is_one_of_types([JSONAssert.Type.STRING, JSONAssert.Type.ARRAY]).verify()

	assert_json(test_data).describe("array should match multiple type options").at("/mixed/4").is_one_of_types([
		JSONAssert.Type.ARRAY,
		JSONAssert.Type.OBJECT,
		JSONAssert.Type.STRING
	]).verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("null should fail bool or number types").at("/mixed/0").is_one_of_types([JSONAssert.Type.BOOL, JSONAssert.Type.NUMBER]).verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("string should fail number or array types").at("/mixed/3").is_one_of_types([JSONAssert.Type.NUMBER, JSONAssert.Type.ARRAY]).verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("empty candidate set should fail type check") \
			.at("/mixed") \
			.with_objects() \
			.containing("nonexistent", "value") \
			.is_one_of_types([JSONAssert.Type.OBJECT]) \
			.verify()
	).is_failed()


func test_is_empty_and_is_not_empty() -> void:
	var test_data := """
	{
		"empty_string": "",
		"empty_array": [],
		"empty_object": {},
		"non_empty_string": "hello",
		"non_empty_array": [1, 2, 3],
		"non_empty_object": {"key": "value"},
		"number": 42
	}
	"""

	assert_json(test_data).describe("empty string should be empty").at("/empty_string").is_empty().verify()
	assert_json(test_data).describe("empty array should be empty").at("/empty_array").is_empty().verify()
	assert_json(test_data).describe("empty object should be empty").at("/empty_object").is_empty().verify()

	assert_json(test_data).describe("non-empty string should not be empty").at("/non_empty_string").is_not_empty().verify()
	assert_json(test_data).describe("non-empty array should not be empty").at("/non_empty_array").is_not_empty().verify()
	assert_json(test_data).describe("non-empty object should not be empty").at("/non_empty_object").is_not_empty().verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("non-empty string should fail is_empty").at("/non_empty_string").is_empty().verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("non-empty array should fail is_empty").at("/non_empty_array").is_empty().verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("empty string should fail is_not_empty").at("/empty_string").is_not_empty().verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("empty array should fail is_not_empty").at("/empty_array").is_not_empty().verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("number should fail is_empty type check").at("/number").is_empty().verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("number should fail is_not_empty type check").at("/number").is_not_empty().verify()
	).is_failed()


func test_has_size() -> void:
	var test_data := """
	{
		"string_5": "hello",
		"array_3": [1, 2, 3],
		"object_2": {"a": 1, "b": 2},
		"empty_array": [],
		"empty_string": "",
		"number": 42
	}
	"""

	assert_json(test_data).describe("string should have size 5").at("/string_5").has_size(5).verify()
	assert_json(test_data).describe("array should have size 3").at("/array_3").has_size(3).verify()
	assert_json(test_data).describe("object should have size 2").at("/object_2").has_size(2).verify()
	assert_json(test_data).describe("empty array should have size 0").at("/empty_array").has_size(0).verify()
	assert_json(test_data).describe("empty string should have size 0").at("/empty_string").has_size(0).verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("string should fail incorrect size").at("/string_5").has_size(4).verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("array should fail incorrect size").at("/array_3").has_size(2).verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("number should fail has_size type check").at("/number").has_size(1).verify()
	).is_failed()


func test_has_element() -> void:
	var test_data := """
	{
		"array_nums": [1, 2, 3, "hello"],
		"array_mixed": [null, true, {"key": "value"}],
		"string_text": "hello world",
		"empty_array": [],
		"number": 42
	}
	"""

	assert_json(test_data).describe("array should contain number 2").at("/array_nums").has_element(2).verify()
	assert_json(test_data).describe("array should contain string hello").at("/array_nums").has_element("hello").verify()
	assert_json(test_data).describe("array should contain null").at("/array_mixed").has_element(null).verify()
	assert_json(test_data).describe("array should contain boolean true").at("/array_mixed").has_element(true).verify()

	assert_json(test_data).describe("string should contain hello").at("/string_text").has_element("hello").verify()
	assert_json(test_data).describe("string should contain world").at("/string_text").has_element("world").verify()
	assert_json(test_data).describe("string should contain space").at("/string_text").has_element(" ").verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("array should fail to find element 5").at("/array_nums").has_element(5).verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("string should fail to find goodbye").at("/string_text").has_element("goodbye").verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("empty array should fail to find element").at("/empty_array").has_element(1).verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("number should fail has_element type check").at("/number").has_element(42).verify()
	).is_failed()


func test_must_satisfy() -> void:
	var test_data := '{"num": 42, "text": "hello"}'

	assert_json(test_data).describe("number should satisfy > 0").at("/num").must_satisfy("is positive", func(x): return x > 0).verify()
	assert_json(test_data).describe("string should satisfy length > 3").at("/text").must_satisfy("length > 3", func(s): return len(s) > 3).verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("number should fail < 0 predicate").at("/num").must_satisfy("is negative", func(x): return x < 0).verify()
	).is_failed()


func test_must_match_regex() -> void:
	var test_data := """
	{
		"email": "user@example.com",
		"phone": "123-456-7890",
		"uuid": "550e8400-e29b-41d4-a716-446655440000",
		"invalid_email": "not-an-email",
		"number": 42
	}
	"""

	var email_regex := RegEx.new()
	email_regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")

	var phone_regex := RegEx.new()
	phone_regex.compile("^\\d{3}-\\d{3}-\\d{4}$")

	var uuid_regex := RegEx.new()
	uuid_regex.compile("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")

	assert_json(test_data).describe("email should match email regex").at("/email").must_match_regex(email_regex).verify()
	assert_json(test_data).describe("phone should match phone regex").at("/phone").must_match_regex(phone_regex).verify()
	assert_json(test_data).describe("UUID should match UUID regex").at("/uuid").must_match_regex(uuid_regex).verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("invalid email should fail email regex").at("/invalid_email").must_match_regex(email_regex).verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("email should fail phone regex").at("/email").must_match_regex(phone_regex).verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("number should fail regex type check").at("/number").must_match_regex(email_regex).verify()
	).is_failed()

	var invalid_regex := RegEx.new()
	invalid_regex.compile("[invalid")  # Missing closing bracket

	assert_failure(func() -> void:
		assert_json(test_data).describe("invalid regex should fail").at("/email").must_match_regex(invalid_regex).verify()
	).is_failed()


func test_must_selected() -> void:
	var test_data := """
	{
		"users": [
			{"name": "Alice", "active": true},
			{"name": "Bob", "active": false},
			{"name": "Charlie", "active": true}
		]
	}
	"""

	assert_json(test_data).describe("root should have 1 candidate").must_selected(1).verify()

	assert_json(test_data).describe("users array should have 1 candidate") \
		.at("/users") \
		.must_selected(1) \
		.with_objects() \
		.must_selected(3) \
		.verify()

	assert_json(test_data).describe("filtered users should have 2 candidates") \
		.at("/users") \
		.with_objects() \
		.containing("active", true) \
		.must_selected(2) \
		.verify()

	assert_failure(func() -> void:
		assert_json(test_data).describe("wrong count should fail") \
			.at("/users") \
			.with_objects() \
			.must_selected(2) \
			.verify()
	).is_failed()

	assert_failure(func() -> void:
		assert_json(test_data).describe("empty set should fail must_selected(1)") \
			.at("/users") \
			.with_objects() \
			.containing("active", "unknown") \
			.must_selected(1) \
			.verify()
	).is_failed()
