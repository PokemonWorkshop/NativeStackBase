# Stands in for a config package installed in the sysroot, so that the sysroot
# mode can be tested without depending on any real system package.
#
# The target is created plain: an IMPORTED target is directory-scoped unless the
# find_package() call that produced it asked for GLOBAL. That is precisely what
# the scope cases check.
add_library(
  NdFakeDep::NdFakeDep INTERFACE IMPORTED
)
set(NdFakeDep_FOUND TRUE)
