cmake_minimum_required(VERSION 3.28)
project(NativeStackBase)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake
     ${CMAKE_CURRENT_LIST_DIR}/cmake/helpers
)

# ##############################################################################
# Define helpers
# ##############################################################################
include(DeclareNativeDependency)

# ##############################################################################
# Tests
# ##############################################################################
option(HELPER_TEST_SUITE "Enable the CMake helper test suite" OFF)

if(HELPER_TEST_SUITE)
  enable_testing()
  add_subdirectory(tests)
endif()
