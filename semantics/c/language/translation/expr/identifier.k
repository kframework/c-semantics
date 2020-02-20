module C-EXPR-IDENTIFIER
     imports C-CONFIGURATION
     imports K-EQUAL
     imports SET
     imports C-ABSTRACT-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> X:CId =>
              #if isRestrictType(T) #then
                lv(restrictedNew(Base, getRestrictBlock(T)), T)
              #else
                lv(lnew(Base), T)
              #fi
          ...</k>
          <env>... X |-> Base:DirectBase ...</env>
          <types>... X |-> T::Type ...</types>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <uses>... .Set => SetItem(X) ...</uses>
          <enums> Enums::Map </enums>
          requires Base =/=K nonStatic
               andBool notBool X in_keys(Enums)
          [structural]

     rule <k> X:CId => le(X, T) ...</k>
          <env>... X |-> nonStatic ...</env>
          <types>... X |-> T::Type ...</types>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <uses>... .Set => SetItem(X) ...</uses>
          <enums> Enums::Map </enums>
          requires notBool X in_keys(Enums)
          [structural]

     // We need to record uses of external symbols because if an external
     // without a definition isn't ever used, then it isn't a link error.
     rule <k> X:CId => lv(lnew(Base), T) ...</k>
          <env>... X |-> Base:LinkBase ...</env>
          <types>... X |-> T::Type ...</types>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>... X |-> _ ...</externals>
          <external-uses> Uses::Map => Uses[X <- L] </external-uses>
          <uses>... .Set => SetItem(X) ...</uses>
          <curr-program-loc> L:CabsLoc </curr-program-loc>
          <enums> Enums::Map </enums>
          requires notBool X in_keys(Enums)
          [structural]

     // According to C18 sec. 6.6:6, enumeration constants are constants and therefore
     // not lvalues, which designate an object. Therefore we convert directly to a tv
     // so that expressions like &x will not work.
     rule <k> X:CId => tv(Value, ut(SetItem(IntegerConstant), int)) ...</k>
          <enums>... X |-> Value::Int ...</enums>

     rule instantiate(Loc::SymLoc, T::Type)
          => te(instantiate(Loc, T), utype(T))
          requires notBool fromConstantExpr(T)
               orBool notBool isStaticDuration(Loc)
               orBool isLinkerLoc(Loc)
               orBool isBuiltinLoc(Loc)
     rule instantiate(Loc::SymLoc, T::Type) => read(Loc, T)
          requires fromConstantExpr(T)
               andBool isStaticDuration(Loc)
               andBool notBool isLinkerLoc(Loc)
               andBool notBool isBuiltinLoc(Loc)

endmodule
