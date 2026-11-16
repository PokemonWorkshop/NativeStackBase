cmake_minimum_required(VERSION 3.28)
project(NativeStackBase)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake
     ${CMAKE_CURRENT_LIST_DIR}/cmake/helpers
)

# ##############################################################################
# Define helpers
# ##############################################################################
include(DeclareNativeDependency)
