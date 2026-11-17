# ##############################################################################
# Helper test suite
#
# Every case is a separate cmake configure run: the helpers record declarations
# in internal ENV variables, which live as long as the cmake process, so cases
# have to be isolated by process rather than by scope. CTest drives them and
# judges each one on what the configure printed. See README.md.
# ##############################################################################

set(ND_TEST_FIXTURES "${CMAKE_CURRENT_SOURCE_DIR}/fixtures")

# nd_pack_fixture(<dir> <out_archive_var> <out_hash_var>)
#
# Packs fixtures/<dir> into an archive and returns its path and SHA-256. Packing
# at configure time rather than committing a tarball keeps the repository
# text-only, and still gives the download modes a real archive and a real hash to
# verify instead of a stub.
function(nd_pack_fixture dir out_archive out_hash)
  set(_archive "${CMAKE_CURRENT_BINARY_DIR}/${dir}.tar.gz")
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar czf "${_archive}" .
    WORKING_DIRECTORY "${ND_TEST_FIXTURES}/${dir}"
    RESULT_VARIABLE _tar_result
    OUTPUT_VARIABLE _tar_output
    ERROR_VARIABLE _tar_output
  )
  if(NOT _tar_result EQUAL 0)
    message(FATAL_ERROR "Failed to pack the ${dir} fixture: ${_tar_output}")
  endif()
  file(SHA256 "${_archive}" _sha256)
  set(${out_archive}
      "${_archive}"
      PARENT_SCOPE
  )
  set(${out_hash}
      "SHA256=${_sha256}"
      PARENT_SCOPE
  )
endfunction()

nd_pack_fixture(demodep ND_TEST_ARCHIVE ND_TEST_HASH)
nd_pack_fixture(binpkg ND_TEST_BIN_ARCHIVE ND_TEST_BIN_HASH)

# Repack when a fixture changes, which a plain execute_process would not catch.
file(GLOB_RECURSE _fixture_files CONFIGURE_DEPENDS "${ND_TEST_FIXTURES}/*")
set_property(
  DIRECTORY
  APPEND
  PROPERTY CMAKE_CONFIGURE_DEPENDS ${_fixture_files}
)

# nd_add_case(<name> PASS <regex>... [EXPECT_ERROR])
#
# Registers cases/<name>.cmake as a test. The case is configured as the harness
# project in a build directory of its own, so that cases can run in parallel.
#
# PASS         - the test passes when the configure output matches any of these.
#                Keep each one short: CMake wraps the text of its warnings and
#                errors, and a long regex can end up straddling a line break.
#                message(STATUS) output is never wrapped.
# EXPECT_ERROR - the case is meant to end in a FATAL_ERROR. Without it, a case
#                that matched PASS but still errored somewhere counts as failed.
function(nd_add_case name)
  cmake_parse_arguments(PARSE_ARGV 1 ARG "EXPECT_ERROR" "" "PASS")
  if(ARG_UNPARSED_ARGUMENTS)
    message(
      FATAL_ERROR "nd_add_case: unknown arguments: ${ARG_UNPARSED_ARGUMENTS}"
    )
  endif()
  if(NOT ARG_PASS)
    message(FATAL_ERROR "nd_add_case(${name}): PASS is required")
  endif()

  set(_case "${CMAKE_CURRENT_SOURCE_DIR}/cases/${name}.cmake")
  if(NOT EXISTS "${_case}")
    message(FATAL_ERROR "nd_add_case(${name}): no such case file: ${_case}")
  endif()

  add_test(
    NAME ${name}
    COMMAND
      ${CMAKE_COMMAND} --fresh -S "${CMAKE_CURRENT_SOURCE_DIR}/harness" -B
      "${CMAKE_CURRENT_BINARY_DIR}/cases/${name}"
      "-DND_HELPERS_DIR=${PROJECT_SOURCE_DIR}/cmake/helpers"
      "-DND_CASE=${_case}" "-DND_FIXTURES_DIR=${ND_TEST_FIXTURES}"
      "-DND_DEP_ARCHIVE=${ND_TEST_ARCHIVE}" "-DND_DEP_HASH=${ND_TEST_HASH}"
      "-DND_BIN_ARCHIVE=${ND_TEST_BIN_ARCHIVE}"
      "-DND_BIN_HASH=${ND_TEST_BIN_HASH}"
  )
  set_tests_properties(${name} PROPERTIES PASS_REGULAR_EXPRESSION "${ARG_PASS}")
  if(NOT ARG_EXPECT_ERROR)
    set_tests_properties(
      ${name} PROPERTIES FAIL_REGULAR_EXPRESSION "CMake Error"
    )
  endif()
endfunction()

# ##############################################################################
# Target scope
#
# find_package() creates IMPORTED targets scoped to the directory that called it,
# while the in-tree modes create ordinary, global ones. Unless the find modes ask
# for GLOBAL, a dependency declared inside one sub-repo never reaches its
# siblings, the two kinds of mode stop being interchangeable, and an alias cannot
# be put on the imported target at all. None of that fails loudly on its own, so
# it is pinned here.
# ##############################################################################

nd_add_case(source-url-targets-are-global PASS "SCOPE sibling: VISIBLE")
nd_add_case(sysroot-targets-are-global PASS "SCOPE sibling: VISIBLE")
nd_add_case(bin-url-targets-are-global PASS "SCOPE sibling: VISIBLE")
nd_add_case(
  bin-url-ignores-system-package EXPECT_ERROR PASS
  "Could not find a package configuration file"
)
nd_add_case(sysroot-targets-can-be-aliased PASS "ALIAS ACCEPTED")

# ##############################################################################
# OPTIONS - behaviour
# ##############################################################################

nd_add_case(
  options-applied-to-old-policy-dep PASS
  "DEP SEES DEMO_OPT='ON' DEMO_OTHER='OFF'"
)
nd_add_case(options-absent PASS "DEP SEES DEMO_OPT='OFF' DEMO_OTHER='OFF'")
nd_add_case(options-list-valued PASS "DEP SEES DEMO_OPT='a;b'")
nd_add_case(options-not-leaked PASS "OPTIONS DID NOT LEAK")
nd_add_case(options-order-independent PASS "skipping redeclaration")
nd_add_case(options-guard-set-outside PASS "was already set to")

# ##############################################################################
# Conflict detection
# ##############################################################################

nd_add_case(redeclaration-compatible PASS "skipping redeclaration")
nd_add_case(conflict-option-values EXPECT_ERROR PASS "OPTIONS DEMO_OPT: 'ON'")
nd_add_case(
  conflict-option-declared-vs-omitted EXPECT_ERROR PASS "vs <not declared>"
)
nd_add_case(conflict-source-hash EXPECT_ERROR PASS "SOURCE_HASH: ")

# ##############################################################################
# Overrides
# ##############################################################################

nd_add_case(
  override-replaces-default PASS "DEP SEES DEMO_OPT='OFF' DEMO_OTHER='ON'"
)
nd_add_case(override-then-default-then-override PASS "skipping redeclaration")
nd_add_case(override-conflicting EXPECT_ERROR PASS "OPTIONS DEMO_OTHER: 'ON'")
nd_add_case(override-declared-too-late EXPECT_ERROR PASS "too late")

# ##############################################################################
# Argument validation
# ##############################################################################

nd_add_case(options-malformed-entry EXPECT_ERROR PASS "malformed OPTIONS entry")
nd_add_case(options-duplicate-key EXPECT_ERROR PASS "more than once")
nd_add_case(options-bare-keyword EXPECT_ERROR PASS "missing value for: OPTIONS")
nd_add_case(
  options-forbidden-in-sysroot EXPECT_ERROR PASS "is not allowed in MODE"
)
nd_add_case(
  options-forbidden-in-bin-url EXPECT_ERROR PASS "is not allowed in MODE"
)
nd_add_case(
  options-forbidden-in-adapter EXPECT_ERROR PASS "is not allowed in MODE"
)
nd_add_case(mode-missing EXPECT_ERROR PASS "MODE is required")
nd_add_case(mode-invalid EXPECT_ERROR PASS "invalid MODE")
nd_add_case(
  source-url-rejects-git-tag EXPECT_ERROR PASS "is not allowed in MODE"
)
nd_add_case(unknown-keyword EXPECT_ERROR PASS "unknown arguments")
