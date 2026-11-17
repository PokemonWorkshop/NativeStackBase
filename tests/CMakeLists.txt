# ##############################################################################
# Helper test suite
#
# Every case is a separate cmake configure run: the helpers record declarations
# in internal ENV variables, which live as long as the cmake process, so cases
# have to be isolated by process rather than by scope. CTest drives them and
# judges each one on what the configure printed. See README.md.
# ##############################################################################

# The fake dependency is packed at configure time, so that the repository stays
# text-only and so that source_url mode gets a real archive and a real hash to
# verify rather than a stub.
set(ND_TEST_FIXTURE "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/demodep")
set(ND_TEST_ARCHIVE "${CMAKE_CURRENT_BINARY_DIR}/demodep.tar.gz")

execute_process(
  COMMAND ${CMAKE_COMMAND} -E tar czf "${ND_TEST_ARCHIVE}" .
  WORKING_DIRECTORY "${ND_TEST_FIXTURE}"
  RESULT_VARIABLE _tar_result
  OUTPUT_VARIABLE _tar_output
  ERROR_VARIABLE _tar_output
)
if(NOT _tar_result EQUAL 0)
  message(FATAL_ERROR "Failed to pack the demodep fixture: ${_tar_output}")
endif()
file(SHA256 "${ND_TEST_ARCHIVE}" _archive_sha256)
set(ND_TEST_HASH "SHA256=${_archive_sha256}")

# Repack when the fixture changes, which a plain execute_process would not catch.
set_property(
  DIRECTORY
  APPEND
  PROPERTY CMAKE_CONFIGURE_DEPENDS "${ND_TEST_FIXTURE}/CMakeLists.txt"
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
      "-DND_CASE=${_case}" "-DND_DEP_ARCHIVE=${ND_TEST_ARCHIVE}"
      "-DND_DEP_HASH=${ND_TEST_HASH}"
  )
  set_tests_properties(${name} PROPERTIES PASS_REGULAR_EXPRESSION "${ARG_PASS}")
  if(NOT ARG_EXPECT_ERROR)
    set_tests_properties(
      ${name} PROPERTIES FAIL_REGULAR_EXPRESSION "CMake Error"
    )
  endif()
endfunction()

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
