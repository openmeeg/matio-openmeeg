if (NOT WIN32)
    set(MATDUMP_EXTERNAL_LIBRARIES m) 
endif()

add_executable(matdump matdump.c)
target_link_libraries(matdump matio ${MADUMP_EXTERNAL_LIBRARIES} ${GETOPT_LIB})
