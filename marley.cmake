cmake_minimum_required(VERSION 2.8)
set(CMAKE_DISABLE_SOURCE_CHANGES on)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED on)

project(marley)

set(EXECUTABLE_NAME "marley")

set(INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")
set(SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
include_directories(${INCLUDE_DIR})

file(GLOB SOURCES "src/*.cc")
list(REMOVE_ITEM SOURCES "${SOURCE_DIR}/RootConfigurationFile.cc"
 "${SOURCE_DIR}/marley.cc" "${SOURCE_DIR}/marley_root.cc"
  "${SOURCE_DIR}/RootJSONConfig.cc")

find_program(ROOTCINT rootcint rootcling PATHS ENV PATH)
find_program(ROOTCONFIG root-config PATHS ENV PATH)
find_program(ROOT root PATHS ENV PATH)

if(ROOT AND ROOTCINT AND ROOTCONFIG)
  exec_program(${ROOTCONFIG} ARGS --version OUTPUT_VARIABLE ROOT_VERSION)
  message("Found ROOT version ${ROOT_VERSION} in ${ROOT}")
  message("MARLEY will be built with ROOT support.")
  exec_program(${ROOTCONFIG} ARGS --cflags OUTPUT_VARIABLE ROOT_CFLAGS)
  exec_program(${ROOTCONFIG} ARGS --ldflags OUTPUT_VARIABLE ROOT_LDFLAGS)
  exec_program(${ROOTCONFIG} ARGS --libdir OUTPUT_VARIABLE ROOT_LIBDIR)
  set(ROOT_LDFLAGS "${ROOT_LDFLAGS} -L${ROOT_LIBDIR} -lCore -lRIO \
    -lHist -lTree")
  if (UNIX AND NOT APPLE)
    set(ROOT_LDFLAGS "${ROOT_LDFLAGS} -rdynamic")
  endif()

  set(ROOT_DICT_INCLUDES -I${INCLUDE_DIR} marley/Particle.hh
    marley/Event.hh marley/marley_linkdef.hh)

  # Create a ROOT dictionary target for our analysis classes based on their
  # latest header files
  add_custom_command(OUTPUT marley_root_dict.cc marley_root_dict.h
    COMMAND rm -f marley_root_dict.*
    COMMAND echo "Building MARLEY ROOT dictionaries..."
    COMMAND ${ROOTCINT} -f marley_root_dict.cc -c ${ROOT_DICT_INCLUDES})
  add_custom_target(root_dictionaries DEPENDS
    ${CMAKE_CURRENT_BINARY_DIR}/marley_root_dict.cc)

  # Tell the MARLEY sources to use optional ROOT-dependent features
  add_definitions(-DUSE_ROOT)
else()
  message("The marley ups product cannot be built without ROOT.")
  message(FATAL_ERROR "Could not find a valid ROOT installation.")
endif()

# Build a shared library containing the core MARLEY class definitions
add_library(MARLEY SHARED ${SOURCES})

add_executable(${EXECUTABLE_NAME} "src/marley.cc")

# Create a shared library to allow the ROOT dictionary to be easily loaded on
# demand
add_library(MARLEY_ROOT SHARED
  ${CMAKE_CURRENT_BINARY_DIR}/marley_root_dict.cc
  ${SOURCE_DIR}/marley_root.cc ${SOURCE_DIR}/RootConfigurationFile.cc
  ${SOURCE_DIR}/RootJSONConfig.cc)
target_link_libraries(MARLEY_ROOT MARLEY)
set_target_properties(MARLEY_ROOT PROPERTIES LINK_FLAGS ${ROOT_LDFLAGS})

# Create the example executable using ROOT.
target_link_libraries(${EXECUTABLE_NAME} MARLEY_ROOT)
set_target_properties(${EXECUTABLE_NAME} PROPERTIES
  LINK_FLAGS ${ROOT_LDFLAGS})

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ROOT_CFLAGS} \
  -Wall -Wextra -pedantic -Wno-error=unused-parameter -Wcast-align")

# Add extra compiler flags for recognized compilers (currently just gcc
# and clang)
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
  message("Compling using version ${CMAKE_CXX_COMPILER_VERSION} of clang")
  # The ROOT headers trigger clang's no-keyword-macro warning, so
  # disable it. Also disable (for now) warnings for braces around
  # initialization of subobjects (overkill in the meta_numerics header)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-keyword-macro \
    -Wno-missing-braces")
elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  message("Compling using version ${CMAKE_CXX_COMPILER_VERSION} of GCC")
  if (CMAKE_CXX_COMPILER_VERSION VERSION_EQUAL 4.9)
    # g++ 4.9 gives many false positives for -Wshadow, so disable it
    # for now.
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-shadow")
  endif()
  # Linking to ROOT libraries can be problematic on distributions (e.g., Ubuntu)
  # that set the g++ flag -Wl,--as-needed by default (see
  # http://www.bnikolic.co.uk/blog/gnu-ld-as-needed.html for details), so
  # disable this behavior on Linux
  if (UNIX AND NOT APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wl,--no-as-needed")
  endif()
else()
  message("Compling using version ${CMAKE_CXX_COMPILER_VERSION} of \
    ${CMAKE_CXX_COMPILER_ID}")
endif()

#install(TARGETS marley MARLEY
#  RUNTIME DESTINATION bin
#  LIBRARY DESTINATION lib
#  ARCHIVE DESTINATION lib)
#
#install(DIRECTORY include/marley DESTINATION include/marley
#  FILES_MATCHING PATTERN "*.hh")
#
#install(DIRECTORY react/ DESTINATION share/marley/react
#  FILES_MATCHING PATTERN "*.react")
#
#install(DIRECTORY examples DESTINATION share/marley/examples)
