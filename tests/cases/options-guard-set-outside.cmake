# An option set by the consumer instead of through OPTIONS is about to be
# overwritten silently, so the helper warns. The declared value still wins.
set(DEMO_OPT OFF)
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OPT=ON
)
