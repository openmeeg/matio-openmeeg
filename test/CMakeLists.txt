IF(NOT WIN32)
    SET(MATIO_EXTERNAL_LIBRARIES m) 
ENDIF()

ADD_EXECUTABLE(test_mat test_mat.c)
TARGET_LINK_LIBRARIES(test_mat matio ${MATIO_EXTERNAL_LIBRARIES} ${GETOPT_LIB})

ADD_EXECUTABLE(test_snprintf test_snprintf.c ${MATIO_SOURCE_DIR}/src/snprintf.c)
TARGET_LINK_LIBRARIES(test_snprintf ${MATIO_EXTERNAL_LIBRARIES} ${GETOPT_LIB})

FIND_PROGRAM(MATLAB matlab)

MACRO(PARSE_TEST_ARGUMENTS LIST_VARS DEFAULT_VAR)
    foreach(var ${LIST_VARS})
        unset(${var})
    endforeach ()

    set(CURRENT_VAR ${DEFAULT_VAR})
    foreach (arg ${ARGN})
        set(skip_this_arg FALSE)
        foreach(var ${LIST_VARS})
            if (${arg} STREQUAL ${var})
                set(CURRENT_VAR ${var})
                set(skip_this_arg TRUE)
                BREAK()
            endif()
        endforeach ()
        if (NOT skip_this_arg)
            set(${CURRENT_VAR} ${${CURRENT_VAR}} ${arg})
        endif()
    endforeach ()
ENDMACRO()

MACRO(SET_TEST_DIR TEST_DIR)
    IF (WIN32)
        IF (NOT CMAKE_BUILD_TYPE)
            SET(CMAKE_BUILD_TYPE Debug)
        ENDIF()
        SET(${TEST_DIR} ${EXECUTABLE_OUTPUT_PATH}/${CMAKE_BUILD_TYPE})
    ELSE()
        SET(${TEST_DIR} ${CMAKE_CURRENT_BINARY_DIR})
    ENDIF()
ENDMACRO()

MACRO(MATIO_TEST_READ NAME FILENAME PROG_NAME)
    PARSE_TEST_ARGUMENTS("COMMAND;DEPENDS" "DEFAULT" ${ARGN})
    SET(PROG_ARGS "${ARGN}")
    SEPARATE_ARGUMENTS(ARGS UNIX_COMMAND "${PROG_ARGS}")
    SET_TEST_DIR(TEST_DIR)
    SET (EXECUTABLE ${TEST_DIR}/${PROG_NAME}${CMAKE_EXECUTABLE_SUFFIX})
    ADD_TEST(${NAME} ${EXECUTABLE} ${PROG_ARGS} -o ${CMAKE_CURRENT_BINARY_DIR}/${FILENAME}) # To perform memcheck tests
    SET_TESTS_PROPERTIES(${NAME} PROPERTIES DEPENDS "${DEPENDS}")
    ADD_TEST(${NAME}-COMPARISON
             ${CMAKE_COMMAND} -D TEST_DIR:STRING=${TEST_DIR}
                              -D TEST_NAME:STRING=${NAME}
                              -D TEST_REFERENCE_DIR:STRING=${MATIO_SOURCE_DIR}/test/datasets/results
                              -D TEST_RESULT:STRING=${FILENAME}
                              -P ${MATIO_SOURCE_DIR}/test/runTest.cmake) # To compare output to reference file
    #SET_TESTS_PROPERTIES(${NAME} PROPERTIES DEPENDS ${EXECUTABLE})
    SET_TESTS_PROPERTIES(${NAME}-COMPARISON PROPERTIES
                         DEPENDS ${NAME}
                         PASS_REGULAR_EXPRESSION "Success")
ENDMACRO()

MACRO(MATIO_TEST_WRITE NAME FILENAME PROG_NAME)
    PARSE_TEST_ARGUMENTS("COMMAND;DEPENDS" "DEFAULT" ${ARGN})
    SET(PROG_ARGS "${ARGN}")
    SEPARATE_ARGUMENTS(ARGS UNIX_COMMAND "${PROG_ARGS}")
    SET_TEST_DIR(TEST_DIR)
    SET (EXECUTABLE ${TEST_DIR}/${PROG_NAME}${CMAKE_EXECUTABLE_SUFFIX})
    ADD_TEST(${NAME} ${EXECUTABLE} ${PROG_ARGS} -o ${CMAKE_CURRENT_BINARY_DIR}/${FILENAME}) # To perform memcheck tests
ENDMACRO()

MACRO(MATIO_TEST_MATLAB_READ NAME FILE TEST_TYPE CLASS)
    IF (MATLAB)
        PARSE_TEST_ARGUMENTS("DEPENDS" "DEFAULT" ${ARGN})
        SET_TEST_DIR(TEST_DIR)
        STRING(REPLACE "-" "_" MSBNAME ${FILE})
        STRING(REPLACE ".mat" "" MSBNAME ${MSBNAME})
        SET(FILENAME ${TEST_DIR}/${FILE})
        SET(TYPE ${CLASS})
        CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/matlab_${TEST_TYPE}.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/matlab/${MSBNAME}.m @ONLY)
        ADD_TEST(NAME ${NAME} WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/matlab COMMAND ${MATLAB} -nosplash -nojvm -r "${MSBNAME};exit")
        SET_TESTS_PROPERTIES(${NAME} PROPERTIES
                             DEPENDS ${DEPENDS}
                             PASS_REGULAR_EXPRESSION "PASSED")
    ENDIF()
ENDMACRO()

#MATIO_TEST(TEST_SNPRINTF test_snprintf)

SET(MATIO_READ_TESTS readvar)

SET(v4_vars var1 var11 var24)
SET(vars)
FOREACH(i RANGE 1 69)
    SET(vars ${vars} ${i})
ENDFOREACH()
SET(compressed_vars ${vars})
SET(uncompressed_vars ${vars})
SET(hdf_vars ${vars})

FOREACH(arg ${MATIO_READ_TESTS})
    FOREACH(vers v4 compressed uncompressed hdf)
        FOREACH(endian le be)
            FOREACH(var ${${vers}_vars})
                SET(testname ${arg}-${vers}-${endian}-${var})
                SET(input ${CMAKE_CURRENT_SOURCE_DIR}/datasets/matio_test_cases_${vers}_${endian}.mat)
                SET(output MATIO-${testname}.out)
                MATIO_TEST_READ(MATIO-${testname} ${output} test_mat ${arg} ${input} ${var})
            ENDFOREACH()
        ENDFOREACH()
    ENDFOREACH()
ENDFOREACH()
    
SET(MATIO_WRITE_TESTS_NUMERIC 
     write_2d_numeric write_complex_2d_numeric write_empty_2d_numeric write_char write_struct_2d_numeric
     write_struct_complex_2d_numeric write_cell_2d_numeric write_cell_complex_2d_numeric write_char)

SET(MATIO_WRITE_TESTS_NUMERIC 
     write_2d_numeric write_complex_2d_numeric write_struct_2d_numeric
     write_struct_complex_2d_numeric write_cell_2d_numeric write_cell_complex_2d_numeric)

#write_empty_2d_numeric write_char writeslab
SET(MATIO_WRITE_TESTS_SPARSE write_sparse write_complex_sparse)

SET(MATIO_WRITE_TESTS ${MATIO_WRITE_TESTS_NUMERIC} ${MATIO_WRITE_TESTS_SPARSE}
    write_char write_empty_struct 
    write_empty_cell
    writeinf writenull writenan writeslab)

SET(MATIO_FILES)
FOREACH(type ${MATIO_WRITE_TESTS_NUMERIC})
    SET(VERSIONS 5)
    IF (MAT73)
        SET(VERSIONS ${VERSIONS} 7.3)
    ENDIF()
    FOREACH(class double single int64 uint64 int32 uint32 int16 uint16 int8 uint8)
        FOREACH (version ${VERSIONS})
            SET(testname ${type}-${class}-${version})
            SET(filename test_${testname}.mat)
            SET(MATIO_FILES ${MATIO_FILES} ${filename})
            MATIO_TEST_WRITE(MATIO-${testname} ${filename} test_mat -c ${class} -v ${version} ${type})
            SET(output ${testname}.out)
            MATIO_TEST_READ(MATIO-readvar-${testname} ${output} test_mat readvar ${filename} a)
            SET_TESTS_PROPERTIES(MATIO-readvar-${testname} PROPERTIES DEPENDS MATIO-${testname})
            IF (${version} STREQUAL "5")
                SET(testname ${testname}-compressed)
                SET(filename test_${testname}.mat)
                SET(output ${testname}.out)
                MATIO_TEST_WRITE(MATIO-${testname} ${filename} test_mat -c ${class} -v ${version} -z ${type} -o ${filename})
                MATIO_TEST_READ(MATIO-readvar-${testname} ${output} test_mat readvar ${filename} a DEPENDS MATIO-${testname})
                MATIO_TEST_MATLAB_READ(MATIO-matlab-${testname} ${filename} ${type} ${class} DEPENDS MATIO-${testname})
            ENDIF() 
        ENDFOREACH()
    ENDFOREACH()
ENDFOREACH()

SET(MATIO_OTHER_FILES writeinf writenan writenull writeslab)
FOREACH(arg ${MATIO_OTHER_FILES})
    SET(testname ${arg})
    SET(filename test_${testname}.mat)
    IF (${arg} STREQUAL "writenull")
        SET(filename test_write_null.mat)
    ENDIF()
    SET(MATIO_FILES ${MATIO_FILES} ${filename})
#    MATIO_TEST(MATIO-${testname} ${filename} Null.out test_mat ${arg})
ENDFOREACH()

SET(MATIO_IND_TESTS ind2sub sub2ind)
FOREACH(arg ${MATIO_IND_TESTS})
    SET(TEST_REFERENCE MATIO-${arg}.out)
    IF (WIN32)
        SET(TEST_REFERENCE MATIO-${arg}-win.out)
    ENDIF()
    MATIO_TEST_READ(MATIO-${arg} ${TEST_REFERENCE} test_mat ${arg})
ENDFOREACH()

#SET(DATASETS d f i64 ui64 i32 i16 i8 str)
#FOREACH(file ${MATIO_FILES})
#    MATIO_TEST(MATIO-copy-${file} copy_${file} Copy.out test_mat copy ${file} -o copy_${file})
#    FOREACH (var ${DATASETS})
#        ADD_TEST(MATIO-delete-${file} test_mat delete ${file} ${var})
#    ENDFOREACH()
#ENDFOREACH()

#SET(MATIO_WRITESLAB_VARS d f i)
#FOREACH(var ${MATIO_WRITESLAB_VARS})
#    MATIO_TEST(MATIO-readslab-${var} "" test_readslab_${var}.out test_mat readslab test_mat_writeslab.mat ${var})
#ENDFOREACH()

#FOREACH(arg write_struct_2d_numeric write_struct_complex_2d_numeric)
#    SET(VERSIONS 4 5)
#    IF (MAT73)
#        SET(VERSIONS ${VERSIONS} 7.3)
#    ENDIF()
#    FOREACH(field 1 2)
#        FOREACH(class double single int64 uint64 int32 uint32 int16 uint16 int8 uint8)
#            FOREACH (version ${VERSIONS})
#                SET(testname ${arg}-${class}-${version})
#                SET(filename test_${testname}.mat)
#                SET(testname getstructfield-${testname})
#                MATIO_TEST(MATIO-${testname} "" ${testname}.out test_mat getstructfield ${filename} a field${field})
#                IF (${version} STREQUAL "5")
#                    SET(testname ${arg}-${class}-${version}-compressed)
#                    SET(filename test_${testname}.mat)
#                    SET(testname getstructfield-${testname})
#                    MATIO_TEST(MATIO-${testname} "" ${testname}.out test_mat getstructfield ${filename} a field${field})
#                ENDIF() 
#            ENDFOREACH()
#        ENDFOREACH()
#    ENDFOREACH()
#ENDFOREACH()

# Add more tests for these.

SET(MATIO_READ_TESTS readvar4 readslab4 slab3)

# Set tests that are expected to fail (TO BE CORRECTED).

IF (ENABLE_FORTRAN)
    INCLUDE_DIRECTORIES(${MATIO_SOURCE_DIR}/src/fortran ${MATIO_BINARY_DIR}/src/fortran)
    ADD_EXECUTABLE(test_matf test_matf.f90)
    TARGET_LINK_LIBRARIES(test_matf fmatio matio m)
    # TESTS
ENDIF()
