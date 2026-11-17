# A package of the same name is reachable through CMAKE_PREFIX_PATH, but the
# downloaded archive does not carry a config for it. bin_url must fail rather
# than quietly satisfy the dependency from the system: the whole point of the
# mode is that the archive is what gets linked.
list(APPEND CMAKE_PREFIX_PATH "${ND_FIXTURES_DIR}/sysrootpkg")

# The binpkg archive provides NdFakeBinDep, not NdFakeDep.
declare_default_native_dependency(
  NdFakeDep
  MODE bin_url
  BIN_URL "${ND_BIN_ARCHIVE}"
  BIN_HASH "${ND_BIN_HASH}"
)
