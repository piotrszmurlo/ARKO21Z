cmake_minimum_required(VERSION 3.9)
project(test C)

set(CMAKE_C_STANDARD 99)

enable_language(C ASM_NASM)
set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")


add_compile_options(
        "$<$<COMPILE_LANGUAGE:ASM_NASM>:-f $<IF:$<BOOL:$<TARGET_PROPERTY:NASM_OBJ_FORMAT>>, \
    $<TARGET_PROPERTY:NASM_OBJ_FORMAT>, ${CMAKE_ASM_NASM_OBJECT_FORMAT}>>"
)


set(CMAKE_ASM_NASM_FLAGS_DEBUG "-g -Fdwarf")
add_executable(test main.c bilinear_interpolation.asm)
set_target_properties(test PROPERTIES
        NASM_OBJ_FORMAT elf64
        RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_CURRENT_SOURCE_DIR}
        RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_CURRENT_SOURCE_DIR})
#=============================================================

target_link_libraries(test PRIVATE allegro
        /usr/lib/liballegro_image.so.5.2.8
        /usr/lib/liballegro_primitives.so.5.2.8)
        
