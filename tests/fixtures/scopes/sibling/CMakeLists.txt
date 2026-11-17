# A sibling directory scope. It declared nothing, but the target contract says a
# dependency's targets must be usable from anywhere in the tree, whatever mode
# provided it.
if(NOT DEFINED ND_SCOPE_TARGET)
  message(FATAL_ERROR "sibling fixture: the case must set ND_SCOPE_TARGET")
endif()

if(TARGET ${ND_SCOPE_TARGET})
  message(STATUS "SCOPE sibling: VISIBLE")
else()
  message(
    FATAL_ERROR
      "SCOPE sibling: ${ND_SCOPE_TARGET} NOT VISIBLE. find_package() creates "
      "directory-scoped IMPORTED targets, so a dependency declared inside one "
      "sub-repo never reaches its siblings unless the call asks for GLOBAL."
  )
endif()
