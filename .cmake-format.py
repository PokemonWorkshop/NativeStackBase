with section("format"):
    # If an argument group contains more than this many sub-groups (parg or kwarg
    # groups) then force it to a vertical layout.
    max_subgroups_hwrap = 2

    # If a positional argument group contains more than this many arguments, then
    # force it to a vertical layout.
    max_pargs_hwrap = 6

    # If a statement is wrapped to more than one line, than dangle the closing
    # parenthesis on its own line.
    dangle_parens = True

    # A list of command names which should always be wrapped
    always_wrap = [
        "target_compile_definitions",
        "target_compile_options",
        "target_link_libraries",
        "target_link_directories",
        "target_include_directories",
        "set_target_properties",
        "add_library",
        "add_executable",
        "ExternalProject_Add",
    ]

with section("markup"):
    # Disable comment formatting
    enable_markup = False

with section("parse"):
    # Keep these in sync with _parse_declare_native_dependency_args() in
    # cmake/helpers/DeclareNativeDependency.cmake: one positional argument (the
    # dependency name), every field one-valued, and OPTIONS variadic.
    _declare_native_dependency_spec = {
        "pargs": 1,
        "kwargs": {
            "MODE": 1,
            "SOURCE_URL": 1,
            "SOURCE_HASH": 1,
            "GIT_URL": 1,
            "GIT_TAG": 1,
            "BIN_URL": 1,
            "BIN_HASH": 1,
            "SCRIPT": 1,
            "OPTIONS": "*",
        },
    }

    additional_commands = {
        "declare_default_native_dependency": _declare_native_dependency_spec,
        "declare_override_native_dependency": _declare_native_dependency_spec,
    }