project(TestLib)

cmake_minimum_required(VERSION 3.5)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(CMAKE_BUILD_RPATH 1)
else()
  set(CMAKE_MACOSX_RPATH 1)
endif()
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

find_package(JlCxx)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")
message(STATUS "Found JlCxx at ${JlCxx_location}")

add_library(testlib SHARED julia_nvdb_wrapper.cpp)

option(NANOVDB_USE_ZLIB "Build with ZLIB support" ON)
if(NANOVDB_USE_ZLIB AND NOT TARGET ZLIB::ZLIB)
  find_package(ZLIB REQUIRED)
endif()
target_link_libraries(testlib ZLIB::ZLIB)
target_compile_definitions(testlib INTERFACE -DNANOVDB_USE_ZIP)


target_link_libraries(testlib JlCxx::cxxwrap_julia)

install(TARGETS
  testlib
LIBRARY DESTINATION lib
ARCHIVE DESTINATION lib
RUNTIME DESTINATION lib)