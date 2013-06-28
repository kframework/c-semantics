module C-TYPING-STRICTNESS-SYNTAX
     syntax K ::= "evalToType"

endmodule

module C-TYPING-STRICTNESS
     imports C-TYPING-STRICTNESS-SYNTAX

     imports C-SYNTAX
     imports C-SEMANTIC-SYNTAX

     syntax K ::= "waitingOnDeclType"
     rule [type-Cast-heat]:
          <k> (. => DeclType(Spec:K, Decl:K)) ~> evalToType ...</k>
          <type> 
               Cast(Spec, Decl, _) => waitingOnDeclType
          ...</type>
          [structural]
          
     rule [type-Cast-cool]:
          <k> (T:KResult => .) ~> evalToType ...</k>
          <type> waitingOnDeclType => T:KResult ...</type>
          [structural]
endmodule
