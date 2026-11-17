# Declares an in-tree dependency from a directory scope of its own, as the
# baseline the sysroot and bin_url scope cases are compared against.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
)

if(NOT TARGET demodep_marker)
  message(
    FATAL_ERROR
      "SCOPE declarer: demodep_marker is missing even where it was declared"
  )
endif()
message(STATUS "SCOPE declarer: VISIBLE")
