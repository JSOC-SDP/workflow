cmake_minimum_required(VERSION 3.6...3.31)
project(
    "JSOC Workflow"
    LANGUAGES C
    VERSION 2.0.0
    DESCRIPTION "JSOC Workflow utilities and scripts"
)

# Customizable installation paths
set(CMAKE_INSTALL_BINDIR "bin" CACHE STRING "Executable directory")
set(CMAKE_INSTALL_SCRIPTDIR "scripts" CACHE STRING "Script directory")

# Build our one binary
file(GLOB APP_SOURCES "apps/GetNextID.c")
add_executable(GetNextID ${APP_SOURCES})

# Install binary
install(
    TARGETS GetNextID
    RUNTIME
    DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}
)

# Define all the installable scripts in the root directory and install them
file(GLOB ROOT_SCRIPTS
    "${CMAKE_SOURCE_DIR}/*.csh"
    "${CMAKE_SOURCE_DIR}/*.pm"
    "${CMAKE_SOURCE_DIR}/*.pl"
    "${CMAKE_SOURCE_DIR}/gatekeeper.restart"
)
install(
    FILES ${ROOT_SCRIPTS}
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    PERMISSIONS
        OWNER_EXECUTE OWNER_WRITE OWNER_READ
        GROUP_EXECUTE GROUP_READ
        WORLD_EXECUTE WORLD_READ
)

# Install app specific files into the scripts directory
install(
    FILES
        ${CMAKE_SOURCE_DIR}/apps/heat.sao
        ${CMAKE_SOURCE_DIR}/apps/mag.lut
    DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_SCRIPTDIR}
    PERMISSIONS
        OWNER_EXECUTE OWNER_WRITE OWNER_READ
        GROUP_EXECUTE GROUP_READ
        WORLD_EXECUTE WORLD_READ
)

# Install scripts directory with subdirectories
install(
    DIRECTORY scripts/
    DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_SCRIPTDIR}
    FILES_MATCHING PATTERN "*"
    PERMISSIONS
        OWNER_EXECUTE OWNER_WRITE OWNER_READ
        GROUP_EXECUTE GROUP_READ
        WORLD_EXECUTE WORLD_READ
)

# Define color codes
string(ASCII 27 Esc)
set(ColorReset "${Esc}[m")
set(ColorBold "${Esc}[1m")
set(ColorRed "${Esc}[31m")
set(ColorGreen "${Esc}[32m")
set(ColorYellow "${Esc}[33m")
set(ColorBlue "${Esc}[34m")
set(ColorMagenta "${Esc}[35m")
set(ColorCyan "${Esc}[36m")

# Print install configuration
message(
    STATUS "${ColorBold}${ColorCyan}"
    "=== JSOC Workflow Configuration ===${ColorReset}"
)
message(
    STATUS "${ColorBold}${ColorBlue}"
    "Install prefix: ${ColorReset} ${CMAKE_INSTALL_PREFIX}"
)
message(
    STATUS
    "${ColorBold}${ColorBlue}"
    "Binaries will be installed to: ${ColorReset}"
    "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}"
)
message(
    STATUS
    "${ColorBold}${ColorBlue}"
    "Scripts will be installed to: ${ColorReset}"
    "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_SCRIPTDIR}"
)
