# Same for a prebuilt archive.
declare_default_native_dependency(
  demodep
  MODE bin_url
  BIN_URL "${ND_DEP_ARCHIVE}"
  BIN_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OPT=ON
)
