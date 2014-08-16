module C-TRANSLATION-ERROR
     imports C-ERROR-SYNTAX

     imports C-BITS-SYNTAX
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

    //TODO: write to stderr has problem, use 2 instead
     rule <k> EXIT(Msg:String)
          => #write(2, Msg +String "\n")
          ~> #write(2, "File: " +String File
               +String "\nLine: " +String Int2String(Line)
               +String "\n")
          ~> HALT ...</k>
          <curr-program-loc>
               CabsLoc(File:String, Line:Int, _, _)
          </curr-program-loc>
     rule <k> EXIT(Msg:String)
          => #write(2, Msg +String "\n")
          ~> HALT ...</k>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>

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
