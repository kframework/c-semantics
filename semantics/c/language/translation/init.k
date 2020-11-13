module C-TRANSLATION-INIT
     imports BOOL
     imports LIST
     imports STRING
     imports COMPAT-SYNTAX
     imports OPTIONS-SYNTAX
     imports SETTINGS-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-CONFIGURATION
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-RESOLUTION-SYNTAX
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
     rule filterCabsLoc(CabsLoc("cabs loc unknown", _, -10, -10, _))
          => UnknownCabsLoc
     rule filterCabsLoc(L:CabsLoc) => L [owise]

     rule ExpressionLoc(K:K, L::CabsLoc) => ExpLoc(K, L)
     rule typeof(ExpLoc(K:K, L::CabsLoc) => K)
     rule utype(ExpLoc(K:K, L::CabsLoc) => K)
     rule type(ExpLoc(K:K, L::CabsLoc) => K)

     syntax KItem ::= #freezerExpLoc(CabsLoc)

     rule
          <k> ExpLoc(K:K, L::CabsLoc) => K ~> #freezerExpLoc(L) ... </k>
          <elab>... .K => L </elab>
          <curr-program-loc> _ => L </curr-program-loc>
          requires notBool isKResult(K)
     rule
          <k> (K:RValue ~> #freezerExpLoc(L)) => K ... </k>
          <elab>... .K => L </elab>
          <curr-program-loc> _ => L </curr-program-loc>
     rule
          <k> (K:KItem ~> #freezerExpLoc(L::CabsLoc)) => ExpLoc(K, L) ... </k>
          <elab>... .K => L </elab>
          <curr-program-loc> _ => L </curr-program-loc>
          requires isKResult(K)
          [owise]

     rule
          <k> reval(ExpLoc(K:RValue, L::CabsLoc) => K) ... </k>
          <elab>... .K => L </elab>
          <curr-program-loc> _ => L </curr-program-loc>
     rule reval(ExpLoc(ExpLoc(K:K, _::CabsLoc) => K, _::CabsLoc))

     rule reval(ExpLoc(ncle(K:KItem, T::Type), _::CabsLoc) => te(K, rvalType(T)))
     rule reval(ExpLoc(nclv(Loc::SymLoc, T::Type), _::CabsLoc) => nclv(Loc, T))

     rule isKResult(ExpLoc(K:K, _::CabsLoc)) => isKResult(K)

     rule (ExpLoc(ncle(K:KItem, T::Type), _::CabsLoc) => ncle(K, T)) ++
     rule (ExpLoc(ncle(K:KItem, T::Type), _::CabsLoc) => ncle(K, T)) --
     rule (ExpLoc(ncle(K:KItem, T::Type), _::CabsLoc) => ncle(K, T)) := _

     // Assignment.k
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) *= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) * E2)
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) /= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) / E2)
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) %= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) % E2)
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) += E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) + E2)
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) -= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) - E2)
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) <<= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) << E2)
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) >>= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) >> E2)
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) &= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) & E2)
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) ^= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) ^ E2)
     rule (ExpLoc(_:Nclv, _::CabsLoc) #as E1) |= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) | E2)

     rule (ExpLoc(E1:Nclv, _::CabsLoc) => E1) := _

     rule compoundAssign((ExpLoc(LV:Nclv, _::CabsLoc) => LV), AExp:RValue)

     // reference.k
     rule &(ExpLoc(E1:Nclv, _::CabsLoc) => E1)

     // inc-and-dec.k
     rule ++ (ExpLoc(E1:Nclv, _::CabsLoc) #as E) => E += tv(1, utype(int))
     rule -- (ExpLoc(E1:Nclv, _::CabsLoc) #as E) => E -= tv(1, utype(int))

     // members.k
     rule (ExpLoc(E1:Nclv, _::CabsLoc) => E1) . _:CId
          [structural]

     // initializer.k
     rule figureInit(_:CId, _:Type, SingleInit(ExpLoc(K:KItem, _::CabsLoc) => K))

     //interpretation.k
     rule BitFieldType(_::KItem, (ExpLoc(K:KItem, _::CabsLoc) => K))
          [structural]



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
