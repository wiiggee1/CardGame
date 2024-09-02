cmake_minimum_required(VERSION 3.20)
project(apples2apples VERSION 1.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_COMPILER_LAUNCHER "ccache")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CONFIG_DIR "${CMAKE_CURRENT_SOURCE_DIR}/data/")

# Proccess <input file> as the first argument, generates an <output file> as second argument. 
# The input file typically contains placeholders for variables that are to be replaced. 
# There is two placeholder formats: 
    # @VAR@: This format is replaced by the value of `VAR`
    # `${VAR}`: This format is also replaced by the value of `VAR`, unless `@ONLY` is specified.
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/config.h.in #<input> argument. 
    ${CMAKE_BINARY_DIR}/config.h            #<output> argument.
    @ONLY                                   #Only variable with the placeholder `@VAR@` syntax will be replaced.
)

add_compile_options(-Wall -Wextra -Wpedantic)

message("Cmake current source directory = ${CMAKE_CURRENT_SOURCE_DIR}")
message("System OS: ${CMAKE_SYSTEM_NAME}")
message("Compiler:" ${CMAKE_CXX_COMPILER})
message("Linker used:" ${CMAKE_LINK_WHAT_YOU_USE_CHECK})
message("Config path: = ${CONFIG_DIR}")

find_package(Boost 1.83.0 REQUIRED COMPONENTS system thread)

#FetchContent_Declare(
    #    <name>                # The name of the content
    #    GIT_REPOSITORY <url>  # The URL to the Git repository
    #    GIT_TAG <tag>         # The Git tag, branch, or commit to checkout
    # Additional options like URL, etc. can be used instead of GIT_REPOSITORY
    #)

include(FetchContent)

FetchContent_Declare(
    cli11_proj
    QUIET
    GIT_REPOSITORY https://github.com/CLIUtils/CLI11.git
    GIT_TAG v2.3.2
)

FetchContent_MakeAvailable(cli11_proj)

# Specify the include directories
include_directories(./include)
include_directories(${Boost_INCLUDE_DIR})
include_directories(${CMAKE_BINARY_DIR})

# Collect all the source files in the src directory
file(GLOB_RECURSE SRCS ./src/*.cpp)

add_executable(apples2apples ${SRCS})

target_link_libraries(apples2apples PRIVATE CLI11::CLI11)
target_link_libraries(apples2apples PRIVATE Boost::boost)
