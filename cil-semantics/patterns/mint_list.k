// Copyright (c) 2014 K Team. All Rights Reserved.

module MINT-LIST
  imports LIST

  rule size(L1:List L2:List) => size(L1) +Int size(L2)    [lemma]
  rule size(ListItem(_)) => 1                             [lemma]
  rule size(.List) => 0                                   [lemma]

  syntax MInt ::= sum(List)                               [function, smtlib(smt_seq_sum)]
  rule sum(L1:List L2:List) => addMInt(sum(L1), sum(L2))  [lemma]
  rule sum(ListItem(MI:MInt)) => MI                       [lemma]
  rule sum(.List) => mi(32, 0)                            [lemma] // TODO(YilongL): avoid hardcoded bit width

  syntax List ::= rev(List)                               [function]
  rule rev(L1:List L2:List) => rev(L2) rev(L1)            [lemma]
  rule rev(ListItem(MI:MInt)) => ListItem(MI)             [lemma]
  rule rev(.List) => .List                                [lemma]

endmodule
