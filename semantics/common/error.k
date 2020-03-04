module ERROR-SYNTAX
     imports LIST
     imports MAP
     imports STRING-SYNTAX
     imports COMMON-SORTS

     syntax ErrorMsg ::= ErrorMsg(ErrorCategory, String, String, List)
                       | ErrorMsg(ErrorCategory, String, String) [function, klabel(ErrorMsgS)]

     syntax ErrorTrace ::= errorTrace(String, List)

     syntax K ::= reportError(ErrorMsg, tu: String, Scope, CabsLoc, Map, K) [function, hook(C_SEMANTICS.error)]

     syntax ErrorCategory ::= Undef(LanguageLinkage) | Unspec(LanguageLinkage) | Impl(LanguageLinkage) | ImplUB(LanguageLinkage) | Cond() | Ill() | Drafting(LanguageLinkage) | Constraint() | Syntax(LanguageLinkage)
     syntax KItem ::= EXIT(ErrorMsg)
     syntax ErrorExit ::= "HALT"
     syntax KItem ::= FATAL()

     syntax KItem ::= recoverFromError(K)
     syntax ErrorResult ::= errorFuncResult(K, K)

     syntax Error
     syntax K ::= assert(Bool, Error)

     syntax KItem ::= "EXT" "-" "UNDEF" "(" String "," String ")" [function, klabel(LinkUndef)]
     syntax KItem ::= "EXT" "-" "UNDEF" "(" String "," String "," List ")"
                    | ILL(String, String)
endmodule

module ERROR
     imports ERROR-SYNTAX
     imports C-CONFIGURATION
     imports K-IO
     imports K-REFLECTION
     imports STRING

     rule ErrorMsg(Type::ErrorCategory, Title::String, Msg::String)
          => ErrorMsg(Type, Title, Msg, .List)

     rule EXT-UNDEF(Title:String, Msg:String)
          => EXT-UNDEF(Title, Msg, .List)
     rule EXT-UNDEF(Title:String, Msg:String, Reason:List)
          => EXIT(ErrorMsg(Undef(CLinkage), Title, Msg, Reason))

     rule ILL(Title:String, Msg:String)
          => EXIT(ErrorMsg(Ill(), Title, Msg))

     rule errorFuncResult(K1:K, K2:K) => K1 ~> K2

     rule assert(B::Bool, E::Error) => #if B #then .K #else E #fi [macro]

endmodule
