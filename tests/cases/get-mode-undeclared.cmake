# Asking about a dependency nothing declared reports NOTFOUND rather than an
# empty string that would quietly match an else-branch.
nd_get_dependency_mode(never_declared _mode)
if(NOT _mode STREQUAL "NOTFOUND")
  message(FATAL_ERROR "expected 'NOTFOUND', got '${_mode}'")
endif()
message(STATUS "MODE REPORTED: ${_mode}")
