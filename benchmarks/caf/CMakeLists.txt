cmake_minimum_required(VERSION 3.20)
project(caf_bench LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(FetchContent)
set(CAF_ENABLE_EXAMPLES OFF CACHE BOOL "" FORCE)
set(CAF_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
set(CAF_ENABLE_TOOLS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(
  caf
  GIT_REPOSITORY https://github.com/actor-framework/actor-framework.git
  GIT_TAG 1.1.0
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(caf)

add_executable(caf_bench main.cpp)
target_link_libraries(caf_bench PRIVATE CAF::core)
