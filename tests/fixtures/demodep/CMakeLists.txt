# A stand-in for a real native dependency, packed into an archive by the test
# suite at configure time.
#
# The minimum required version is deliberately old: anything below 3.13, without
# the ...<max> range form, leaves CMP0077 at OLD, so option() ignores a normal
# variable of the same name set by the parent. That is the case OPTIONS has to
# survive, so the fixture reproduces it rather than hiding it.
cmake_minimum_required(VERSION 3.10)
project(demodep LANGUAGES NONE)

option(DEMO_OPT "An option the test suite sets through OPTIONS" OFF)
option(DEMO_OTHER "An option the test suite usually leaves alone" OFF)

# message(STATUS) is not line-wrapped by CMake, so the test regexes can match it
# in one piece.
message(STATUS "DEP SEES DEMO_OPT='${DEMO_OPT}' DEMO_OTHER='${DEMO_OTHER}'")
