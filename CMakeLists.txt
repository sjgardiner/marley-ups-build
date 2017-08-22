# ======================================================================
#  Build file for the MARLEY ups product
#
#  cd .../path/to/build/directory
#  source .../path/to/marley/ups/setup_for_development <-d|-o|-p>
#  buildtool -I "/path/to/install/location" -bti [-jN]
# ======================================================================

# use cmake 2.8 or later
cmake_minimum_required (VERSION 2.8)

project(marley-ups)

# cetbuildtools contains our cmake modules
set( CETBUILDTOOLS_VERSION $ENV{CETBUILDTOOLS_VERSION} )
if( NOT CETBUILDTOOLS_VERSION )
  message( FATAL_ERROR "ERROR: setup cetbuildtools to get the cmake modules" )
endif()
set(CMAKE_MODULE_PATH $ENV{CETBUILDTOOLS_DIR}/Modules ${CMAKE_MODULE_PATH})

include(CetCMakeEnv)
cet_cmake_env()

# these are minimum required versions, not the actual product versions
find_ups_product( cetbuildtools v2_03_00 )
find_ups_root( v5_30_02 )

cet_check_gcc()

# ups - table and config files
add_subdirectory(ups)

# packaging utility - enable building a package tarball
include(UseCPack)

include(ExternalProject)

# Retrieve the appropriate version of MARLEY from the public git
# repository, then use GNU make to build it
ExternalProject_Add(marley
  PREFIX marley
  STAMP_DIR ./stamp
  TMP_DIR  ./tmp
  GIT_REPOSITORY git@bitbucket.org:sjgardiner/marley.git 
  GIT_TAG v1.0.0
  SOURCE_DIR ./marley
  BINARY_DIR ./marley/build
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND ""
  BUILD_COMMAND make VERBOSE=1
  INSTALL_COMMAND ""
  TEST_COMMAND ""
  LOG_DOWNLOAD 1
  LOG_BUILD 1
  LOG_INSTALL 1
)

ExternalProject_Get_Property(marley binary_dir)
ExternalProject_Get_Property(marley source_dir)

# Use CMake to install the files since it is aware of the ups product
# layout defined by cetbuildtools
install(PROGRAMS ${binary_dir}/marley DESTINATION ${${product}_bin_dir})
install(DIRECTORY ${binary_dir}/ DESTINATION ${${product}_lib_dir}
  PATTERN "Makefile" EXCLUDE PATTERN "marley" EXCLUDE)
install(DIRECTORY ${source_dir}/react ${source_dir}/structure
  ${source_dir}/examples DESTINATION ${product}/${version})
install(DIRECTORY ${source_dir}/include/marley
  DESTINATION ${${product}_inc_dir})
install(FILES ${source_dir}/README.md ${source_dir}/LICENSE
  DESTINATION ${product}/${version})