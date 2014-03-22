include(CompareVersionStrings)
function(HDF5_VERIFY_VERSION HDF5MINVERS HDF5_COMP_RES)
    try_run(RRESULT CRESULT
            ${CMAKE_BINARY_DIR}/cmake
            ${CMAKE_CURRENT_SOURCE_DIR}/cmake/HDF5Version.c
            CMAKE_FLAGS -DINCLUDE_DIRECTORIES::STRING=${HDF5_INCLUDE_DIRS}
            RUN_OUTPUT_VARIABLE HDF5VERS)
    if (NOT ${CRESULT})
        message(FATAL "Unable to compile a simple hdf5 program. Check your installation.")
    endif()
    if (NOT ${RRESULT} EQUAL 0)
        message(FATAL "Executing a simple hdf5 program.")
    endif()
    compare_version_strings(${HDF5MINVERS} ${HDF5VERS} RVAR)
    set(${HDF5_COMP_RES} ${RVAR} PARENT_SCOPE)
endfunction()
