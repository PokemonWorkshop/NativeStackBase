# The same option declared twice in one call is ambiguous.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OPT=ON DEMO_OPT=OFF
)
