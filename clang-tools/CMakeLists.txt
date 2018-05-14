cmake_minimum_required(VERSION 2.8.4)
project(clang-tools)

set(LLVM_PATH /usr/lib/llvm-3.9 CACHE PATH "LLVM path")
link_directories(${LLVM_PATH}/lib)
include_directories(${LLVM_PATH}/include)

add_definitions(
-D__STDC_LIMIT_MACROS
-D__STDC_CONSTANT_MACROS
)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall -Wno-unused-variable")
set(CLANG_KAST_FILES ClangKast.cc)
set(CALL_SITES_FILES CallSites.cc)
add_executable(clang-kast ${CLANG_KAST_FILES})
add_executable(call-sites ${CALL_SITES_FILES})

include(FindCurses)
set(LIBS
  clangFrontend
  clangSerialization
  clangDriver
  clangParse
  clangSema
  clangAnalysis
  clangAST
  clangBasic
  clangEdit
  clangLex
  clangTooling
  LLVMProfileData
  LLVMX86AsmParser # MC, MCParser, Support, X86Desc, X86Info
  LLVMX86Desc # MC, Support, X86AsmPrinter, X86Info
  LLVMX86AsmPrinter # MC, Support, X86Utils
  LLVMX86Info # MC, Support, Target
  LLVMX86Utils # Core, Support
  LLVMipo
  LLVMScalarOpts
  LLVMInstCombine
  LLVMTransformUtils
  LLVMAnalysis
  LLVMTarget
  LLVMOption # Support
  LLVMMCParser # MC, Support
  LLVMMC # Object, Support
  LLVMObject # BitReader, Core, Support
  LLVMBitReader # Core, Support
  LLVMCore # Support
  LLVMSupport
  pthread
  z
  dl
  ${CURSES_LIBRARIES}
)

target_link_libraries(clang-kast ${LIBS})
target_link_libraries(call-sites ${LIBS})

install(TARGETS clang-kast
        RUNTIME DESTINATION bin)
install(TARGETS call-sites
        RUNTIME DESTINATION bin)
