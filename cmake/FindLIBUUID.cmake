# - Find libuuid
# Find the libuuid library
#
# This module defines the following variables:
#   LIBUUID_FOUND  -  True if library and include directory are found
# If set to TRUE, the following are also defined:
#   LIBUUID_INCLUDE_DIRS  -  The directory where to find the header file
#   LIBUUID_LIBRARIES  -  Where to find the library file
#
# For conveniance, these variables are also set. They have the same values
# than the variables above.  The user can thus choose his/her prefered way
# to write them.
#   LIBUUID_INCLUDE_DIR
#   LIBUUID_LIBRARY
#
# This file is in the public domain

include(FindPkgConfig)
pkg_check_modules(LIBUUID uuid)

if(NOT LIBUUID_FOUND)
  find_path(LIBUUID_INCLUDE_DIRS NAMES uuid/uuid.h
    PATH_SUFFIXES uuid
    DOC "The libuuid include directory")

  find_library(LIBUUID_LIBRARIES NAMES uuid
    DOC "The libuuid library")

  # Use some standard module to handle the QUIETLY and REQUIRED arguments, and
  # set LIBUUID_FOUND to TRUE if these two variables are set.
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LIBUUID REQUIRED_VARS LIBUUID_LIBRARIES LIBUUID_INCLUDE_DIRS)

  # Compatibility for all the ways of writing these variables
  if(LIBUUID_FOUND)
    set(LIBUUID_INCLUDE_DIR ${LIBUUID_INCLUDE_DIRS})
    set(LIBUUID_LIBRARY ${LIBUUID_LIBRARIES})
    set(LIBUUID_CFLAGS -I${LIBUUID_INCLUDE_DIRS})
  endif()
endif()

mark_as_advanced(LIBUUID_INCLUDE_DIRS LIBUUID_LIBRARIES LIBUUID_CFLAGS)
