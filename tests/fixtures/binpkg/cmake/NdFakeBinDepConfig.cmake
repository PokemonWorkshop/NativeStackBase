# Stands in for the CMake config shipped inside a prebuilt archive, found by
# bin_url mode after extraction.
add_library(
  NdFakeBinDep::NdFakeBinDep INTERFACE IMPORTED
)
set(NdFakeBinDep_FOUND TRUE)
