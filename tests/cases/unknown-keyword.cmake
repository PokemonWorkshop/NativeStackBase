# A misspelled keyword must not be swallowed.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}" OPTION DEMO_OPT=ON
)
