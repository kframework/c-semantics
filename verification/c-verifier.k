require "../semantics/c11.k"
require "int_set.k"
require "int_list.k"
require "tree_pattern.k"
require "list_pattern.k"

module C-VERIFIER
  imports C11
  imports C-CONFIGURATION
  imports LIST-PATTERN
  imports TREE-PATTERN

  rule cast(t(.Set, T:SimpleType), tv(V:CValue, t(_:Set, T)))
    => tv(V, t(.Set, T:SimpleType))    //[lemma]

  rule (I1:Int &Int I2:Int) &Int I2:Int => I1:Int &Int I2:Int    [lemma]
  rule I:Int |Int 0 => I [lemma]
  rule 0 |Int I:Int => I [lemma]
  rule ((I1:Int >>Int I2:Int) &Int I3:Int) <<Int I2:Int
    => I1 &Int (I3 <<Int I2)
    [lemma]
  rule (I1:Int &Int I2:Int) |Int (I1:Int &Int I3:Int)
    => I1 &Int (I2 |Int I3)
    [lemma]
  rule I:Int &Int 4294967295 => I
    requires (-2147483648 <=Int I) andBool (I <=Int 2147483647)
    [lemma]
  rule (I1:Int +Int I2:Int) -Int I3:Int => I1 +Int (I2 -Int I3)   [lemma]
  rule I:Int +Int 0 => I    [lemma]
  rule 0 +Int I:Int => I    [lemma]


  /* set axioms */
  rule intersectSet(SetItem(K:K) S1:Set, S2:Set)
    => #if K in S2 #then
         SetItem(K) intersectSet(S1, S2)
       #else
         intersectSet(S1, S2)
       #fi 
  rule intersectSet(.Set, _:Set) => .Set

  rule (SetItem(K:K) S1:Set) -Set S2:Set
    => #if K in S2 #then
         S1 -Set S2
       #else
         SetItem(K) (S1 -Set S2)
       #fi 
  rule .Set -Set _:Set => .Set

  rule '_<=Set_(S1:Set,, S2:Set) => (S1 -Set S2) ==K .Set

  rule K1:K in SetItem(K2:K) S:Set => K1 ==K K2 orBool K1 in S
  rule _:K in .Set => false

  /* list axioms */
  rule K1:K in ListItem(K2:K) L:List => K1 ==K K2 orBool K1 in L
  rule _ in .List => false

  syntax KItem ::= "breakpoint"
endmodule

