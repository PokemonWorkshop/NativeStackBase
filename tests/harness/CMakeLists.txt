# The project every test case is configured as.
#
# It only sets up the module path, loads the helpers and includes the case file.
# Each case therefore contains nothing but the declarations under test, and runs
# in its own cmake process: the internal ENV records the helpers rely on cannot
# leak from one case into another.
cmake_minimum_required(VERSION 3.28)
project(nd_helper_case LANGUAGES NONE)

foreach(
  _required IN
  ITEMS ND_HELPERS_DIR
        ND_CASE
        ND_FIXTURES_DIR
        ND_DEP_ARCHIVE
        ND_DEP_HASH
        ND_BIN_ARCHIVE
        ND_BIN_HASH
)
  if(NOT DEFINED ${_required})
    message(FATAL_ERROR "test harness: -D${_required}=... is required")
  endif()
endforeach()

list(APPEND CMAKE_MODULE_PATH "${ND_HELPERS_DIR}")
include(DeclareNativeDependency)

include("${ND_CASE}")
