# A sysroot dependency is already built: a build option could only be ignored.
declare_default_native_dependency(
  demodep
  MODE sysroot
  OPTIONS DEMO_OPT=ON
)
