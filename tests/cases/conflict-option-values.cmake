# Two declarations agreeing on the version but disagreeing on an option is the
# silent divergence the conflict check exists to catch.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OPT=ON
)
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OPT=OFF
)
