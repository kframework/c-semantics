module CPP-EXECUTION-STMT-BLOCK-SYNTAX
     imports BOOL

     syntax LVal

     syntax KItem ::= lcentry(
                         val: LVal,
                         initialized: Bool,
                         canBeVirtual: Bool,
                         isConstructor: Bool)

     syntax KItem ::= destructLocal(isException: Bool, entry: KItem)

endmodule

module CPP-EXECUTION-STMT-BLOCK
     imports C-CONFIGURATION
     imports INT
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports DELETE-OBJECT-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports CPP-EXECUTION-EXPR-REFERENCE-SYNTAX
     imports CPP-EXECUTION-FULL-EXPRESSION-SYNTAX
     imports CPP-EXECUTION-STMT-BLOCK-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-CLASS-BASIC-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX

     rule <k> saveLocallyConstructed(E::Expr) => E ~> restoreLocallyConstructed(L) ...</k>
          <locally-constructed> L::List </locally-constructed>

     syntax KItem ::= restoreLocallyConstructed(List)

     rule <k> V:Val ~> restoreLocallyConstructed(L::List) => V ...</k>
          <locally-constructed> _ => L </locally-constructed>
          requires isEvalVal(V)

     rule <k> pushBlock(Tag:Int)
               => addToHistory(Tag) ~> enterRestrictBlock(blockScope(F, Base, Tag))
          ...</k>
          <curr-scope> blockScope(F::QualId, Base::SymBase, (_ => Tag)) </curr-scope>
          <block-control>
               C::Bag
               <catch-handlers> Catch::List => .List </catch-handlers>
               <local-vars> Vars::Set => .Set </local-vars>
               <locally-constructed> Constructed::List => .List </locally-constructed>
          </block-control>
          <block-stack> .List
               => ListItem(<block-control>
                    C
                    <catch-handlers> Catch </catch-handlers>
                    <local-vars> Vars </local-vars>
                    <locally-constructed> Constructed </locally-constructed>
               </block-control>)
          ...</block-stack>

     syntax KItem ::= "updateScope"

     rule <k> updateScope => .K ...</k>
          <curr-scope> blockScope(_, _, (_ => Tag)) </curr-scope>
          <block-history> ListItem(Tag::Int) ...</block-history>

     rule <k> updateScope => .K ...</k>
          <curr-scope> blockScope(_, _, (_ => 0)) </curr-scope>
          <block-history> .List </block-history>

     rule popBlock(IsException::Bool) => destructLocals(IsException) ~> unfoldBlockStack ~> exitRestrictBlock(getLocalAddresses()) ~> updateScope
          [structural]

     syntax Set ::= getLocalAddresses() [function]
                  | #getLocalAddresses(List, Set) [function]

     rule [[ getLocalAddresses() => #getLocalAddresses(LC, .Set) ]]
          <locally-constructed> LC::List </locally-constructed>

     rule #getLocalAddresses(.List, S::Set) => S
     rule #getLocalAddresses(
               (ListItem(lcentry(lv(Loc::SymLoc, _, _), _, _, _)) => .List) _,
               (.Set => SetItem(base(Loc))) _
          )

     rule <k> addToConstructed(L:LVal, t(... st: classType(...)) #as T::CPPType) => .K ...</k>
          <locally-constructed> .List => ListItem(lcentry(L, true, false, false)) ...</locally-constructed>

     rule (.K => addToConstructed(L [ prv(N -Int 1, noTrace, type(size_t)) ], T))
          ~> addToConstructed(L:LVal, t(... st: arrayType(T::CPPType, N::Int => N -Int 1)))
          requires N >Int 0

     rule addToConstructed(_, t(... st: arrayType(_, 0))) => .K

     // we have to atomically remove the item from locally-constructed and call the destructor as a single operation
     // because the destructor could throw an exception that unwinds back through this block, in which case the
     // destructor should not be called again. See http://www.open-std.org/jtc1/sc22/wg21/docs/cwg_defects.html#2176

     rule <k> (.K => destructLocal(IsException, Entry))
              ~> destructLocals(IsException:Bool)
          ...</k>
          <locally-constructed> ListItem(Entry::KItem) => .List ...</locally-constructed>

     rule <k> destructLocals(...) => .K ...</k>
          <locally-constructed> .List </locally-constructed>


     rule destructLocal(IsException:Bool,
               lcentry(
                    lv(Loc::SymLoc, _, T::CPPType) #as V::LVal,
                    Initialized:Bool,
                    CanBeVirtual::Bool,
                    IsConstructor:Bool
               )
          )
          =>
          #if notBool Initialized orBool (IsConstructor andBool notBool IsException) #then
               .K
          #else
               destruct(V, CanBeVirtual) ~> fullExpression
          #fi
          ~>
          #if IsConstructor orBool isCPPRefType(T) #then
               .K
          #else
               deleteObject(base(Loc))
          #fi
          ~>
          #if isCPPRefType(T) #then
               deleteReference(Loc)
          #else .K #fi

     syntax KItem ::= "unfoldBlockStack"

     rule <k> unfoldBlockStack => .K ...</k>
          (<block-control>... .Bag ...</block-control> => C)
          <block-stack> ListItem(C:BlockControlCell) => .List ...</block-stack>

     syntax KItem ::= destruct(LVal, canBeVirtual: Bool)

     // we don't need an explicit type conversion here because the type of the implicit parameter is already the same
     // as the type of the address taken unless the function is virtual, which is handled elsewhere.
     rule <k> destruct(lv(_, _, t(... st: classType(_ :: Class(_, X::CId, _) #as C::Class)) #as T::CPPType) #as V::LVal, CanBeVirtual:Bool)
              => ExpressionStmt(BuiltinCallOp(lv(lnew(Base), noTrace, FuncT),
                   CanBeVirtual andBool isMethodVirtual(FuncT),
                   ListItem(getAddress(V))))
          ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... DestructorId(X) |-> (_::CPPType |-> (FuncT::CPPType, envEntry(... base: Base::SymBase))) ...</cenv>

     rule destruct(lv(_, _, T::CPPType), _) => .K
          requires notBool isCPPClassType(T)

endmodule
