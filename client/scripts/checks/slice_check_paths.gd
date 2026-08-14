class_name SliceCheckPaths
extends RefCounted

## Keeps automated and human-review save roots inside the ignored workspace.
## Production saves continue to use SliceSaveCatalog.DEFAULT_ROOT_DIR.

const RUNTIME_INTAKE_DIR := "tools/runtime-intake"
const CHECK_RUNS_DIR := "check-runs"
const REVIEW_WORLDS_DIR := "review-worlds"


static func repository_root() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


static func check_run(topic: String, unique: bool = true) -> String:
	var path := repository_root().path_join(RUNTIME_INTAKE_DIR).path_join(
		CHECK_RUNS_DIR
	).path_join(topic)
	if unique:
		path += "-%d" % Time.get_ticks_usec()
	return path


static func review_worlds(name: String = "current") -> String:
	return repository_root().path_join(RUNTIME_INTAKE_DIR).path_join(
		REVIEW_WORLDS_DIR
	).path_join(name)
