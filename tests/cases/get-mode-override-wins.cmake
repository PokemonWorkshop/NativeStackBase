# An override replaces the default, so its mode is the effective one. The two
# declarations deliberately use different modes: reading the default's record
# here would report "source_url" and go unnoticed if both agreed.
set(NdFakeDep_DIR "${ND_FIXTURES_DIR}/sysrootpkg")

declare_override_native_dependency(NdFakeDep MODE sysroot)
declare_default_native_dependency(
  NdFakeDep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
)

nd_get_dependency_mode(NdFakeDep _mode)
if(NOT _mode STREQUAL "sysroot")
  message(FATAL_ERROR "expected the override's 'sysroot', got '${_mode}'")
endif()
message(STATUS "MODE REPORTED: ${_mode}")
