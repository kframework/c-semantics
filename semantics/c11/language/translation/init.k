module C-TRANSLATION-INIT
     imports C-CONFIGURATION
     imports BOOL
     imports LIST
     imports STRING
     imports COMPAT-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-COMMON-EXPR-REFERENCE-SYNTAX
     imports C-DECL-RESOLUTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-LINKING-INIT-SYNTAX
     imports C-LINKING-RESOLUTION-SYNTAX
     imports C-SYNTAX

     rule ToIdentifier("___missing_field_name") => #NoName
     rule ToIdentifier(S:String) => Identifier(S)
          requires S =/=String "___missing_field_name"

     rule <k> builtinTu => TranslationUnit("builtin", list(.List),
                   list(ListItem(addBuiltins(builtins, true))))
          ...</k>
          <options>... SetItem(XBuiltins()) ...</options>

     rule <k> builtinTu => .K ...</k>
          <options> Opts:Set </options>
          requires notBool (XBuiltins() in Opts)

     rule <k> TranslationUnit(TU:String, list(Strings:List), list(Decls:List))
               => makeTu(TU +String newUUID)
               ~> preDeclareStrings(Strings)
               ~> listToK(Decls)
               ~> allocateIncompleteTentatives
               ~> removeUnusedIdentifiers
          ...</k>

     syntax KItem ::= preDeclareStrings(List)

     rule preDeclareStrings(ListItem(K:K) L:List)
          => runInit(K ~> discard)
          ~> preDeclareStrings(L)
          [structural]
     rule preDeclareStrings(.List) => .K
          [structural]


     rule <k> reportSuccess => .K ...</k>
          <result-value> _ => 0 </result-value>

     rule CodeLoc(K:K, L:CabsLoc) => filterCabsLoc(L) ~> K
     rule DefinitionLocRange(K:K, L1:CabsLoc, L2:CabsLoc)
          => filterCabsLoc(L1) ~> K ~> filterCabsLoc(L2)

     rule <k> L:CabsLoc => .K ...</k>
          <elab>... .K => L </elab>
          <curr-program-loc> _ => L </curr-program-loc>

     syntax CabsLoc ::= filterCabsLoc(CabsLoc) [function]
     rule filterCabsLoc(CabsLoc("cabs loc unknown", -10, -10, 0, _))
          => UnknownCabsLoc
     rule filterCabsLoc(L:CabsLoc) => L [owise]

     rule ExpressionLoc(K:K, _) => K

     /*@ \fromStandard{\source[n1570]{\para{6.10.6}{1}}}{
     A preprocessing directive of the form
     \cdisplay{# pragma pp-tokensoptnew-line}
     \broken{where the preprocessing token \cinline{STDC} does not immediately
     follow pragma in the directive (prior to any macro replacement)} causes the
     implementation to behave in an implementation-defined manner. The behavior
     might cause translation to fail or cause the translator or the resulting
     program to behave in a non-conforming manner. Any such pragma that is not
     recognized by the implementation is ignored.
     }*/
     rule Pragma(_) => .K
          [structural]
     rule PragmaKccInv(_) => .K
          [structural]

     rule AttributeWrapper(K:K, _) => K

     rule NothingExpression() => {emptyValue}:>Expression

     rule Computation(.K) => .K
     rule <k> Computation(V:RValue) => .K ...</k>
          <elab>... .K => Computation(V) </elab>
          requires isHold(V)
     // Totally elide pure expressions from the translated program.
     rule Computation(V:RValue) => .K
          requires notBool isHold(V)

     rule checkRestrict(_) => .K

endmodule
