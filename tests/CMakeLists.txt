cmake_minimum_required(VERSION 3.20)

enable_testing()

# Dependencies
find_package(Boost 1.83.0 REQUIRED COMPONENTS system thread unit_test_framework)
#find_package(Boost COMPONENTS filesystem system unit_test_framework REQUIRED)

# Collect all the source files for the unit testing
file(GLOB_RECURSE TEST_SRCS ./game_test.cpp)

add_executable(tests ${TEST_SRCS})

# Specify the include directories
include_directories(${CMAKE_SOURCE_DIR}/include)
include_directories(${Boost_INCLUDE_DIR})
include_directories(${CMAKE_BINARY_DIR})


target_link_libraries(tests PRIVATE CLI11::CLI11)
target_link_libraries(tests PRIVATE Boost::boost)
target_link_libraries(tests PRIVATE Boost::unit_test_framework)

add_test(NAME UnitTesting COMMAND tests)
