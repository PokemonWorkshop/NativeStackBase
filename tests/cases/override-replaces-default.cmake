# An override declared before the default replaces the whole configuration,
# OPTIONS included: the default's DEMO_OPT=ON is not merged in.
declare_override_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OTHER=ON
)
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OPT=ON
)
