cmake_minimum_required ( VERSION 3.5 )

project ( clang-tools LANGUAGES CXX )


find_package ( Curses REQUIRED )
find_package ( LLVM 6.0 EXACT REQUIRED CONFIG )

link_directories ( ${LLVM_LIBRARY_DIRS} )

# NOTE: not needed because CURSES_LIBRARIES contains full paths.
# link_directories ( ${CURSES_LIBRARY_DIRS} )

include_directories ( ${LLVM_INCLUDE_DIRS} )
include_directories ( ${CURSES_INCLUDE_DIRS} )

add_compile_options (
  -Wall
  -Wno-unused-variable
  -Wno-unused-parameter
  -Wno-vla
  -Wno-comment
)

add_executable(clang-kast ClangKast/ClangKast.cc)
add_executable(call-sites CallSites/CallSites.cc)

set_target_properties (
  clang-kast
  call-sites
  PROPERTIES
    CXX_STANDARD 17
    CXX_EXTENSIONS OFF
    CXX_STANDARD_REQUIRED ON 
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

add_definitions (
  -D__STDC_LIMIT_MACROS
  -D__STDC_CONSTANT_MACROS
)


# NOTE: find_package(LLVM...) does not populate this variable, unfortunately.
set ( LLVM_LIBRARIES
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
  LLVMBinaryFormat
  LLVMSupport
)


target_link_libraries ( clang-kast PRIVATE ${LLVM_LIBRARIES} )
target_link_libraries ( call-sites PRIVATE ${LLVM_LIBRARIES} )

target_link_libraries ( clang-kast PRIVATE ${CURSES_LIBRARIES} )
target_link_libraries ( call-sites PRIVATE ${CURSES_LIBRARIES} )
