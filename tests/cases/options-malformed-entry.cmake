# KEY=VALUE is self-delimiting on purpose: writing the pair with a space, the
# classic mistake, is rejected instead of being read as two broken entries.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OPT ON
)
