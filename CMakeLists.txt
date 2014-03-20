set(PACKAGE_VERSION_MAJOR "1")
set(PACKAGE_VERSION_MINOR "5")
set(PACKAGE_VERSION_PATCH "0")

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake;${CMAKE_MODULE_PATH}")

# ===========
# = Options =
# ===========

option(ENABLE_FORTRAN "Enable fortran interface to mat library")
set(EXTRA_LANGAGE)
if (ENABLE_FORTRAN)
    set(EXTRA_LANGAGE Fortran)
    set(MATIO_FORTRAN TRUE)
endif()

project(MATIO C ${EXTRA_LANGAGE})

set(MATIO_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(MATIO_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})

cmake_minimum_required(VERSION 2.8)

# It may seem that ${CMAKE_ARCH_TRIPLET} might appear in a future cmake release.
# For now, do for the best.
set(MATIO_PLATFORM ${CMAKE_SYSTEM_PROCESSOR}-unknown-${CMAKE_SYSTEM_NAME})

include(FindLibrary)

# =======================
# = HANDLE DEFINITTIONS =
# =======================

# ===========
# = Options =
# ===========

include(DefaultFileVersion)

option(ENABLE_PROFILE "Turn on profile")
if (ENABLE_PROFILE)
endif()

option(EXTENDED_SP "Enable extended sparse matrix data types not supported in Matlab" ON)
if (EXTENDED_SP)
    set(EXTENDED_SPARSE 1)
endif()

include (Documentation optionAL)
if (BUILD_DOCUMENTATION)
    add_subdirectory(documentation)
endif()

# =================
# = Check headers =
# =================

#   For public header

# Provide stdint.h for windows, if it is not already there.
# MSVC starts to include stddint.h only from MSVC10 !!!
# Append after in order to use the system includes if they are provided.

if (WIN32 AND NOT CYGWIN_INSTALL_PATH)
    set(INTTYPES_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/contrib/msinttypes-r26)
    set(CMAKE_REQUIRED_INCLUDES ${INTTYPES_INCLUDES})
    include_directories(AFTER SYSTEM ${INTTYPES_INCLUDES})
endif()

include(CheckIncludeFile)
include(CheckHeaderSTDC)

check_include_file(inttypes.h HAVE_INTTYPES_H)
check_include_file(stdint.h   HAVE_STDINT_H)
check_include_file(strings.h  HAVE_STRINGS_H)
check_include_file(ctype.h    HAVE_CTYPE_H)
check_include_file(stdlib.h   HAVE_STDLIB_H)
check_include_file(string.h   HAVE_STRING_H)
#CHECK_INCLUDE_FILE(malloc.h   HAVE_MALLOC_H)
check_header_stdc()

# ===================
# = Check type size =
# ===================

include(CheckTypeSize)
set(TYPES double float long int short char size_t)
foreach(TYPE ${TYPES})
    string(TOUPPER ${TYPE} TYPE_UPPER)
    check_type_size(${TYPE} SIZEOF_${TYPE_UPPER})
endforeach()
check_type_size("long long" LONG_LONG)
set(HAVE_LONG_LONG ${HAVE_${LONG_LONG}})
set(SIZEOF_LONG_LONG ${LONG_LONG})
check_type_size("long double" LONG_DOUBLE)
set(HAVE_LONG_DOUBLE ${HAVE_${LONG_DOUBLE}})
check_type_size(void* SIZEOF_VOID_P)

set(TYPES uint8_t uint16_t uint32_t uint64_t int8_t int16_t int32_t int64_t)
foreach(TYPE ${TYPES})
    string(TOUPPER ${TYPE} TYPE_UPPER)
    check_type_size(${TYPE} ${TYPE_UPPER})
    set(HAVE_MAT_${TYPE_UPPER} ${HAVE_${TYPE_UPPER}})
    set(SIZEOF_${TYPE_UPPER} ${${TYPE_UPPER}})
    if (NOT ${${TYPE_UPPER}})
        message(FATAL_ERROR "Unknown type ${TYPE}")
    endif()
endforeach()

# ===================
# = Check functions =
# ===================

include(CheckFunctionExists)
check_function_exists(vsnprintf  HAVE_VSNPRINTF)
check_function_exists(snprintf   HAVE_SNPRINTF)
check_function_exists(vasprintf  HAVE_VASPRINTF)
check_function_exists(asprintf   HAVE_ASPRINTF)
check_function_exists(strcasecmp HAVE_STRCASECMP)
check_function_exists(getopt     HAVE_GETOPT)

include(VA_COPY)
VA_COPY()

if (WIN32)
    if (NOT LIBRARY_OUTPUT_PATH)
        set(LIBRARY_OUTPUT_PATH    "${CMAKE_CURRENT_BINARY_DIR}")
    endif()
    if (NOT EXECUTABLE_OUTPUT_PATH)
        set(EXECUTABLE_OUTPUT_PATH "${CMAKE_CURRENT_BINARY_DIR}")
    endif()
endif()

if (NOT HAVE_GETOPT)
    add_subdirectory(getopt)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/getopt)
    set(GETOPT_LIB gnu)
endif()

# =========
# = Z Lib =
# =========

option(USE_SYSTEM_ZLIB "Use installed zlib if possible" ON)
mark_as_advanced(USE_SYSTEM_ZLIB)

string(COMPARE NOTEQUAL "${USE_SYSTEM_ZLIB_STATUS}" "" USE_SYSTEM_ZLIB_STATUS_NOT_EMPTY)
if (USE_SYSTEM_ZLIB_STATUS_NOT_EMPTY)
    string(COMPARE NOTEQUAL "${USE_SYSTEM_ZLIB_STATUS}" "${USE_SYSTEM_ZLIB}" RESET)
endif()

# Store in cache previous value of BUILD_SHARED_LIBS
set(USE_SYSTEM_ZLIB_STATUS "${USE_SYSTEM_ZLIB}" CACHE INTERNAL "Previous system zlib status" FORCE)

if (${RESET})
    unset(SYSTEM_ZLIB)
    unset(SYSTEM_ZLIB CACHE)
    unset(ZLIB_LIBRARIES)
    unset(ZLIB_LIBRARIES CACHE)
endif()

if (USE_SYSTEM_ZLIB)
    MATIO_FIND_LIBRARY(SYSTEM_ZLIB z)
    if (SYSTEM_ZLIB)
        set(ZLIB_LIBRARIES ${SYSTEM_ZLIB} CACHE STRING "TEST")
    else()
        set(USE_LOCAL_ZLIB 1)
    endif()
endif()

if (NOT USE_SYSTEM_ZLIB OR USE_LOCAL_ZLIB)
    find_package(ZLIB)
    if (NOT ZLIB_FOUND)
        message(FATAL_ERROR "zlib is required by matio")
    endif()
    include_directories(${ZLIB_INCLUDE_DIR})
    set(ZLIB_LIBRARIES zlib)
endif()

set(HAVE_ZLIB 1)
set(Z_PREFIX)

#   Tell Hdf5 to disable its own zlib detection (and to use this version).

set(H5_ZLIB_HEADER zlib.h)

option(MAT73 "Matlab 7.3 support" ON)

string(COMPARE NOTEQUAL "${MAT73_STATUS}" "" MAT73_STATUS_NOT_EMPTY)
if (MAT73_STATUS_NOT_EMPTY)
    string(COMPARE NOTEQUAL "${MAT73_STATUS}" "${MAT73}" RESET)
endif()

# Store in cache previous value of BUILD_SHARED_LIBS
set(MAT73_STATUS "${MAT73}" CACHE INTERNAL "Previous matlab 7.3 support status" FORCE)

if (${RESET})
    unset(HDF5_FOUND)
    unset(HDF5_FOUND CACHE)
endif()

if (MAT73)
    message("Looking for HDF5")
    find_package(HDF5)
    if (HDF5_FOUND)
        message("HDF5 FOUND!!!!")
        set(HAVE_HDF5 1)
        include(HDF5Version)
        HDF5_VERIFY_VERSION(1.8.9 HDF5_OK)
        if (HDF5_OK EQUAL 1)
            MESSAGE(WARNING "hdf5 library must be 1.8.9 or higher. Using internal copy.")
            set(HDF5_FOUND FALSE)
            set(HDF5_INCLUDE_DIRS)
            set(HDF5_LIBRARIES)
            UNSET(HAVE_HDF5)
        endif()
    else()
        MESSAGE(WARNING "hdf5 not found, mat7.3 format disabled")
        set(MAT73 OFF CACHE BOOL "Matlab 7.3 support disabled because hdf5 was not found" FORCE)
    endif()
    if (MAT73 AND HAVE_HDF5)
        include_directories(${HDF5_INCLUDE_DIRS})
        if (NOT BUILD_SHARED_LIBS)
            set(TARGET_SUFFIX -static)
        endif()
        set(HDF5_LIB ${HDF5_LIBRARIES})
    endif()
endif()

include_directories(${CMAKE_CURRENT_BINARY_DIR}/src)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
add_subdirectory(src)
add_subdirectory(tools)

# ==============
# = pkg-config =
# ==============

set(prefix ${CMAKE_INSTALL_PREFIX})
set(VERSION ${PACKAGE_VERSION_MAJOR}.${PACKAGE_VERSION_MINOR}.${PACKAGE_VERSION_PATCH})
set(exec_prefix "\${prefix}")
set(libdir "\${exec_prefix}/lib")
set(includedir "\${prefix}/include")
set(ZLIB_LIBS ${ZLIB_LIBRARIES})

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/matio.pc.in"
    "${CMAKE_CURRENT_BINARY_DIR}/matio.pc"
    IMMEDIATE @ONLY)

#INSTALL(EXPORT matio DESTINATION )

# ===========
# = Testing =
# ===========

option(MATIO_BUILD_TESTING "Build matio tests" ON)
if (MATIO_BUILD_TESTING)
    if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/test/datasets)
        include(CTest)
        enable_testing()
        add_subdirectory(test)
    endif()
endif()

# =============
# = Uninstall =
# =============

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall-${PROJECT-NAME}
    "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake")

#-----------------------------------------------
# packaging
#-----------------------------------------------

include(Packaging)
