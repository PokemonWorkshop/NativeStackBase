# A sysroot dependency must expose its targets the way the in-tree modes do:
# globally. find_package() creates IMPORTED targets scoped to the directory that
# called it, so without the GLOBAL keyword a dependency declared inside a
# sub-repo is invisible to its siblings and to the top level - while
# source_url/git mode produces ordinary, global targets. The two modes would then
# not be interchangeable, which the whole design depends on.
set(NdFakeDep_DIR "${ND_FIXTURES_DIR}/sysrootpkg")
set(ND_SCOPE_TARGET NdFakeDep::NdFakeDep)

add_subdirectory("${ND_FIXTURES_DIR}/scopes/sysroot-declarer" declarer)
add_subdirectory("${ND_FIXTURES_DIR}/scopes/sibling" sibling)

if(NOT TARGET NdFakeDep::NdFakeDep)
  message(FATAL_ERROR "SCOPE top-level: NdFakeDep::NdFakeDep NOT VISIBLE")
endif()
message(STATUS "SCOPE top-level: VISIBLE")
