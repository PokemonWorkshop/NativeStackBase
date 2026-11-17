# The options are scoped to the fetched subproject: they must not reach the
# consumer's own scope, nor the cache.
declare_default_native_dependency(
  demodep
  MODE source_url
  SOURCE_URL "${ND_DEP_ARCHIVE}"
  SOURCE_HASH "${ND_DEP_HASH}"
  OPTIONS DEMO_OPT=ON
)

if(DEFINED DEMO_OPT)
  message(
    FATAL_ERROR "DEMO_OPT leaked into the consumer scope as '${DEMO_OPT}'"
  )
endif()
if(DEFINED CACHE{DEMO_OPT})
  message(FATAL_ERROR "DEMO_OPT leaked into the cache")
endif()
message(STATUS "OPTIONS DID NOT LEAK")
