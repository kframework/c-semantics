module LINKING-C-RESOLUTION-SYNTAX
     imports MAP

     syntax KItem ::= resolveCReferences(Map)
                    | "resolveMain"
endmodule

module LINKING-C-RESOLUTION
     imports LINKING-C-RESOLUTION-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports MAP
     imports STRING
     imports COMMON-SORTS
     imports ERROR-SYNTAX
     imports SYMLOC-SYNTAX

     // Add the real location at which an external reference is defined to the
     // environment of every TU where it appears.

     syntax KItem ::= resolveCReference(CId)
     rule (.K => setTranslationLoc(L) ~> resolveCReference(X))
               ~> resolveCReferences((X:CId |-> L:CabsLoc => .Map) _)
          [structural]

     rule <k> resolveCReference(X:CId) ...</k>
          <external-decls>...
               X |-> (SetItem(Tu:String) => .Set) _::Set
          ...</external-decls>
          <external-defs>... X |-> Base':SymBase ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>... X |-> (Base:LinkBase => Base') ...</genv>
          <linkings>... .Map => Base |-> Base' ...</linkings>
          [structural]
     rule <k> resolveCReference(X:CId) ...</k>
          <external-decls>...
               X |-> (SetItem(Tu:String) => .Set) _::Set
          ...</external-decls>
          <external-defs>... X |-> _ ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>... X |-> Base:DirectBase ...</genv>
          [structural]
     rule <k> resolveCReference(X:CId) => .K  ...</k>
          <external-decls>...
               X:CId |-> .Set => .Map
          ...</external-decls>
          <external-defs>... X |-> _ ...</external-defs>
          <external-types>... X |-> _ ...</external-types>
          [structural]
     rule <k> resolveCReference(X:CId) => .K ...</k>
          <external-defs> Defs:Map </external-defs>
          <external-types> Types:Map </external-types>
          requires (notBool (X in_keys(Defs)) orBool notBool (X in_keys(Types)))
               andBool isMangledName(X)
          [structural]
     rule <k> (.K => setTranslationLoc(L) ~> EXT-UNDEF("TDR2",
                    "No definition for symbol with external linkage: "
                     +String showCId(X) +String "."))
              ~> resolveCReference(X:CId)
          ...</k>
          <external-defs> Defs:Map </external-defs>
          <external-types> Types:Map </external-types>
          <external-decls-loc>...
               X |-> L::CabsLoc
          ...</external-decls-loc>
          requires (notBool (X in_keys(Defs)) orBool notBool (X in_keys(Types)))
               andBool notBool isMangledName(X)
          [structural]
     // Now everything left in <external-uses> should be an unresolved
     // reference.
     rule resolveCReferences(.Map) => .K

     syntax Bool ::= isMangledName(CId) [function]
     rule isMangledName(Identifier(X::String)) => substrString(X, 0, 2) ==String "_Z"
          requires lengthString(X) >Int 2
     rule isMangledName(_) => false [owise]

     // Remember which TU has the definition of main.
     rule <k> resolveMain => .K ...</k>
          <main-tu>... .Set => SetItem(MainTu) </main-tu>
          <external-defs>...
               Identifier("main") |-> (obj(... d: static(MainTu:String)) #as Main::SymBase)
          ...</external-defs>
          <external-types>...
               Identifier("main") |-> _
          ...</external-types>
          <functions>... Main |-> _ ...</functions>
          [structural]
     rule <k> (.K => setTranslationLoc(L) ~> EXT-UNDEF("TDR3", "Main is not a function."))
               ~> resolveMain
          ...</k>
          <external-defs>...
               Identifier("main") |-> Main::SymBase
          ...</external-defs>
          <external-defs-loc>...
               Identifier("main") |-> L::CabsLoc
          ...</external-defs-loc>
          <functions> Functions:Map </functions>
          requires notBool (Main in_keys(Functions))
          [structural]

endmodule
