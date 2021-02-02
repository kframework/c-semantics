module C-TRANSLATION-INIT
     imports BOOL
     imports LIST
     imports STRING
     imports COMPAT-SYNTAX
     imports OPTIONS-SYNTAX
     imports SETTINGS-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-CHECK-USE-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONFIGURATION
     imports C-CONVERSION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-RESOLUTION-SYNTAX
     imports C-DECL-TAGGED
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-EXPR-SYNTAX
     imports C-TYPING-INTERPRETATION
     imports C-TYPING-SYNTAX
     imports COMMON-INIT-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX

     rule <k> TranslationUnit(Tu:String, list(Strings:List), list(Decls:List))
               => makeTu(Tu +String Uuid)
               ~> preDeclareStrings(Strings)
               ~> listToK(Decls)
               ~> allocateIncompleteTentatives
               ~> removeUnusedIdentifiers(Tu +String Uuid)
          ...</k>
          <uuid> Uuid::String </uuid>

     syntax KItem ::= preDeclareStrings(List)
     rule preDeclareStrings(ListItem(K:KItem) L:List)
          => K ~> discard
          ~> preDeclareStrings(L)
          [structural]
     rule preDeclareStrings(.List) => .K
          [structural]

     rule CodeLoc(K:K, L:CabsLoc) => filterCabsLoc(L) ~> K
     rule DefinitionLocRange(K:KItem, L1:CabsLoc, L2:CabsLoc)
          => filterCabsLoc(L1) ~> K ~> filterCabsLoc(L2)

     rule <k> L:CabsLoc => .K ...</k>
          <elab>... .K => L </elab>
          <curr-program-loc> _ => L </curr-program-loc>

     syntax CabsLoc ::= filterCabsLoc(CabsLoc) [function]
     rule filterCabsLoc(CabsLoc("cabs loc unknown", _, -10, _, _))
          => UnknownCabsLoc
     rule filterCabsLoc(L:CabsLoc) => L [owise]

     rule ExpressionLoc(K:K, L:CabsLoc) => ExpLoc(K, L)

     rule typeof(ExpLoc(K:K, _:CabsLoc) => K)

     rule isKResult(ExpLoc(K:K, _::CabsLoc)) => isKResult(K) andBool notBool isTv(K)
     rule isHold(ExpLoc(K:K, _::CabsLoc)) => isHold(K)

     syntax Bool ::= isTv(K)  [function]
     rule isTv(tv(...)) => true
     rule isTv(_) => false [owise]

     rule
          <k> ExpLoc(K:K, L::CabsLoc) => K ~> #popExpLoc() ... </k>
          <curr-expression-loc> .List => ListItem(L) ...</curr-expression-loc>
          requires notBool isKResult(K)
     rule ExpLoc(tv(...) #as Tv:RValue, _::CabsLoc) => Tv

     rule <k> #popExpLoc() => .K ... </k>
          <curr-expression-loc> ListItem(L:CabsLoc) => .List ...</curr-expression-loc>

     rule <k> te(K:KItem, T:UType) ~> #popExpLoc() => te(ExpLoc(K, L), T) ... </k>
          <curr-expression-loc> ListItem(L:CabsLoc) => .List ...</curr-expression-loc>
          requires notBool isLocation(K)
     rule <k> te(ExpLoc(K:RValue, _), T:UType) ~> #popExpLoc() => te(ExpLoc(K, L), T) ... </k>
          <curr-expression-loc> ListItem(L:CabsLoc) => .List ...</curr-expression-loc>
          requires notBool isLocation(K)  // The requires clause should never be needed.

     rule <k> ncle(K:KItem, T:Type) ~> #popExpLoc() => ncle(ExpLoc(K, L), T) ... </k>
          <curr-expression-loc> ListItem(L:CabsLoc) => .List ...</curr-expression-loc>
          requires notBool isLocation(K)
     rule <k> ncle(ExpLoc(K:KItem, _), T:Type) ~> #popExpLoc() => ncle(ExpLoc(K, L), T) ... </k>
          <curr-expression-loc> ListItem(L:CabsLoc) => .List ...</curr-expression-loc>
          requires notBool isLocation(K)  // Should never be needed.

     rule <k> initValue(I:CId, T:Type, K:K) ~> #popExpLoc() => initValue(I, T, ExpLoc(K, L)) ... </k>
          <curr-expression-loc> ListItem(L:CabsLoc) => .List ...</curr-expression-loc>
          requires notBool isLocation(K)  // Should never be needed.

     rule <k> nclv(...) ~> (#popExpLoc() => .K) ... </k>
          <curr-expression-loc> ListItem(L:CabsLoc) => .List ...</curr-expression-loc>
     rule <k> V:RValue ~> (#popExpLoc() => .K) ... </k>
          <curr-expression-loc> ListItem(_:CabsLoc) => .List ...</curr-expression-loc>
          requires notBool isRHold(V)
     rule <k> reval(V:RValue) ~> (#popExpLoc() => .K) ... </k>
          <curr-expression-loc> ListItem(_:CabsLoc) => .List ...</curr-expression-loc>

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
     rule Pragma(X) => .K
          requires PragmaPack(_) :/=K X

     context Pragma(PragmaPack(HOLE:KItem => reval(HOLE)))

     rule <k> Pragma(PragmaPack(tv(V::Int, _))) => .K ...</k>
          <pragma-pack-value> _ => V </pragma-pack-value>

     rule <k> Pragma(PragmaPack(emptyValue)) => .K ...</k>
          <pragma-pack-value> _ => cfg:defaultMaxAlign </pragma-pack-value>

     rule NothingExpression() => emptyValue

     rule [[ nameOfCurrentTranslationUnit() => Tu ]]
          <curr-tu> Tu::String </curr-tu>

     rule currentSemantics() => CTranslation()

     context alias [c]: HERE:K

     rule (<T>...
               <k> cleanup </k>
               <options> Opts:Set </options>
          ...</T> => .Bag)
          requires notBool (Debug() in Opts)
          [structural]
endmodule
