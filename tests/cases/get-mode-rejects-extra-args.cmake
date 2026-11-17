# A misspelled or forgotten out-var must not be swallowed.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
)
nd_get_dependency_mode(demodep _mode AND_SOMETHING_ELSE)
