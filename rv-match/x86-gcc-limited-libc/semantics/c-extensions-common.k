requires "core-extensions/c11/language/common/common.k"
requires "core-extensions/common/common.k"

module C-COMMON-EXTENSIONS
  imports CORE-EXTENSIONS-COMMON
  imports C-CORE-EXTENSIONS-COMMON
  imports C-BUILTIN-SYNTAX
  imports MAP

  rule extensionBuiltins => .Map
endmodule
