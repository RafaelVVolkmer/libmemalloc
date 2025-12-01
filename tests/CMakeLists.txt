cmake_minimum_required(VERSION 3.18)

# ------------------------------------------------------------------------------
# 1. Honor BUILD_TESTING early
# ------------------------------------------------------------------------------
if(NOT BUILD_TESTING)
  return()
endif()

# -------------------------------------------------------------------------
# 2. Collect all test sources (*.c) in tests/
# -------------------------------------------------------------------------
file(GLOB TEST_SRCS "${CMAKE_SOURCE_DIR}/tests/*.c")

# -------------------------------------------------------------------------
# 3. For each create an executable in bin/tests, link it and register CTest
# -------------------------------------------------------------------------
foreach(test_src IN LISTS TEST_SRCS)
    get_filename_component(test_name ${test_src} NAME_WE)

    add_executable(${test_name} ${test_src})
    set_target_properties(${test_name} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/tests"
    )
    target_include_directories(${test_name}
        PRIVATE "${CMAKE_SOURCE_DIR}/inc"
    )
    target_link_libraries(${test_name}
        PRIVATE libmemalloc_static
    )
        
    target_compile_definitions(${test_name}
        PRIVATE LOG_LEVEL=LOG_LEVEL_DEBUG
    )

    set(valgrind_log "${CMAKE_BINARY_DIR}/bin/tests/${test_name}.valgrind.log")

    if (VALGRIND_EXECUTABLE)
        add_test(NAME ${test_name}
            COMMAND ${VALGRIND_EXECUTABLE}
                    --leak-check=full
                    --show-leak-kinds=all
                    --track-origins=yes
                    --error-exitcode=1
                    --exit-on-first-error=no
                    --log-file=${valgrind_log}
                    $<TARGET_FILE:${test_name}>
        )
    else()
        add_test(NAME ${test_name}
            COMMAND env TZ=UTC $<TARGET_FILE:${test_name}>
        )
    endif()

    set_tests_properties(${test_name} PROPERTIES
        ENVIRONMENT "TZ=UTC"
        TIMEOUT 60
    )
endforeach()
