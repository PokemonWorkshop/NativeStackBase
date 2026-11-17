# The scalar fields are compared too, not only OPTIONS.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
)
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH
    "SHA256=0000000000000000000000000000000000000000000000000000000000000000"
)
