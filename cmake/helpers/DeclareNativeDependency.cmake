include(FetchContent)

# ##############################################################################
# Public API
# ##############################################################################

# declare_default_native_dependency()
#
# Declare a default version to use for a given native dependency. Supports four modes
#   "sysroot"       - Use the system/toolchain-installed version of the dependency through find_package.
#   "source"/"git"  - Fetch the source code using FetchContent
#   "bin_url"       - Download and extract the compiled dependency from a url containing a CMake config file
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
#   MODE git
#   GIT_URL <git_url>
#   GIT_TAG <git_tag>
# )
# declare_default_native_dependency(
#   <name>
#   MODE source_url
#   SOURCE_URL <source_url>
#   SOURCE_HASH <source_hash>
# )
# declare_default_native_dependency(
#   <name>
#   MODE bin_url
#   BIN_URL <bin_url_url>
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
#   MODE                - Type of source, supports "sysroot", "source", "bin_url". Defines what
#                         other parameters are required.
#
#   MODE "git" parameters:
#   GIT_URL            - The url of the git repo to fetch the source from. It must supports FetchContent.
#   GIT_TAG            - The git tag/branch/commit to checkout.
#
#   MODE "source_url" parameters:
#   SOURCE_URL          - The url of tar/zip archive containing the source code.
#   SOURCE_HASH         - The hash for verification (e.g., "MD5=...").
#
#   MODE "bin_url" parameters:
#   BIN_URL         - The URL of the bin_url to download. It must contains a subdirectory named "cmake"
#                          containing a valid CMake config file for find_package
#   BIN_HASH        - The hash for verification (e.g., "MD5=...").
#
#   MODE "cmake_adapter" parameters:
#   SCRIPT              - The full path (not relative) to the adapter script to call
#
# The user can override the default native dependency by calling declare_override_native_dependency.
# Or, the equivalent, by setting the corresponding CACHE variables before the call of declare_default_native_dependency:
#   ND_OVERRIDE_MODE_<NAME>           - The override mode for the dependency.
#   ND_OVERRIDE_SOURCE_URL_<NAME>     - The override URL for the source mode.
#   ND_OVERRIDE_SOURCE_TAG_<NAME>     - The override tag for the source mode.
#   ND_OVERRIDE_BIN_URL_<NAME>    - The override URL for the bin_url mode.
#   ND_OVERRIDE_BIN_HASH_<NAME>   - The override hash for the bin_url mode.
#   ND_OVERRIDE_SCRIPT_<NAME>         - The override hash for the bin_url mode.
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
    elseif(ARG_MODE STREQUAL "source_url")
      _declare_dnd_source_url(${dep_name} ${ARG_SOURCE_URL} ${ARG_SOURCE_HASH})
    elseif(ARG_MODE STREQUAL "git")
      _declare_dnd_git(${dep_name} ${ARG_GIT_URL} ${ARG_GIT_TAG})
    elseif(ARG_MODE STREQUAL "bin_url")
      _declare_dnd_bin_url(${dep_name} ${ARG_BIN_URL} ${ARG_BIN_HASH})
    elseif(ARG_MODE STREQUAL "cmake_adapter")
      _declare_dnd_adapter(${dep_name} ${ARG_SCRIPT})
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

  # TODO: Check for already defined default declaration - an override must always occurs before the default

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
  elseif(ARG_MODE STREQUAL "source_url")
    _declare_dnd_source_url(${dep_name} ${ARG_SOURCE_URL} ${ARG_SOURCE_HASH})
  elseif(ARG_MODE STREQUAL "git")
    _declare_dnd_git(${dep_name} ${ARG_GIT_URL} ${ARG_GIT_TAG})
  elseif(ARG_MODE STREQUAL "bin_url")
    _declare_dnd_bin_url(${dep_name} ${ARG_BIN_URL} ${ARG_BIN_HASH})
  elseif(ARG_MODE STREQUAL "cmake_adapter")
    _declare_dnd_adapter(${dep_name} ${ARG_SCRIPT})
  else()
    message(
      FATAL_ERROR
        "declare_override_native_dependency(${dep_name}): invalid MODE '${ARG_MODE}' "
        "(expected sysroot, source_url, git, bin_url or cmake_adapter)"
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

# Download the source code of a library from a bin_url
function(_declare_dnd_source_url dep_name url hash)
  FetchContent_Declare(
    ${dep_name}
    URL ${url}
    URL_HASH ${hash}
    OVERRIDE_FIND_PACKAGE
  )
  FetchContent_MakeAvailable(${dep_name})
endfunction()

# Download the source code of a library from a git repository
function(_declare_dnd_git dep_name url tag)
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
function(_declare_dnd_bin_url dep_name url hash)
  # Download the tar ball, checks its hash and extract it
  FetchContent_Declare(
    ${dep_name}_bin
    URL ${url}
    URL_HASH ${hash}
  )
  FetchContent_MakeAvailable(${dep_name}_bin)
  FetchContent_GetProperties(${dep_name}_bin)

  # try find_package on the bin_url
  find_package(
    ${dep_name} REQUIRED PATHS ${dep_name}_bin_SOURCE_DIR
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
      SOURCE_HASH
      GIT_URL
      GIT_TAG
      BIN_URL
      BIN_HASH
      SCRIPT
  )
  set(_multi_value "")
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

  # Per-mode required / forbidden keywords
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
    )
  elseif(ARG_MODE STREQUAL "source_url")
    set(_required SOURCE_URL SOURCE_HASH)
    set(_forbidden BIN_URL BIN_HASH SCRIPT GIT_URL GIT_HASH)
  elseif(ARG_MODE STREQUAL "bin_url")
    set(_required BIN_URL BIN_HASH)
    set(_forbidden SOURCE_URL SOURCE_HASH SCRIPT GIT_URL GIT_TAG)
  elseif(ARG_MODE STREQUAL "git")
    set(_required GIT_URL GIT_TAG)
    set(_forbidden SOURCE_URL SOURCE_HASH BIN_URL BIN_HASH SCRIPT)
  elseif(ARG_MODE STREQUAL "cmake_adapter")
    set(_required SCRIPT)
    set(_forbidden SOURCE_URL SOURCE_HASH BIN_URL BIN_HASH)
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
endmacro()

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
