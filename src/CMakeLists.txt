set(HEADERS matio_private.h mat4.h mat5.h matio.h matioConfig.h)
#matio_io.c
set(SRC_FILES mat.c mat4.c mat5.c io.c endian.c matvar_cell.c matvar_struct.c read_data.c snprintf.c)
IF (ZLIB_LIBRARIES)
    set(SRC_FILES ${SRC_FILES} inflate.c)
endif()

IF (WIN32)
    set(SRC_FILES ${SRC_FILES} matio.rc)
endif()

set(FORTRAN_INTERFACE_FILE)
IF (ENABLE_FORTRAN)
    include(FortranCInterface)
    FortranCInterface_HEADER(fortran.h MACRO_NAMESPACE "FC_")
    set(FORTRAN_INTERFACE_FILE ${CMAKE_CURRENT_BINARY_DIR}/fortran.h)
    add_subdirectory(fortran)
endif()

IF (MAT73)
    set(SRC_FILES ${SRC_FILES} mat73.c)
endif()

#   Does not work currently with C only projects for windows.
#   Go back to old method and write the header by hand...
#include(GenerateExportHeader)
#add_compiler_export_flags()
#generate_export_header(matio)
add_library(matio ${LIB_TYPE} ${SRC_FILES} ${HEADERS})

IF (ZLIB_LIBRARIES)
    target_link_libraries(matio ${ZLIB_LIBRARIES})
endif()

IF (MAT73)
    target_link_libraries(matio ${HDF5_LIB})
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/matioConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/matioConfig.h"
    IMMEDIATE @ONLY)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/matio_pubconf.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/matio_pubconf.h"
    IMMEDIATE @ONLY)

# ================
# = INSTALLATION =
# ================

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/matio_pubconf.h ${CMAKE_CURRENT_SOURCE_DIR}/matio.h 
              ${CMAKE_CURRENT_SOURCE_DIR}/matio_export.h ${FORTRAN_INTERFACE_FILE}
        DESTINATION include)

install(TARGETS matio
        RUNTIME DESTINATION ${INSTALL_BIN_DIR}
        LIBRARY DESTINATION ${INSTALL_LIB_DIR}
        ARCHIVE DESTINATION ${INSTALL_LIB_DIR})
