cmake_minimum_required(VERSION 3.5)
project(hanayomi LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)  # Needed for QObject subclasses

find_package(Qt5 COMPONENTS Core Gui Qml Quick Network Sql REQUIRED)

add_executable(hanayomi
    src/main.cpp
    src/MangaDexSource.cpp
    src/DatabaseHelper.cpp
    src/SuwayomiRunner.cpp
)

target_include_directories(hanayomi PRIVATE src)

target_link_libraries(hanayomi
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::Network
    Qt5::Sql
)

install(TARGETS hanayomi DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY qml DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY jre DESTINATION ${CMAKE_INSTALL_PREFIX})
install(DIRECTORY suwayomi-lib DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES hanayomi.desktop hanayomi.apparmor manifest.json hanayomi.svg DESTINATION ${CMAKE_INSTALL_PREFIX})
