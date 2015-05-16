module C-EXPR-SEQUENCING
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     syntax KItem ::= commaListHolder(K)
     rule Comma(list(ListItem(K:K) L:List))
          => toRVal(K) ~> comma ~> commaListHolder(.K) ~> Comma(list(L))
          requires L =/=MSet .List
     rule commaListHolder(CL:K) ~> Comma(list(ListItem(K:K) L:List))
          => toRVal(K) ~> comma ~> commaListHolder(CL) ~> Comma(list(L))
          requires L =/=MSet .List

     rule (R:RValue ~> comma => .K)
          ~> commaListHolder(_ ~> (.K => toRVal(stripHold(R)) ~> comma))
          requires isHold(R)
     rule (R:RValue ~> comma => .K)
          ~> commaListHolder(_)
          requires notBool isHold(R)

     rule commaListHolder(CL:K) ~> Comma(list(ListItem(K:K)))
          => toRVal(K) ~> commaListHolder(CL)

     rule R:RValue ~> commaListHolder(CL:K)
          => e(CL ~> toRVal(stripHold(R)), type(R))

endmodule
