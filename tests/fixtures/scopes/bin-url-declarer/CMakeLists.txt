# Same, for a dependency downloaded prebuilt.
declare_default_native_dependency(
  NdFakeBinDep
  MODE bin_url
  BIN_URL "${ND_BIN_ARCHIVE}"
  BIN_HASH "${ND_BIN_HASH}"
)

if(NOT TARGET NdFakeBinDep::NdFakeBinDep)
  message(
    FATAL_ERROR
      "SCOPE declarer: NdFakeBinDep::NdFakeBinDep is missing even where it was declared"
  )
endif()
message(STATUS "SCOPE declarer: VISIBLE")
