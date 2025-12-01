cmake_minimum_required(VERSION 3.24)

if (DOXYGEN_EXECUTABLE)

    if(POLICY CMP0135)
        cmake_policy(SET CMP0135 NEW)
    endif()

    set(REPO_URL "https://github.com/jothepro/doxygen-awesome-css/archive/refs/heads/main.zip")
    set(AWESOME_DOXYGEN_DIR "${CMAKE_SOURCE_DIR}/doxygen/doxygen-awesome")

    FetchContent_Declare(
        doxygen-awesome-css
        URL "${REPO_URL}"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        SOURCE_DIR "${AWESOME_DOXYGEN_DIR}"
    )

    FetchContent_MakeAvailable(doxygen-awesome-css)

    set(DOXYFILE_IN   "${CMAKE_SOURCE_DIR}/doxygen/Doxyfile.in")
    set(DOXYFILE_OUT  "${CMAKE_BINARY_DIR}/Doxyfile")

    configure_file(${DOXYFILE_IN} ${DOXYFILE_OUT} @ONLY)

    add_custom_target(doc
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Generating Doxygen docs with Awesome CSS"
        VERBATIM
    )

endif()