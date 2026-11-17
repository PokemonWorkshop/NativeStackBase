# Declares a sysroot dependency from a directory scope of its own, the way a
# FetchContent'd sub-repo declaring its own dependencies would.
declare_default_native_dependency(NdFakeDep MODE sysroot)

if(NOT TARGET NdFakeDep::NdFakeDep)
  message(
    FATAL_ERROR
      "SCOPE declarer: NdFakeDep::NdFakeDep is missing even where it was declared"
  )
endif()
message(STATUS "SCOPE declarer: VISIBLE")
