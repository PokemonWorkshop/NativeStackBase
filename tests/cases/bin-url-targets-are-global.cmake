# bin_url mode finds its config package with find_package() too, so it has the
# same scoping problem and needs the same GLOBAL keyword.
set(ND_SCOPE_TARGET NdFakeBinDep::NdFakeBinDep)

add_subdirectory("${ND_FIXTURES_DIR}/scopes/bin-url-declarer" declarer)
add_subdirectory("${ND_FIXTURES_DIR}/scopes/sibling" sibling)

if(NOT TARGET NdFakeBinDep::NdFakeBinDep)
  message(FATAL_ERROR "SCOPE top-level: NdFakeBinDep::NdFakeBinDep NOT VISIBLE")
endif()
message(STATUS "SCOPE top-level: VISIBLE")
