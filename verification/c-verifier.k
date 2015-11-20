require "../semantics/c11.k"
require "lemmas.k"
require "int_set.k"
require "int_list.k"
require "tree_pattern.k"
require "list_pattern.k"

module C-VERIFIER
  imports C11
  imports C-CONFIGURATION
  imports LEMMAS
  imports LIST-PATTERN
  imports TREE-PATTERN

  syntax KItem ::= "breakpoint"

  syntax Int ::= "ii" "(" Int "," Int "," Int "," Int ")"
  rule ii(I3:Int,I2:Int,I1:Int,I0:Int)
    => ((((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int) [macro]
endmodule
