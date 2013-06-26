module C-TYPING-STRICTNESS
     imports C-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS
     imports C-CONFIGURATION

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
