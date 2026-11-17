# A value that is itself a list survives the round-trip, as long as the entry is
# quoted at the call site.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS "DEMO_OPT=a;b"
)
