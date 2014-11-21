// Copyright (c) 2014 K Team. All Rights Reserved.

module MINT-SET
  imports MINT

  syntax MIntSet ::= MIntSet "U" MIntSet           [function, left, smtlib(smt_miset_cup)]
                   | ".MIntSet"                    [function, smtlib(smt_miset_emp)]
                   | "{" MInt "}"                  [function, smtlib(smt_miset_ele), klabel(smt_miset_ele)]
                   | MIntSet "-MIntSet" MIntSet    [function, smtlib(smt_miset_dif)]
  syntax Bool ::= MInt "inMIntSet" MIntSet         [function, smtlib(smt_miset_mem)]
                | MIntSet  "<MIntSet" MIntSet      [function, smtlib(smt_miset_lt)]
                | MIntSet "<=MIntSet" MIntSet      [function, smtlib(smt_miset_le)]
  rule S:MIntSet U .MIntSet => S    [lemma]
  rule .MIntSet U S:MIntSet => S    [lemma]

  rule I:MInt inMIntSet (S1:MIntSet U S2:MIntSet)
    => (I inMIntSet S1) orBool (I inMIntSet S2)
    [lemma]
  rule _:MInt inMIntSet .MIntSet => false                  [lemma]
  rule I1:MInt inMIntSet { I2:MInt } => I1 ==K I2          [lemma]

  rule S:MIntSet <MIntSet (S1:MIntSet U S2:MIntSet)
    => (S:MIntSet <MIntSet S1:MIntSet) andBool (S:MIntSet <MIntSet S2:MIntSet)
    [lemma]
  rule (S1:MIntSet U S2:MIntSet) <MIntSet S:MIntSet
    => (S1:MIntSet <MIntSet S:MIntSet) andBool (S2:MIntSet <MIntSet S:MIntSet)
    [lemma]
  rule _:MIntSet <MIntSet .MIntSet => true                  [lemma]
  rule .MIntSet <MIntSet _:MIntSet => true                  [lemma]
  rule { I1:MInt } <MIntSet { I2:MInt } => ultMInt(I1, I2)  [lemma]

  rule S:MIntSet <=MIntSet (S1:MIntSet U S2:MIntSet)
    => (S:MIntSet <=MIntSet S1:MIntSet) andBool (S:MIntSet <=MIntSet S2:MIntSet)
    [lemma]
  rule (S1:MIntSet U S2:MIntSet) <=MIntSet S:MIntSet
    => (S1:MIntSet <=MIntSet S:MIntSet) andBool (S2:MIntSet <=MIntSet S:MIntSet)
    [lemma]
  rule _:MIntSet <=MIntSet .MIntSet => true                 [lemma]
  rule .MIntSet <=MIntSet _:MIntSet => true                 [lemma]
  rule { I1:MInt } <=MIntSet { I2:MInt } => uleMInt(I1, I2) [lemma]

  rule .MIntSet -MIntSet _:MIntSet => .MIntSet              [lemma]
endmodule
