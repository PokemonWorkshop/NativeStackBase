# An adapter sets whatever options its dependency needs internally.
declare_default_native_dependency(
  demodep
  MODE cmake_adapter
  SCRIPT "${ND_CASE}"
  OPTIONS DEMO_OPT=ON
)
