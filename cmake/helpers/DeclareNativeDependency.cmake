include(FetchContent)

# ##############################################################################
# Public API
# ##############################################################################

# declare_default_native_dependency()
#
# Declare a default version to use for a given native dependency. Supports four modes
#   "sysroot"           - Use the system/toolchain-installed version of the dependency through find_package.
#   "source_url"/"git"  - Fetch the source code using FetchContent
#   "bin_url"           - Download and extract the compiled dependency from a url containing a CMake config file
#   "cmake_adapter"     - Call a custom CMake script to expose targets to CMake
#
# It will set internal ENV variables to track the declared default native dependency. If another
# call to declare_default_native_dependency is made for the same NAME, it will check for conflicts.
#
# If the duplicate declaration conflicts with the previous one, an error will be raised.
#
# Usage:
# declare_default_native_dependency(
#   <name>
#   MODE git
#   GIT_URL <git_url>
#   GIT_TAG <git_tag>
#   [OPTIONS
#     <key>=<value>
#     <key>=<value>
#   ]
# )
# declare_default_native_dependency(
#   <name>
#   MODE source_url
#   SOURCE_URL <source_url>
#   SOURCE_HASH <source_hash>
#   [OPTIONS
#     <key>=<value>
#     <key>=<value>
#   ]
# )
# declare_default_native_dependency(
#   <name>
#   MODE bin_url
#   BIN_URL <bin_url>
#   BIN_HASH <bin_url_hash>
# )
# declare_default_native_dependency(
#   <name>
#   MODE sysroot
# )
# declare_default_native_dependency(
#   <name>
#   MODE cmake_adapter
#   SCRIPT <full_path_to_script>
# )
#
# Named parameters:
#   MODE                - Type of source, supports "sysroot", "source_url", "git", "bin_url", "cmake_adapter". Defines what
#                         other parameters are required.
#
#   MODE "git" parameters:
#   GIT_URL             - The url of the git repo to fetch the source from. It must supports FetchContent.
#   GIT_TAG             - The git tag/branch/commit to checkout.
#   OPTIONS             - Optional. Build options for the dependency, given as a list of KEY=VALUE. If the
#                         value is a list, it should be quoted as "FOO=a;b".
#
#   MODE "source_url" parameters:
#   SOURCE_URL          - The url of tar/zip archive containing the source code.
#   SOURCE_HASH         - The hash for verification (e.g., "MD5=...").
#   OPTIONS             - Optional. Build options for the dependency, given as a list of KEY=VALUE. If the
#                         value is a list, it should be quoted as "FOO=a;b".
#
#   MODE "bin_url" parameters:
#   BIN_URL         - The URL of the bin_url to download. It must contains a subdirectory named "cmake"
#                          containing a valid CMake config file for find_package
#   BIN_HASH        - The hash for verification (e.g., "MD5=...").
#
#   MODE "cmake_adapter" parameters:
#   SCRIPT              - The full path (not relative) to the adapter script to call
#
# The user can override the default native dependency by calling declare_override_native_dependency, it
# must be done before the default declaration it intends to override. An override replaces the whole
# configuration, OPTIONS included.
#
function(declare_default_native_dependency dep_name)
  _parse_declare_native_dependency_args(declare_default_native_dependency)

  # Conflict check against a previous declaration
  message(CHECK_START "Checking ${dep_name} for previous default declaration")
  set(_prefix "_ND_${dep_name}")
  if(DEFINED ENV{${_prefix}_MODE})
    set(_conflicts "")
    foreach(_key IN LISTS _one_value)
      if(_key STREQUAL "NAME")
        continue()
      endif()
      if(NOT "$ENV{${_prefix}_${_key}}" STREQUAL "${ARG_${_key}}")
        string(
          APPEND
          _conflicts
          "\n  ${_key}: '$ENV{${_prefix}_${_key}}' (previous) vs '${ARG_${_key}}' (current)"
        )
      endif()
    endforeach()

    _nd_diff_options(${_prefix} _option_conflicts)
    string(APPEND _conflicts "${_option_conflicts}")

    if(_conflicts)
      message(CHECK_FAIL "uncompatible previous declaration")
      message(
        FATAL_ERROR
          "Conflicting declarations for native dependency '${dep_name}':${_conflicts}"
      )
    endif()

    message(CHECK_PASS "found compatible declaration - skipping redeclaration")
  elseif(NOT DEFINED ENV{_ND_OVERRIDE_${dep_name}_MODE})
    # First declaration - declare the ENV values
    message(CHECK_PASS "found none")
    foreach(_key IN LISTS _one_value)
      if(NOT _key STREQUAL "NAME")
        set(ENV{${_prefix}_${_key}} "${ARG_${_key}}")
      endif()
    endforeach()
    _nd_store_options(${_prefix})

    # Then actually fetch/find the dependency
    if(ARG_MODE STREQUAL "sysroot")
      _declare_nd_sysroot(${dep_name})
    elseif(ARG_MODE STREQUAL "source_url")
      _declare_nd_source_url(${dep_name} ${ARG_SOURCE_URL} ${ARG_SOURCE_HASH})
    elseif(ARG_MODE STREQUAL "git")
      _declare_nd_git(${dep_name} ${ARG_GIT_URL} ${ARG_GIT_TAG})
    elseif(ARG_MODE STREQUAL "bin_url")
      _declare_nd_bin_url(${dep_name} ${ARG_BIN_URL} ${ARG_BIN_HASH})
    elseif(ARG_MODE STREQUAL "cmake_adapter")
      _declare_nd_adapter(${dep_name} ${ARG_SCRIPT})
    else()
      message(
        FATAL_ERROR
          "declare_default_native_dependency(${dep_name}): invalid MODE '${ARG_MODE}' "
          "(expected sysroot, source_url, git, bin_url or cmake_adapter)"
      )
    endif()
  else()
    message(
      STATUS "Found override declaration for ${dep_name} - skipping default"
    )
  endif()
endfunction()

function(declare_override_native_dependency dep_name)
  _parse_declare_native_dependency_args(declare_override_native_dependency)

  # An override only has an effect if it is declared before the default it
  # overrides: once the default has been processed the dependency is already
  # fetched, and this call would silently do nothing. _ND_<dep>_MODE is recorded
  # by declare_default_native_dependency() only when it actually processed the
  # dependency, so its presence means exactly "too late".
  if(DEFINED ENV{_ND_${dep_name}_MODE})
    message(
      FATAL_ERROR
        "declare_override_native_dependency(${dep_name}): too late, '${dep_name}' "
        "has already been declared and fetched by "
        "declare_default_native_dependency() in MODE "
        "'$ENV{_ND_${dep_name}_MODE}'. Declare the override before the default, "
        "that is above the include() that declares it."
    )
  endif()

  # Conflict check against a previous declaration
  message(CHECK_START "Checking ${dep_name} for previous override declaration")
  set(_prefix "_ND_OVERRIDE_${dep_name}")
  if(DEFINED ENV{${_prefix}_MODE})
    set(_conflicts "")
    foreach(_key IN LISTS _one_value)
      if(_key STREQUAL "NAME")
        continue()
      endif()
      if(NOT "$ENV{${_prefix}_${_key}}" STREQUAL "${ARG_${_key}}")
        string(
          APPEND
          _conflicts
          "\n  ${_key}: '$ENV{${_prefix}_${_key}}' (previous) vs '${ARG_${_key}}' (current)"
        )
      endif()
    endforeach()

    _nd_diff_options(${_prefix} _option_conflicts)
    string(APPEND _conflicts "${_option_conflicts}")

    if(_conflicts)
      message(CHECK_FAIL "uncompatible previous declaration")
      message(
        FATAL_ERROR
          "Conflicting declarations for native dependency '${dep_name}':${_conflicts}"
      )
    endif()

    message(CHECK_PASS "found compatible declaration - skipping redeclaration")
    return()
  else()
    # First declaration - declare the ENV values
    message(CHECK_PASS "found none")
    foreach(_key IN LISTS _one_value)
      if(NOT _key STREQUAL "NAME")
        set(ENV{${_prefix}_${_key}} "${ARG_${_key}}")
      endif()
    endforeach()
    _nd_store_options(${_prefix})
  endif()

  # Then actually calls the underlying logic
  if(ARG_MODE STREQUAL "sysroot")
    _declare_nd_sysroot(${dep_name})
  elseif(ARG_MODE STREQUAL "source_url")
    _declare_nd_source_url(${dep_name} ${ARG_SOURCE_URL} ${ARG_SOURCE_HASH})
  elseif(ARG_MODE STREQUAL "git")
    _declare_nd_git(${dep_name} ${ARG_GIT_URL} ${ARG_GIT_TAG})
  elseif(ARG_MODE STREQUAL "bin_url")
    _declare_nd_bin_url(${dep_name} ${ARG_BIN_URL} ${ARG_BIN_HASH})
  elseif(ARG_MODE STREQUAL "cmake_adapter")
    _declare_nd_adapter(${dep_name} ${ARG_SCRIPT})
  else()
    message(
      FATAL_ERROR
        "declare_override_native_dependency(${dep_name}): invalid MODE '${ARG_MODE}' "
        "(expected sysroot, source_url, git, bin_url or cmake_adapter)"
    )
  endif()

endfunction()

# nd_get_dependency_mode()
#
# Report, in <out_var>, the mode a native dependency is actually provided with.
#
# This helper should mostly be used by CMake adapters looking to understand how a specific
# dependency is actually provided. (ex: SFML and its shenanigans).
#
# If you use it in any other case, think twice, you might be relying on internal details you should not depend on.
#
# Usage:
# nd_get_dependency_mode(<name> <out_var>)
#
# e.g.
#   nd_get_dependency_mode(foo _foo_mode)
#   if(_foo_mode STREQUAL "sysroot")
#     # the dependency comes installed, with whatever its config package defines
#   endif()
#
function(nd_get_dependency_mode dep_name out_var)
  if(NOT ARGC EQUAL 2)
    message(
      FATAL_ERROR
        "nd_get_dependency_mode: expected exactly <name> and <out_var>, got ${ARGC} arguments"
    )
  endif()

  if(DEFINED ENV{_ND_OVERRIDE_${dep_name}_MODE})
    set(${out_var}
        "$ENV{_ND_OVERRIDE_${dep_name}_MODE}"
        PARENT_SCOPE
    )
  elseif(DEFINED ENV{_ND_${dep_name}_MODE})
    set(${out_var}
        "$ENV{_ND_${dep_name}_MODE}"
        PARENT_SCOPE
    )
  else()
    set(${out_var}
        "NOTFOUND"
        PARENT_SCOPE
    )
  endif()
endfunction()

# ##############################################################################
# Internal functions
# ##############################################################################

# Find a library on the sysroot / system
function(_declare_nd_sysroot dep_name)
  find_package(${dep_name} REQUIRED GLOBAL)
endfunction()

# Download the source code of a library from a bin_url
function(_declare_nd_source_url dep_name url hash)
  _nd_apply_options(${dep_name})
  FetchContent_Declare(
    ${dep_name}
    URL ${url}
    URL_HASH ${hash}
    OVERRIDE_FIND_PACKAGE
  )
  FetchContent_MakeAvailable(${dep_name})
endfunction()

# Download the source code of a library from a git repository
function(_declare_nd_git dep_name url tag)
  _nd_apply_options(${dep_name})
  FetchContent_Declare(
    ${dep_name}
    GIT_REPOSITORY ${url}
    GIT_TAG ${tag}
    OVERRIDE_FIND_PACKAGE
    # TODO: enable GIT_SHALLOW for branches / tags by adding a specific flag
  )
  FetchContent_MakeAvailable(${dep_name})
endfunction()

# Download the compiled code of a library from a bin_url
function(_declare_nd_bin_url dep_name url hash)
  # Download the tar ball, checks its hash and extract it
  FetchContent_Declare(
    ${dep_name}_bin
    URL ${url}
    URL_HASH ${hash}
  )
  FetchContent_MakeAvailable(${dep_name}_bin)
  # FetchContent reports its directories under the lowercased name, whatever
  # case the dependency was declared with.
  string(TOLOWER "${dep_name}" _lc_dep_name)
  FetchContent_GetProperties(${_lc_dep_name}_bin)

  # try find_package on the bin_url
  #
  # NO_DEFAULT_PATH: keep the system packages out
  # NO_CMAKE_FIND_ROOT_PATH: keep the sysroot out
  # GLOBAL: make the found package available globally
  find_package(
    ${dep_name}
    REQUIRED
    PATHS
    ${${_lc_dep_name}_bin_SOURCE_DIR}
    NO_DEFAULT_PATH
    NO_CMAKE_FIND_ROOT_PATH
    GLOBAL
  )
endfunction()

function(_declare_nd_adapter dep_name script_path)
  if(IS_ABSOLUTE ${script_path}
     AND EXISTS ${script_path}
     AND (NOT IS_DIRECTORY ${script_path})
  )
    include(${script_path})
  else()
    message(
      FATAL_ERROR
        "${script_path} is not a valid, absolute, cmake-adapter script path"
    )
  endif()
endfunction()

# ##############################################################################
# Internal macros
# ##############################################################################

# Helper macro to parse functions arguments for both:
# - declare_default_native_dependency
# - declare_override_native_dependency
macro(_parse_declare_native_dependency_args function_name)
  set(_options "")
  set(_one_value
      MODE
      SOURCE_URL
      SOURCE_HASH
      GIT_URL
      GIT_TAG
      BIN_URL
      BIN_HASH
      SCRIPT
  )
  set(_multi_value OPTIONS)
  cmake_parse_arguments(
    PARSE_ARGV 1 ARG "${_options}" "${_one_value}" "${_multi_value}"
  )

  if(ARG_UNPARSED_ARGUMENTS)
    message(
      FATAL_ERROR
        "${function_name}: unknown arguments: ${ARG_UNPARSED_ARGUMENTS}"
    )
  endif()
  if(ARG_KEYWORDS_MISSING_VALUES)
    message(
      FATAL_ERROR
        "${function_name}: missing value for: ${ARG_KEYWORDS_MISSING_VALUES}"
    )
  endif()

  foreach(_arg MODE)
    if(NOT ARG_${_arg})
      message(FATAL_ERROR "${function_name}: ${_arg} is required")
    endif()
  endforeach()

  # Per-mode required / forbidden keywords. OPTIONS is forbidden for the modes
  # that consume a prebuilt artefact, where it could only be silently ignored.
  if(ARG_MODE STREQUAL "sysroot")
    set(_required "")
    set(_forbidden
        SOURCE_URL
        SOURCE_HASH
        GIT_URL
        GIT_TAG
        BIN_URL
        BIN_HASH
        SCRIPT
        OPTIONS
    )
  elseif(ARG_MODE STREQUAL "source_url")
    set(_required SOURCE_URL SOURCE_HASH)
    set(_forbidden BIN_URL BIN_HASH SCRIPT GIT_URL GIT_TAG)
  elseif(ARG_MODE STREQUAL "bin_url")
    set(_required BIN_URL BIN_HASH)
    set(_forbidden SOURCE_URL SOURCE_HASH SCRIPT GIT_URL GIT_TAG OPTIONS)
  elseif(ARG_MODE STREQUAL "git")
    set(_required GIT_URL GIT_TAG)
    set(_forbidden SOURCE_URL SOURCE_HASH BIN_URL BIN_HASH SCRIPT)
  elseif(ARG_MODE STREQUAL "cmake_adapter")
    set(_required SCRIPT)
    set(_forbidden SOURCE_URL SOURCE_HASH BIN_URL BIN_HASH OPTIONS)
  else()
    message(
      FATAL_ERROR "${function_name}(${dep_name}): invalid MODE '${ARG_MODE}' "
                  "(expected sysroot, source_url, git, bin_url, cmake_adapter)"
    )
  endif()

  foreach(_arg IN LISTS _required)
    if(NOT ARG_${_arg})
      message(
        FATAL_ERROR
          "${function_name}(${dep_name}): ${_arg} is required in MODE ${ARG_MODE}"
      )
    endif()
  endforeach()
  foreach(_arg IN LISTS _forbidden)
    if(DEFINED ARG_${_arg})
      message(
        FATAL_ERROR
          "${function_name}(${dep_name}): ${_arg} is not allowed in MODE ${ARG_MODE}"
      )
    endif()
  endforeach()

  _nd_parse_options(${function_name} ${dep_name})
endmacro()

# Validate and normalise the OPTIONS keyword into:
#   _ARG_OPTION_KEYS      - the option names, sorted
#   _ARG_OPTION_VAL_<key> - the value declared for each option name
#
# OPTIONS is optional: with the keyword absent, ARG_OPTIONS is undefined, the
# loop below runs zero times and the key list stays empty. A bare OPTIONS with
# no entries is already rejected by the ARG_KEYWORDS_MISSING_VALUES check.
#
# This is a macro so that the results land in the caller's scope, where the
# conflict check, the recording and the apply step all read them from.
macro(_nd_parse_options function_name dep_name)
  # Reset: a macro has no scope of its own, so a key list left over from an
  # earlier declaration in the same directory scope must not leak into this one.
  set(_ARG_OPTION_KEYS "")
  foreach(_option_item IN LISTS ARG_OPTIONS)
    if(NOT _option_item MATCHES "^([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
      message(
        FATAL_ERROR
          "${function_name}(${dep_name}): malformed OPTIONS entry '${_option_item}', "
          "expected KEY=VALUE (quote the entry if its value contains ';')"
      )
    endif()
    set(_option_key "${CMAKE_MATCH_1}")
    if(_option_key IN_LIST _ARG_OPTION_KEYS)
      message(
        FATAL_ERROR
          "${function_name}(${dep_name}): OPTIONS declares '${_option_key}' more than once"
      )
    endif()
    list(APPEND _ARG_OPTION_KEYS "${_option_key}")
    set(_ARG_OPTION_VAL_${_option_key} "${CMAKE_MATCH_2}")
  endforeach()
  # Sorted, so that the order OPTIONS are written in is not significant
  list(SORT _ARG_OPTION_KEYS)
endmacro()

# Apply the declared OPTIONS as normal variables, for a dependency that is about
# to be brought into the source tree.
#
# This is a macro: the variables have to land in the scope that goes on to call
# FetchContent_MakeAvailable()/add_subdirectory(), which is the caller's.
macro(_nd_apply_options dep_name)
  # A dependency whose cmake_minimum_required() asks for less than 3.13, without
  # the ...<max> range form, keeps CMP0077 at OLD. Its option() calls would then
  # ignore the normal variables set below and silently fall back to the upstream
  # defaults. Scoped to this subtree, like the options themselves.
  set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)

  foreach(_option_key IN LISTS _ARG_OPTION_KEYS)
    # Catch an option that something else already set: the declaration is meant
    # to be the single source of truth, and it is about to win silently.
    if(DEFINED ${_option_key} AND NOT "${${_option_key}}" STREQUAL
                                  "${_ARG_OPTION_VAL_${_option_key}}"
    )
      message(
        WARNING
          "Native dependency '${dep_name}': '${_option_key}' was already set to "
          "'${${_option_key}}' outside of OPTIONS (a consumer's CMakeLists, or -D on "
          "the command line). The declared value "
          "'${_ARG_OPTION_VAL_${_option_key}}' takes precedence. Change it with "
          "declare_override_native_dependency(${dep_name} ... OPTIONS ...), "
          "which overrides the declaration itself."
      )
    endif()
    set(${_option_key} "${_ARG_OPTION_VAL_${_option_key}}")
  endforeach()
endmacro()

# Record the declared OPTIONS for a later conflict check, in the same internal
# ENV namespace <prefix> that the declaration's own fields are recorded in:
# "_ND_<dep>" for a default, "_ND_OVERRIDE_<dep>" for an override.
#
# The key list and each value are kept apart, rather than as one "K=V;K=V" blob,
# so that a value which is itself a list survives the round-trip and so that the
# diff below can tell "declared by only one of the two" from "declared by both
# with different values".
function(_nd_store_options prefix)
  foreach(_key IN LISTS _ARG_OPTION_KEYS)
    set(ENV{${prefix}_OPTION_${_key}} "${_ARG_OPTION_VAL_${_key}}")
  endforeach()
  set(ENV{${prefix}_OPTIONS} "${_ARG_OPTION_KEYS}")
endfunction()

# Compare the OPTIONS of the current declaration against the recorded ones and
# return the differences, one line per option, in <out_conflicts>.
#
# An option declared by one of the two but not the other is a difference: not
# declaring an option means "whatever upstream defaults to", which is not the
# same as asking for a value. Values are compared as exact strings - ON and TRUE
# are reported as a conflict, because the variable's type is unknown here and a
# STRING option may legitimately hold the literal "ON". A false negative would
# put back exactly the silent divergence this check exists to catch.
function(_nd_diff_options prefix out_conflicts)
  set(_prev_keys "$ENV{${prefix}_OPTIONS}")

  set(_all ${_prev_keys} ${_ARG_OPTION_KEYS})
  if(_all)
    list(REMOVE_DUPLICATES _all)
    list(SORT _all)
  endif()

  set(_conflicts "")
  foreach(_key IN LISTS _all)
    set(_was "<not declared>")
    set(_now "<not declared>")
    if(_key IN_LIST _prev_keys)
      set(_was "'$ENV{${prefix}_OPTION_${_key}}'")
    endif()
    if(_key IN_LIST _ARG_OPTION_KEYS)
      set(_now "'${_ARG_OPTION_VAL_${_key}}'")
    endif()
    if(NOT _was STREQUAL _now)
      string(APPEND _conflicts
             "\n  OPTIONS ${_key}: ${_was} (previous) vs ${_now} (current)"
      )
    endif()
  endforeach()

  set(${out_conflicts}
      "${_conflicts}"
      PARENT_SCOPE
  )
endfunction()

# ##############################################################################
# Misc
# ##############################################################################

# declare_override_native_dependency(
#   tracy_ruby
#   MODE source
#   SOURCE_URL git@github.com:maxmarsc/tracy-ruby.git
#   SOURCE_TAG de2e1034711e668834b8850cf85afb5693727653
# )

# Test fields, to be deleted
# declare_default_native_dependency(OpenAL MODE sysroot)
# declare_default_native_dependency(
#   tracy_ruby
#   MODE
#   source
#   SOURCE_URL
#   git@github.com:maxmarsc/tracy-ruby.git
#   SOURCE_TAG
#   "main"
# )
# declare_default_native_dependency(
#   NAME
#   Test3
#   MODE
#   bin_url
#   BIN_URL
#   "http://example.com/test.tar.gz"
#   BIN_HASH
#   "abcd1234"
# )
