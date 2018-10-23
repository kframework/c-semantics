module LINKING-C-BUILTIN-SYNTAX
     imports MAP
     imports STRING

     syntax KItem ::= addCBuiltins(tu: String, Map)
     syntax KItem ::= addNativeSymbols(tu: String, Map)
endmodule

module LINKING-C-BUILTIN
     imports LINKING-C-BUILTIN-SYNTAX
     imports C-CONFIGURATION
     imports C-ALIGNMENT-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX

     rule (.K => addBuiltin(Tu, X, adjustParams(T), obj(0, byteAlignofType(T), builtinSymbol(idToSymbol(X))), true))
               ~> addCBuiltins(Tu::String, (X::CId |-> T:Type => .Map) _)
     rule addCBuiltins(_, .Map) => .K

     rule (.K => addBuiltin(Tu, X, adjustParams(T), obj(0, byteAlignofType(T), nativeSymbol(idToSymbol(X))), false))
               ~> addNativeSymbols(Tu::String, (X::CId |-> T:Type => .Map) _)
     rule addNativeSymbols(_, .Map) => .K

     // Only add a builtin if it has an external type (that is, it's been
     // declared somewhere) and if it doesn't already have a definition.
     // Therefore, if someone redefines a builtin, we won't co-opt it.
     // We should use this mechanism only for symbols that are considered weak
     // by the C and C++ standards, or for native symbols.

     syntax KItem ::= addBuiltin(tu: String, CId, Type, SymBase, Bool)
     rule <k> addBuiltin(Tu::String, B::CId, T:FunctionType, Base::SymBase, AddAll:Bool)
               => declareBuiltinFunction(B, T, Base, Tu)
          ...</k>
          <external-uses> Uses:Map </external-uses>
          <external-types> Types:Map </external-types>
          <external-defs> Defs:Map </external-defs>
          <tu-id> Tu </tu-id>
          <uses>... .Set => SetItem(B) ...</uses>
          requires (notBool (B in_keys(Defs)) andBool B in_keys(Uses))
               orBool (notBool (B in_keys(Defs)) andBool (B in_keys(Types)))
               orBool AddAll

     rule <k> addBuiltin(Tu::String, B::CId, T::Type, Base::SymBase, AddAll:Bool)
               => declareBuiltinConstant(B, T, Base, Tu)
          ...</k>
          <external-uses> Uses:Map </external-uses>
          <external-defs> Defs:Map </external-defs>
          <tu-id> Tu </tu-id>
          <uses>... .Set => SetItem(B) ...</uses>
          requires ((notBool (B in_keys(Defs)) andBool B in_keys(Uses))
               orBool AddAll)
               andBool notBool isFunctionType(T)

     rule <k> addBuiltin(_, B::CId, _, _, false) => .K ...</k>
          <external-defs> Defs:Map </external-defs>
          <external-uses> Uses:Map </external-uses>
          requires (B in_keys(Defs))
               orBool notBool (B in_keys(Uses))

     // compare against declare()
     syntax KItem ::= declareBuiltinFunction(CId, Type, SymBase, String)
                    | declareBuiltinConstant(CId, Type, SymBase, String)

     rule <k> declareBuiltinFunction(B:CId, T::Type, Base:SymBase, Tu::String) => .K ...</k>
          <mem> Mem::Map => Mem[Base <- object(T, 1, makeEmptyArray(1))] </mem>
          <functions> Fun::Map => Fun[Base <- functionObject(B, T, .List)] </functions>
          <external-decls> Decls::Map => Decls[B += Tu] </external-decls>
          <external-decls-loc> DeclLocs::Map => DeclLocs[B <- UnknownCabsLoc] </external-decls-loc>
          <external-defs> Defs::Map => Defs[B <- Base] </external-defs>
          <external-defs-loc> Locs::Map => Locs[B <- UnknownCabsLoc] </external-defs-loc>
          <tu-id> Tu </tu-id>
          <genv> Env::Map => Env[B <- Base] </genv>
          <gtypes> Types::Map => Types[B <- T] </gtypes>

     rule <k> declareBuiltinConstant(B:CId, T::Type, Base:SymBase, Tu::String) => .K ...</k>
          <external-decls> Decls::Map => Decls[B += Tu] </external-decls>
          <external-decls-loc> DeclLocs::Map => DeclLocs[B <- UnknownCabsLoc] </external-decls-loc>
          <external-defs> Defs::Map => Defs[B <- Base] </external-defs>
          <external-defs-loc> Locs::Map => Locs[B <- UnknownCabsLoc] </external-defs-loc>
          <tu-id> Tu </tu-id>
          <genv> Env::Map => Env[B <- Base] </genv>
          <gtypes> Types::Map => Types[B <- T] </gtypes>

     syntax String ::= idToSymbol(CId) [function]
     rule idToSymbol(Identifier(S::String)) => S

endmodule
