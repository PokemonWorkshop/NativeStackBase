# The mode of a plain default declaration is reported as declared.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
)

nd_get_dependency_mode(demodep _mode)
if(NOT _mode STREQUAL "source_url")
  message(FATAL_ERROR "expected 'source_url', got '${_mode}'")
endif()
message(STATUS "MODE REPORTED: ${_mode}")
