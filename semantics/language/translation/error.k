module C-TRANSLATION-ERROR
     imports C-ERROR-SYNTAX

     imports C-BITS-SYNTAX
     imports C-COMMON-EXPR-CONDITIONAL-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX
     imports DEBUG-SYNTAX

    //TODO(LiyiLi): write to stderr has problem, use 2 instead
     rule <k> EXIT(Msg:String) 
          => #write(2, Msg +String "\n")
          ~> #write(2, "Location: " 
               +String File +String ":" 
               +String Int2String(Line)
               +String "\n")
          ~> HALT ...</k>
          <curr-program-loc> 
               CabsLoc(File:String, Line:Int, _, _)
          </curr-program-loc>
     rule <k> EXIT(Msg:String) 
          => #write(2, Msg +String "\n")
          ~> HALT ...</k>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>

     // TODO(chathhorn): clean up.
     // dynamic exp
     rule cast(t(N:Set, T:SimpleType), emptyValue)
	   => castHold(t(N,T),emptyValue)
          requires T =/=K void

     rule [err00001]: 
          (. => UNDEF("00001", "Casting empty value to type other than void.", "6.3.2.2:1"))
          ~> castHold(t(_, T:SimpleType), emptyValue)
          requires T =/=K void
          [structural]
          
     rule cast(t(N:Set, T:K), skipval)
	   => castHold(t(N,T),skipval)
          requires (T:K =/=K void)

     rule [err00034]:
          (. => ERROR("00034", "Casting void type to non-void type.", 308) ) ~>
          cast(t(_, T:K), skipval)
          requires (T:K =/=K void)
          [structural]
          
     rule [err00041]:
          (. => ERROR("00041", "If one of a conditional expression's branches has void type, the other must also have void type.", "6.5.15:3") ) ~>
          types(trItem(t(_, void)) ts:: trItem(t(_, T:K)))
          requires T:K =/=K void
          [structural]
     rule [err00042]:
          (. => ERROR("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
          types(trItem(t(_, T:K)) ts:: trItem(t(_, void)))
          requires T:K =/=K void
          [structural]
     rule [err00043]:
          (. => ERROR("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", "6.5.15:3") ) ~>
          types(trItem(T:Type) ts:: trItem(T':Type))
          requires (T =/=K T')
               andBool (isStructType(T) orBool isUnionType(T))
               andBool (isStructType(T') orBool isUnionType(T'))
          [structural]

     // rule [err00046]:
     //      (. => ERROR("00046", "Trying to reinterpret integer bytes as floating bytes.", 37) ) ~>
     //      concretize(T:Type, dataList((piece(N:Int, _:Int),, _)))
     //      requires hasFloatType(T) andBool (N >=Int 0)
     //      [structural]
          
// TODO(chathhorn): add this back.
//      rule <k> (. => ERROR("00215",
//                "Found multiple declarations of " +String S 
//                +String " with incompatible types.", 15)) ~>
//                verifyCompat(T:Type, Identifier(S:String)) 
//           ...</k>
//           <curr-tu> Tu:String </curr-tu>
//           <raw-types>... kpair(Tu, Identifier(S)) |-> PrevT:Type </raw-types>
//           requires notBool areCompatible(PrevT, T)

endmodule
