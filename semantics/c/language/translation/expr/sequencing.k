module C-EXPR-SEQUENCING
     imports BASIC-K
     imports BOOL
     imports K-EQUAL
     imports COMPAT-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax KItem ::= commaListHolder(K)
     rule Comma(list(ListItem(K:KItem) L:List))
          => toRVal(K) ~> comma ~> commaListHolder(.K) ~> Comma(list(L))
          requires L =/=K .List
     rule commaListHolder(CL:K) ~> Comma(list(ListItem(K:KItem) L:List))
          => toRVal(K) ~> comma ~> commaListHolder(CL) ~> Comma(list(L))
          requires L =/=K .List

     rule (toRVal(R:RValue) ~> comma => .K)
          ~> commaListHolder(_ ~> (.K => toRVal(stripHold(R)) ~> comma))
          requires isHold(R)
     rule (toRVal(R:RValue) ~> comma => .K)
          ~> commaListHolder(_)
          requires notBool isHold(R)

     rule commaListHolder(CL:K) ~> Comma(list(ListItem(K:KItem)))
          => toRVal(K) ~> commaListHolder(CL)
     rule toRVal(R:RValue) ~> commaListHolder(CL:K)
          => te(compoundExp(CL ~> toRVal(stripHold(R))), stripConstants(utype(R)))

endmodule
