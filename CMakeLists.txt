# =============================================================================
# miniSoftwareRenderer —— 从零实现的 C++ 软渲染器
#
# 用法（在仓库根目录执行）：
#     cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
#     cmake --build build -j
#
# 生成器可任选：MinGW Makefiles / Unix Makefiles / Ninja / Visual Studio。
# =============================================================================
cmake_minimum_required(VERSION 3.20)

project(miniSoftwareRenderer
        VERSION 1.0.0
        DESCRIPTION "Software rasterizer written from scratch in C++"
        LANGUAGES CXX)

# -----------------------------------------------------------------------------
# 平台限制
#
# 平台层 miniSoftwareRenderer/win32.cpp 直接使用 Win32 API（<windows.h>、GDI）
# 创建窗口并呈现后台缓冲，因此本项目目前只能在 Windows 上构建。
# 这是代码层面的约束，与构建系统无关。
# -----------------------------------------------------------------------------
if(NOT WIN32)
    message(FATAL_ERROR
        "miniSoftwareRenderer 目前只支持 Windows / Windows only.\n"
        "平台层 win32.cpp 依赖 <windows.h> 与 GDI，请在 Windows 上"
        "使用 MSVC 或 MinGW-w64 构建。")
endif()

# -----------------------------------------------------------------------------
# 语言标准与全局选项
# -----------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 生成 compile_commands.json，方便 clangd / VS Code / CLion 解析
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 单配置生成器（MinGW Makefiles / Ninja / Unix Makefiles）默认使用 Release
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "构建类型" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
                 Debug Release RelWithDebInfo MinSizeRel)
endif()

# 原 VS 工程在 Release/Unicode 配置下定义了 UNICODE/_UNICODE
option(HANA_USE_UNICODE "定义 UNICODE/_UNICODE，使用 Win32 宽字符 API" ON)

# -----------------------------------------------------------------------------
# 源文件与头文件
# -----------------------------------------------------------------------------
set(HANA_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/miniSoftwareRenderer")

set(HANA_SOURCES
    "${HANA_SRC_DIR}/camera.cpp"
    "${HANA_SRC_DIR}/color.cpp"
    "${HANA_SRC_DIR}/gameobject.cpp"
    "${HANA_SRC_DIR}/graphics.cpp"
    "${HANA_SRC_DIR}/IShader.cpp"
    "${HANA_SRC_DIR}/main.cpp"
    "${HANA_SRC_DIR}/maths.cpp"
    "${HANA_SRC_DIR}/model.cpp"
    "${HANA_SRC_DIR}/renderbuffer.cpp"
    "${HANA_SRC_DIR}/scene.cpp"
    "${HANA_SRC_DIR}/tgaimage.cpp"
    "${HANA_SRC_DIR}/vector.cpp"
    "${HANA_SRC_DIR}/win32.cpp"
)

set(HANA_HEADERS
    "${HANA_SRC_DIR}/camera.h"
    "${HANA_SRC_DIR}/color.h"
    "${HANA_SRC_DIR}/gameobject.h"
    "${HANA_SRC_DIR}/graphics.h"
    "${HANA_SRC_DIR}/IShader.h"
    "${HANA_SRC_DIR}/mathapi.h"
    "${HANA_SRC_DIR}/maths.h"
    "${HANA_SRC_DIR}/matrix.h"
    "${HANA_SRC_DIR}/model.h"
    "${HANA_SRC_DIR}/platform.h"
    "${HANA_SRC_DIR}/renderbuffer.h"
    "${HANA_SRC_DIR}/scene.h"
    "${HANA_SRC_DIR}/tgaimage.h"
    "${HANA_SRC_DIR}/vector.h"
)

add_executable(${PROJECT_NAME} ${HANA_SOURCES} ${HANA_HEADERS})

# 头文件与源文件同目录，使用引号包含即可解析；显式声明便于 IDE 补全
target_include_directories(${PROJECT_NAME} PRIVATE "${HANA_SRC_DIR}")

# 注意：不要用 file(GLOB) 把 assets/ 加进 target_sources()。
# assets/**/*.obj 是 Wavefront 模型数据，而 .obj 同时是 MSVC 的目标文件后缀，
# CMake 会把它们当成待链接的目标文件而构建失败。

source_group("Source Files" FILES ${HANA_SOURCES})
source_group("Header Files" FILES ${HANA_HEADERS})

# -----------------------------------------------------------------------------
# 编译选项
# -----------------------------------------------------------------------------
if(MSVC)
    # 对齐原 vcxproj：WarningLevel=Level3、ConformanceMode、DisableSpecificWarnings 4996
    target_compile_options(${PROJECT_NAME} PRIVATE /W3 /MP /wd4996 /permissive-)
else()
    # MinGW-w64 / gcc / clang
    target_compile_options(${PROJECT_NAME} PRIVATE -Wall)
endif()

target_compile_definitions(${PROJECT_NAME} PRIVATE _CONSOLE)

if(HANA_USE_UNICODE)
    target_compile_definitions(${PROJECT_NAME} PRIVATE UNICODE _UNICODE)
endif()

# -----------------------------------------------------------------------------
# 输出位置
# -----------------------------------------------------------------------------
# 单配置生成器 -> build/bin/；多配置生成器会在其后追加配置名，如 build/bin/Release/
set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

# -----------------------------------------------------------------------------
# 资源拷贝
#
# win32.cpp 的 initialize_path() 会 chdir 到 <可执行文件目录>/assets，
# 随后各场景以 "../assets/..." 访问模型与贴图，因此 assets 必须与 exe 同目录。
# 对应原 vcxproj 的 PostBuildEvent（xcopy）。
# -----------------------------------------------------------------------------
set(HANA_ASSET_DIR "${HANA_SRC_DIR}/assets")

add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E copy_directory
            "${HANA_ASSET_DIR}"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>/assets"
    COMMENT "复制 assets 到 $<TARGET_FILE_DIR:${PROJECT_NAME}>/assets"
)
