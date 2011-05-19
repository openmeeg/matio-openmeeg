IF(NOT WIN32)
    SET(MATIO_EXTERNAL_LIBRARIES m) 
ENDIF()

ADD_EXECUTABLE(test_mat test_mat.c)
TARGET_LINK_LIBRARIES(test_mat matio ${MATIO_EXTERNAL_LIBRARIES})

ADD_EXECUTABLE(test_snprintf test_snprintf.c ${MATIO_SOURCE_DIR}/src/snprintf.c)
TARGET_LINK_LIBRARIES(test_snprintf ${MATIO_EXTERNAL_LIBRARIES})

MACRO(MATIO_TEST NAME FILENAME OUTPUT PROG_NAME)
    SET(PROG_ARGS "${ARGN}")
    SEPARATE_ARGUMENTS(ARGS UNIX_COMMAND "${PROG_ARGS}")
    IF (WIN32)
        SET (TEST_DIR ${EXECUTABLE_OUTPUT_PATH})
    ELSE ()
        SET (TEST_DIR ${CMAKE_CURRENT_BINARY_DIR})
    ENDIF ()

    SET (EXECUTABLE ${TEST_DIR}/${PROG_NAME}${CMAKE_EXECUTABLE_SUFFIX})
    ADD_TEST(${NAME} ${EXECUTABLE} ${PROG_ARGS} -o ${FILENAME}) # To perform memcheck tests
    ADD_TEST(${NAME}-COMPARISON
             ${CMAKE_COMMAND} -D TEST_DIR:STRING=${TEST_DIR}
                              -D TEST_NAME:STRING=${NAME}
                              -D TEST_REFERENCE_DIR:STRING=${CMAKE_SOURCE_DIR}/test/results
                              -D TEST_PROGRAM:STRING=${EXECUTABLE}
                              -D TEST_ARGS:STRING=${ARGS}
                              -D TEST_RESULT:STRING=${FILENAME}
                              -D OUTPUT:STRING=${OUTPUT}
                              -P ${MATIO_SOURCE_DIR}/test/runTest.cmake) # To compare output to reference file
    #SET_TESTS_PROPERTIES(${NAME} PROPERTIES DEPENDS ${EXECUTABLE})
    SET_TESTS_PROPERTIES(${NAME}-COMPARISON PROPERTIES
                         DEPENDS ${NAME}
                         PASS_REGULAR_EXPRESSION "Success")
ENDMACRO()

#MATIO_TEST(TEST_SNPRINTF test_snprintf)

SET(MATIO_WRITE_TESTS_NUMERIC 
     write_2d_numeric write_complex_2d_numeric write_empty_2d_numeric write_char write_struct_2d_numeric
     write_struct_complex_2d_numeric write_cell_2d_numeric write_cell_complex_2d_numeric write_char)

SET(MATIO_WRITE_TESTS_SPARSE write_sparse write_complex_sparse)

SET(MATIO_WRITE_TESTS ${MATIO_WRITE_TESTS_NUMERIC} ${MATIO_WRITE_TESTS_SPARSE}
    write_char write_empty_struct 
    write_empty_cell
    writeinf writenan writeslab)

SET(MATIO_FILES)
FOREACH(arg ${MATIO_WRITE_TESTS_NUMERIC} ${MATIO_WRITE_TESTS_SPARSE} write_empty_cell write_empty_struct writeinf writenan writeslab)
    SET(VERSIONS 4 5)
    IF (NOT ${arg} STREQUAL "writeslab")
        IF (MAT73)
            SET(VERSIONS ${VERSIONS} 7.3)
        ENDIF()
    ENDIF()
    FOREACH(class double single int64 uint64 int32 uint32 int16 uint16 int8 uint8)
        FOREACH (version ${VERSIONS})
            SET(testname ${arg}-${class}-${version})
            SET(filename test_${testname}.mat)
            SET(MATIO_FILES ${MATIO_FILES} ${filename})
            MATIO_TEST(MATIO-${testname} ${filename} Null.out test_mat -c ${class} -v ${version} ${arg} -o ${filename})
            IF (${version} STREQUAL "5")
                SET(filename test_${testname}-compressed.mat)
                MATIO_TEST(MATIO-${testname}-compressed ${filename} Null.out test_mat -c ${class} -v ${version} -z ${arg} -o ${filename})
            ENDIF() 
        ENDFOREACH()
    ENDFOREACH()
ENDFOREACH()

SET(MATIO_IND_TESTS ind2sub sub2ind)
FOREACH(arg ${MATIO_IND_TESTS})
    MATIO_TEST(MATIO-${arg} NONE MATIO-${arg}.out test_mat ${arg})
ENDFOREACH()

FOREACH(file ${MATIO_FILES})
    MATIO_TEST(MATIO-copy-${file} copy_${file} Copy.out test_mat copy ${file} -o copy_${file})
ENDFOREACH()

SET(DATASETS d f i64 ui64 i32 i16 i8 str)
SET(MATIO_OTHER_FILES writeinf writenan write_null)
FOREACH(file ${MATIO_FILES})
#    MATIO_TEST(MATIO-copy-${file} test_mat copy test_${file}.mat)
#MATIO_TEST(MATIO-delete-${file} test_mat delete test_mat_copy.mat) Need to specify a variable name...
ENDFOREACH()

#   Record the output and compare it with stored values ??

SET(MATIO_WRITE_VARS d f i64 ui64 i32 i16 i8 str)
FOREACH(file write write_compressed)
    FOREACH(var ${MATIO_WRITE_VARS})
#        MATIO_TEST(MATIO-readvarinfo-${file}-${var} test_mat readvarinfo test_${file}.mat a)
#        MATIO_TEST(MATIO-readvar-${file}-${var} test_mat readvar test_${file}.mat ${var})
    ENDFOREACH()
ENDFOREACH()

FOREACH(file writecell write_compressed_cell)
#    MATIO_TEST(MATIO-readvarinfo-${file} test_mat readvarinfo test_mat_${file}.mat cell)
#    MATIO_TEST(MATIO-readvar-${file} test_mat readvar test_mat_${file}.mat cell)
ENDFOREACH()

SET(MATIO_WRITESLAB_VARS d f i)
FOREACH(var ${MATIO_WRITESLAB_VARS})
#    MATIO_TEST(MATIO-readslab-${var} test_mat readslab test_mat_writeslab.mat ${var})
ENDFOREACH()

FOREACH(file write_struct write_compressed_struct)
    FOREACH(field 1 2 3 4 data)
#        MATIO_TEST(MATIO-getstructfield-${file}-${field} test_mat getstructfield test_mat_${file}.mat structure ${var})
    ENDFOREACH()
ENDFOREACH()

# Add more tests for these.

SET(MATIO_READ_TESTS readvar4 readslab4 slab3)

# Set tests that are expected to fail (TO BE CORRECTED).

#SET_TESTS_PROPERTIES(MATIO-writenull PROPERTIES WILL_FAIL TRUE)
#SET_TESTS_PROPERTIES(MATIO-writenull-COMPARISON PROPERTIES WILL_FAIL TRUE)
#SET_TESTS_PROPERTIES(MATIO-copy-write_null PROPERTIES WILL_FAIL TRUE)

#SET_TESTS_PROPERTIES(MATIO-readvarinfo-write_compressed_cell PROPERTIES WILL_FAIL TRUE)
#SET_TESTS_PROPERTIES(MATIO-readvar-write_compressed_cell PROPERTIES WILL_FAIL TRUE)

IF (ENABLE_FORTRAN)
    INCLUDE_DIRECTORIES(${MATIO_SOURCE_DIR}/src/fortran ${MATIO_BINARY_DIR}/src/fortran)
    ADD_EXECUTABLE(test_matf test_matf.f90)
    TARGET_LINK_LIBRARIES(test_matf matio m)
    # TESTS
ENDIF()
