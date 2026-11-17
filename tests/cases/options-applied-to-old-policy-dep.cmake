# A declared option must reach the dependency even though the fixture keeps
# CMP0077 at OLD, and an option that is not declared must keep its upstream
# default.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OPT=ON
)
