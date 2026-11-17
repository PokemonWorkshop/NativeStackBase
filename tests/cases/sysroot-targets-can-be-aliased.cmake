# The other consequence of the scope rule: add_library(... ALIAS <imported>)
# refuses an imported target that is not global. Every mode has to be able to
# carry the same alias contract, so this has to work for a sysroot dependency
# just as it does for an in-tree one.
set(NdFakeDep_DIR "${ND_FIXTURES_DIR}/sysrootpkg")
set(ND_SCOPE_TARGET NdFakeDep::NdFakeDep)

add_subdirectory("${ND_FIXTURES_DIR}/scopes/sysroot-declarer" declarer)

add_library(
  NdFakeDep::aliased ALIAS NdFakeDep::NdFakeDep
)
if(NOT TARGET NdFakeDep::aliased)
  message(FATAL_ERROR "ALIAS of the imported target did not take")
endif()
message(STATUS "ALIAS ACCEPTED")
