# The baseline the sysroot and bin_url cases are measured against: a dependency
# built in-tree produces ordinary targets, which are global already.
set(ND_SCOPE_TARGET demodep_marker)

add_subdirectory("${ND_FIXTURES_DIR}/scopes/source-url-declarer" declarer)
add_subdirectory("${ND_FIXTURES_DIR}/scopes/sibling" sibling)
message(STATUS "SCOPE top-level: VISIBLE")
