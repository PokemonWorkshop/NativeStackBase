include(FetchContent)

# ##############################################################################
# Public API
# ##############################################################################

# declare_default_native_dependency()
#
# Declare a default version to use for a given native dependency. Supports four modes
#   "sysroot"       - Use the system/toolchain-installed version of the dependency through find_package.
#   "source"        - Fetch the dependency from a git repository using FetchContent
#   "tarball"       - Download and extract the dependency from a tarball containing a CMake config file
#   "cmake_adapter" - Call a custom CMake script to expose targets to CMake
#
# It will set internal ENV variables to track the declared default native dependency. If another
# call to declare_default_native_dependency is made for the same NAME, it will check for conflicts.
#
# If the duplicate declaration conflicts with the previous one, an error will be raised.
#
# Usage:
# declare_default_native_dependency(
#   <name>
#   MODE source
#   SOURCE_URL <source_url>
#   SOURCE_TAG <source_tag>
# )
# declare_default_native_dependency(
#   <name>
#   MODE tarball
#   TARBALL_URL <tarball_url>
#   TARBALL_HASH <tarball_hash>
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
#   MODE                - Type of source, supports "sysroot", "source", "tarball". Defines what
#                         other parameters are required.
#
#   MODE "source" parameters:
#   SOURCE_URL          - The url of the git repo to fetch the source from. It must supports FetchContent.
#   SOURCE_TAG          - The git tag/branch/commit to checkout.
#
#   MODE "tarball" parameters:
#   TARBALL_URL         - The URL of the tarball to download. It must contains a subdirectory named "cmake"
#                          containing a valid CMake config file for find_package
#   TARBALL_HASH        - The hash for verification (e.g., "MD5=...").
#
#   MODE "cmake_adapter" parameters:
#   SCRIPT              - The full path (not relative) to the adapter script to call
#
# The user can override the default native dependency by calling declare_override_native_dependency.
# Or, the equivalent, by setting the corresponding CACHE variables before the call of declare_default_native_dependency:
#   ND_OVERRIDE_MODE_<NAME>           - The override mode for the dependency.
#   ND_OVERRIDE_SOURCE_URL_<NAME>     - The override URL for the source mode.
#   ND_OVERRIDE_SOURCE_TAG_<NAME>     - The override tag for the source mode.
#   ND_OVERRIDE_TARBALL_URL_<NAME>    - The override URL for the tarball mode.
#   ND_OVERRIDE_TARBALL_HASH_<NAME>   - The override hash for the tarball mode.
#   ND_OVERRIDE_SCRIPT_<NAME>         - The override hash for the tarball mode.
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
      if(NOT "${${_prefix}_${_key}}" STREQUAL "${ARG_${_key}}")
        string(
          APPEND
          _conflicts
          "\n  ${_key}: '${${_prefix}_${_key}}' (previous) vs '${ARG_${_key}}' (current)"
        )
      endif()
    endforeach()

    if(_conflicts)
      message(CHECK_FAIL "uncompatible previous declaration")
      message(
        FATAL_ERROR
          "Conflicting declarations for native dependency '${dep_name}':${_conflicts}"
      )
    endif()

    message(CHECK_PASS "found compatible declaration - skipping redeclaration")
  elseif(NOT DEFINED CACHE{ND_OVERRIDE_MODE_${dep_name}})
    # First declaration - declare the ENV values
    message(CHECK_PASS "found none")
    foreach(_key IN LISTS _one_value)
      if(NOT _key STREQUAL "NAME")
        set(ENV{${_prefix}_${_key}} "${ARG_${_key}}")
      endif()
    endforeach()

    # Then actually fetch/find the dependency
    if(ARG_MODE STREQUAL "sysroot")
      _declare_dnd_sysroot(${dep_name})
    elseif(ARG_MODE STREQUAL "source")
      _declare_dnd_source(${dep_name} ${ARG_SOURCE_URL} ${ARG_SOURCE_TAG})
    elseif(ARG_MODE STREQUAL "tarball")
      _declare_dnd_tarball(${dep_name} ${ARG_TARBALL_URL} ${ARG_TARBALL_HASH})
    elseif(ARG_MODE STREQUAL "cmake_adapter")
      _declare_dnd_adapter(${dep_name} ${ARG_SCRIPT})
    else()
      message(
        FATAL_ERROR
          "declare_default_native_dependency(${dep_name}): invalid MODE '${ARG_MODE}' "
          "(expected sysroot, source or tarball)"
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

  # Check for already defined default declaration - an override must always occurs before the default

  # Conflict check against a previous declaration
  message(CHECK_START "Checking ${dep_name} for previous override declaration")
  set(_prefix "ND_OVERRIDE")
  set(_suffix "${dep_name}")
  if(DEFINED CACHE{${_prefix}_MODE_${_suffix}})
    set(_conflicts "")
    foreach(_key IN LISTS _one_value)
      if(_key STREQUAL "NAME")
        continue()
      endif()
      if(NOT "${${_prefix}_${_key}_${_suffix}}" STREQUAL "${ARG_${_key}}")
        string(
          APPEND
          _conflicts
          "\n  ${_key}: '${${_prefix}_${_key}_${_suffix}}' (previous) vs '${ARG_${_key}}' (current)"
        )
      endif()
    endforeach()

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
    # First declaration - declare the CACHE values
    message(CHECK_PASS "found none")
    foreach(_key IN LISTS _one_value)
      if(NOT _key STREQUAL "NAME")
        set(${_prefix}_${_key}
            "${ARG_${_key}}"
            CACHE INTERNAL ""
        )
      endif()
    endforeach()
  endif()

  # Then actually calls the underlying logic
  if(ARG_MODE STREQUAL "sysroot")
    _declare_dnd_sysroot(${dep_name})
  elseif(ARG_MODE STREQUAL "source")
    _declare_dnd_source(${dep_name} ${ARG_SOURCE_URL} ${ARG_SOURCE_TAG})
  elseif(ARG_MODE STREQUAL "tarball")
    _declare_dnd_tarball(${dep_name} ${ARG_TARBALL_URL} ${ARG_TARBALL_HASH})
  elseif(ARG_MODE STREQUAL "cmake_adapter")
    _declare_dnd_adapter(${dep_name} ${ARG_SCRIPT})
  else()
    message(
      FATAL_ERROR
        "declare_override_native_dependency(${dep_name}): invalid MODE '${ARG_MODE}' "
        "(expected sysroot, source or tarball)"
    )
  endif()

endfunction()

# ##############################################################################
# Internal functions
# ##############################################################################

# Find a library on the sysroot / system
function(_declare_dnd_sysroot dep_name)
  find_package(${dep_name} REQUIRED)
endfunction()

# Download the source code of a library
function(_declare_dnd_source dep_name url tag)
  FetchContent_Declare(
    _${dep_name}_fetch_content
    GIT_REPOSITORY ${url}
    GIT_TAG ${tag}
    # TODO: enable GIT_SHALLOW for branches / tags by adding a specific flag ?
  )
  FetchContent_MakeAvailable(_${dep_name}_fetch_content)
endfunction()

# Find a library by downloading its tarball
function(_declare_dnd_tarball dep_name url hash)
  # Download the tar ball, checks its hash and extract it
  FetchContent_Declare(
    _${dep_name}_fetch_content
    URL ${url}
    URL_HASH ${hash}
  )
  FetchContent_MakeAvailable(_${dep_name}_fetch_content)
  FetchContent_GetProperties(_${dep_name}_fetch_content)

  # try find_package on the tarball
  find_package(
    ${dep_name}
    REQUIRED
    PATHS
    _${dep_name}_fetch_content_SOURCE_DIR
    NO_CMAKE_FIND_ROOT_PATH
  )
endfunction()

function(_declare_dnd_adapter dep_name script_path)
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
      SOURCE_TAG
      TARBALL_URL
      TARBALL_HASH
      SCRIPT
  )
  set(_multi_value "")
  cmake_parse_arguments(
    PARSE_ARGV
    1
    ARG
    "${_options}"
    "${_one_value}"
    "${_multi_value}"
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

  # Per-mode required / forbidden keywords
  if(ARG_MODE STREQUAL "sysroot")
    set(_required "")
    set(_forbidden
        SOURCE_URL
        SOURCE_TAG
        TARBALL_URL
        TARBALL_HASH
        SCRIPT
    )
  elseif(ARG_MODE STREQUAL "source")
    set(_required SOURCE_URL SOURCE_TAG)
    set(_forbidden TARBALL_URL TARBALL_HASH SCRIPT)
  elseif(ARG_MODE STREQUAL "tarball")
    set(_required TARBALL_URL TARBALL_HASH)
    set(_forbidden SOURCE_URL SOURCE_TAG SCRIPT)
  elseif(ARG_MODE STREQUAL "cmake_adapter")
    set(_required SCRIPT)
    set(_forbidden SOURCE_URL SOURCE_TAG TARBALL_URL TARBALL_HASH)
  else()
    message(
      FATAL_ERROR "${function_name}(${dep_name}): invalid MODE '${ARG_MODE}' "
                  "(expected sysroot, source or tarball)"
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
endmacro()

# ##############################################################################
# Misc
# ##############################################################################

# declare_override_native_dependency(
#   tracy_ruby
#   MODE
#   source
#   SOURCE_URL
#   git@github.com:maxmarsc/tracy-ruby.git
#   SOURCE_TAG
#   de2e1034711e668834b8850cf85afb5693727653
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
#   tarball
#   TARBALL_URL
#   "http://example.com/test.tar.gz"
#   TARBALL_HASH
#   "abcd1234"
# )
