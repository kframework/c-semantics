module C-ANNOTATION-SYNTAX
     imports C-SYNTAX
     syntax KItem ::= generateRuleAnnotation(CId)
     syntax String ::= #generateRuleAnnotation(CId, K) [function, hook(C_SEMANTICS.generateRuleAnnotation), impure]
     syntax KItem ::= writeAnnotation(String)
endmodule

module C-ANNOTATION
     imports C-ANNOTATION-SYNTAX
     imports C-CONFIGURATION
     imports C-ABSTRACT-SYNTAX

     rule <k> (PragmaKccRule(S:String) => .K) ~> CodeLoc(FunctionDefinition(_, _), _)  ...</k>
          <annotation> _ => S </annotation>

     rule <k> generateRuleAnnotation(X:CId) => writeAnnotation(#generateRuleAnnotation(X, S)) ...</k>
          <annotation> S:String => "" </annotation>
          requires S =/=K ""

     rule <k> generateRuleAnnotation(_) => .K ...</k>
          <annotation> "" </annotation>

     rule <k> writeAnnotation(S:String) => .K ...</k>
          <generated-annotations>... .List => ListItem(S) </generated-annotations>

endmodule
