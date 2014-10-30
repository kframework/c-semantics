module C-DECL-INITIALIZER-SYNTAX
     syntax KResult ::= initializer(K)

     // Function id, param ids, prototype, body.
     syntax RValue ::= functionObject(CId, List, Type, K)

     // CId, type, initializer.
     syntax K ::= figureInit(CId, K, K) [strict(2)]

     // These are also used by compound literals.
     syntax KResult ::= initValue(CId, Type, K)

     syntax K ::= singleIntInit(K) [strict]

     syntax K ::= allowInit(K)
endmodule

module C-DECL-INITIALIZER
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-ZERO-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-LITERAL-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> allowInit(K:K) => K ~> initDone ... </k>
          <initializing> I:Int => I +Int 1 </initializing>
          [structural]

     syntax K ::= "initDone"
     rule <k> R:KResult ~> initDone => R ...</k>
          <initializing> I:Int => I -Int 1 </initializing>
          [structural]
     rule <k> initDone => . ...</k>
          <initializing> I:Int => I -Int 1 </initializing>
          [structural]

     rule figureInit(X:CId, T:Type, CodeLoc(K:K, L:K))
          => CodeLoc(.K, L) ~> figureInit(X, T, K)
          [structural]

     rule figureInit(X:CId, T:Type, NoInit)
          => initValue(X, T, .K)
          [structural]

     // aggregates
     rule figureInit(X:CId, T:Type, CompoundInit(L:K))
          => giveType(X, T)
          ~> figureInit-aux(X, T, startInit(T, X, CompoundInit(L)))
          when isAggregateType(T) orBool isUnionType(T)
          [structural]

     rule figureInit(
               _,
               t(_, arrayType(T:Type, Len:Int)),
               (SingleInit(stringLiteral(S:String))
               => CompoundInit(list(ListItem(InitFragment(NextInit,
                    SingleInit(stringLiteral(S)))))))
          )
          when hasCharType(T) andBool (lengthString(S) <=Int Len)
          [structural]

     rule figureInit(
               _,
               t(_, arrayType(T:Type, Len:Int)),
               (SingleInit(wstringLiteral(S:List))
               => CompoundInit(list(ListItem(InitFragment(NextInit,
                    SingleInit(wstringLiteral(S)))))))
          )
          when isWCharType(T) andBool (lengthList(S) <=Int Len)
          [structural]

     rule figureInit(_, t(_, (incompleteArrayType(T:Type)
          => arrayType(T, lengthString(S) +Int 1))),
               SingleInit(stringLiteral(S:String)))
          when hasCharType(T)
          [structural]

     rule figureInit(_, t(_, (incompleteArrayType(T:Type)
          => arrayType(T, lengthList(S) +Int 1))),
               SingleInit(wstringLiteral(S:List)))
          when isWCharType(T)
          [structural]

     rule figureInit(X:CId, t(Mods:Set, incompleteArrayType(T:Type)),
               CompoundInit(list(ListItem(InitFragment(NextInit,
               SingleInit(stringLiteral(S:String)))))))
          => figureInit(X, t(Mods, incompleteArrayType(T)),
               SingleInit(stringLiteral(S)))
          [structural]

     // this comes from function declarations.  should probably adjust this
     rule figureInit(X:CId, T:Type, initializer(K:K))
          => figureInit-aux(X, T, initializer(K))
          [structural]

     // base types
     rule figureInit(X:CId, T:Type, SingleInit(K:K))
          => figureInit-aux(X, T,
               initializer(Computation(X := K)))
          when notBool isArrayType(T)
          [structural]
     // c1x 6.7.8:11
     rule figureInit(X:CId, T:Type,
               CompoundInit(list(ListItem(InitFragment(NextInit, SingleInit(K:K))))))
          => figureInit-aux(X, T,
               initializer(Computation(X := K)))
          when notBool (isAggregateType(T) orBool isUnionType(T))
          [structural]

     // id, type, initializer
     syntax K ::= "figureInit-aux" "(" CId "," Type "," K ")" [strict(3)]
     rule figureInit-aux(X:CId, T:Type, initializer(K:K))
          => initValue(X, T, K)
          when isCompleteType(T)
          [structural]

     rule <k> figureInit-aux(_:CId, t(_,
                    (incompleteArrayType(T:Type)
                    => arrayType(T, N))), initializer(_))
          ...</k>
          <incomplete-length> N:Int </incomplete-length>
          [structural]

     syntax K ::= te(K, Type) [klabel('te)]

     // Special array designator syntax so that it doesn't get caught by the
     // X[Y] => *(X + Y) macro.
     syntax K ::= K "[[" Int "]]"
     rule K:K [[ N:Int ]] => K[N]

     syntax K ::= "getInit"
     syntax K ::= fillInit(K)
                | fillInits(List)
                | "fillInit-aux" "(" K ")"

     rule <k> getInit => initializer(K:K) ...</k>
          <saved-init> K:K => . </saved-init>
          <curr-object> _:List => . </curr-object>
          <curr-subobject> _:List => . </curr-subobject>
          [structural]

     syntax K ::= startInit(Type, CId, K)
     rule <k> startInit(T:Type, X:CId, CompoundInit(list(L:List)))
               => fillInits(L) ~> getInit
          ...</k>
          <incomplete-length> _ => 0 </incomplete-length>
          <curr-subobject>
               .List => ListItem(te(X, T))
          </curr-subobject>
          <curr-object>
               .List => ListItem(te(X, T))
          </curr-object>
          <saved-init>... .K => zero(X) </saved-init>
          when isUnionType(T) orBool isAggregateType(T)
          [structural]

     rule fillInits(ListItem(InitFragment(K:K, Exp:K)) L:List)
          => fillInit(InitFragment(K, Exp)) ~> fillInits(L)
          [structural]
     rule fillInits(.List) => .K
          [structural]

     syntax ListItem ::= "next"
     syntax ListItem ::= "block"

     rule <curr-subobject>
               ListItem(te(K:K, t(Mods:Set, arrayType(T:Type, Len:CSize))))
               => ListItem(te(K[[0]], T))
                    ListItem(te(K, t(Mods, arrayType(T, Len))))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               ListItem(te(K:K, t(Mods:Set, incompleteArrayType(T:Type))))
               => ListItem(te(K[[0]], T))
                    ListItem(te(K, t(Mods, incompleteArrayType(T))))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (.List => ListItem(te(K . F, T)))
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(ListItem(typedDeclaration(T:Type, F:CId)) _, _, _)
               ))))
          ...</curr-subobject>
          [structural]

     // fixme these are terrible!
     rule <curr-subobject>
               (.List => ListItem(te(K . F, T)))
               ListItem(te(K:K, t(_, unionType(_, _,
                    fieldInfo(ListItem(typedDeclaration(T:Type, F:CId)) _, _, _)
               ))))
          ...</curr-subobject>
          [structural]

     // fixme should i worry about basetype here_
     rule <curr-subobject>
               (next ListItem(te(K:K[[N:Int]], T:Type))
                    => ListItem(te(K[[N +Int 1]], T)))
               ListItem(te(K, t(_, arrayType(_, Len:Int))))
          ...</curr-subobject>
          when Len >Int N +Int 1
          [structural]
     rule <curr-subobject>
               next (ListItem(te(K:K[[N:Int]], _:Type)) => .List)
                    ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</curr-subobject>
          when notBool Len >Int N +Int 1
          [structural]

     rule <curr-subobject>
               (next ListItem(te(K:K[[N:Int]], T:Type))
                    => ListItem(te(K[[N +Int 1]], T)))
               ListItem(te(K, t(_, incompleteArrayType(_))))
          ...</curr-subobject>
          [structural]

     rule <curr-subobject>
               (next ListItem(te(K:K . F:CId, T:Type))
                    => ListItem(te(K . F', T')))
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(_
                         ListItem(typedDeclaration(T, F))
                         ListItem(typedDeclaration(T':Type, F':CId)) _, _, _)
               ))))
          ...</curr-subobject>
          when F' =/=K #NoName
          [structural]

     rule <curr-subobject>
               (next ListItem(te(K:K . F:CId, T:Type))
                    => ListItem(te(K . F', T')))
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(_
                         ListItem(typedDeclaration(T, F))
                         ListItem(typedDeclaration(_, #NoName))
                         ListItem(typedDeclaration(T':Type, F':CId)) _, _, _)
               ))))
          ...</curr-subobject>
          [structural]

     rule <curr-subobject>
               next (ListItem(te(K:K . F:CId, T:Type)) => .List)
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(_ ListItem(typedDeclaration(T, F)), _, _)
               ))))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               next (ListItem(te(K:K . F:CId, T:Type)) => .List)
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(_
                         ListItem(typedDeclaration(T, F))
                         ListItem(typedDeclaration(_, #NoName)), _, _)
               ))))
          ...</curr-subobject>
          [structural]

     rule <curr-subobject>
               next (ListItem(te(K:K . _, _)) => .List)
               ListItem(te(K:K, t(_, unionType(_, _, _))))
          ...</curr-subobject>
          [structural]

     rule fillInit(InitFragment(NextInit, Exp:K)) => fillInit(Exp)
          [structural]

     syntax K ::= finishCompoundInit(List)
     rule <k> fillInit(CompoundInit(list(L:List)))
               => fillInits(L)
               ~> finishCompoundInit(next ListItem(te(K, T)) ListItem(Remainder))
          ...</k>
          <curr-subobject>
               (_:List => .)
               ListItem(te(K:K, T:Type))
               (ListItem(Remainder:K) => .)
          </curr-subobject>
          <curr-object>
               (. => ListItem(te(K, T)))
          ...</curr-object>
          when isAggregateType(T) orBool isUnionType(T)
          [structural]
     rule <k> finishCompoundInit(L:List) => . ...</k>
          <curr-object>
               (ListItem(te(_:K, _:Type)) => .)
          ...</curr-object>
          <curr-subobject> (_ => L) </curr-subobject>
          [structural]

     context fillInit(InitFragment(HOLE, _))

     // note that these clear the current subobject cell, because it will be
     // repopulated when building the designator
     rule <k> fillInit(InitFragment(InFieldInit(F:CId, K':K), Exp:K))
               => fillInit(InitFragment(buildDesignator(
                    InFieldInit(F, K')), Exp))
          ...</k>
          <curr-object> ListItem(te(K:K, T:Type)) ...</curr-object>
          <curr-subobject>
               _:List => block ListItem(te(K, T))
          </curr-subobject>
          when isStructType(T) orBool isUnionType(T)
          [structural]
     // fixme does this need to worry about incompleteLength_
     rule <k> fillInit(InitFragment(AtIndexInit(Index:K, K':K), Exp:K))
               => fillInit(InitFragment(
                    buildDesignator(AtIndexInit(Index, K')), Exp))
          ...</k>
          <curr-object> ListItem(te(K:K, T:Type)) ...</curr-object>
          <curr-subobject>
               _:List => block ListItem(te(K, T))
          </curr-subobject>
          when isArrayType(T)
          [structural]

     syntax K ::= buildDesignator(K)
     rule <k> buildDesignator(InFieldInit(F:CId, More:K))
               => buildDesignator(More)
          ...</k>
          <curr-subobject>
               block (.List => ListItem(te(K . F, T)))
                    ListItem('te(K:K,, 't(_,, Lbl:KLabel(S:CId,, _))))
          ...</curr-subobject>
          <structs>...
               S |-> fieldInfo(_, (_ F:CId |-> T:Type), _)
          ...</structs>
          when Lbl ==KLabel 'structType orBool Lbl ==KLabel 'unionType
          [structural]

     rule <k> buildDesignator(NextInit) => NextInit ...</k>
          <curr-subobject> (block => .List) ...</curr-subobject>
          [structural]

     context buildDesignator(AtIndexInit(HOLE => reval'(HOLE), _))
     rule <k> buildDesignator(AtIndexInit(tv(N:Int, _), More:K))
               => buildDesignator(More)
          ...</k>
          <curr-subobject>
               block (.List => ListItem(te(K[[N]], innerType(T))))
                    ListItem(te(K:K, T:Type))
          ...</curr-subobject>
          when isArrayType(T)
          [structural]

     syntax K ::= "popInit"

     syntax Int ::= getTopArrayUse(K) [function]
     rule getTopArrayUse(_:CId) => 0
     // +1 for length instead of index
     rule getTopArrayUse(_:CId[[N:Int]]) => N +Int 1
     rule getTopArrayUse(K:K . _:CId) => getTopArrayUse(K)
     rule getTopArrayUse((K:K[[N:Int]])[[_]]) => getTopArrayUse(K[[N]])
     rule getTopArrayUse((K:K . _:CId)[[_]]) => getTopArrayUse(K)

     syntax K ::= initializeSingleInit(K)

     rule (. => typeof(K)) ~> initializeSingleInit(K:K)
          [structural]

     // fixme want to exclude strings, but not normal arrays
     rule <k> T':Type ~> initializeSingleInit(K':K) => . ...</k>
          <curr-subobject>
               (.List => next) ListItem(te(K:K, T:Type))
          ...</curr-subobject>
          <incomplete-length>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incomplete-length>
          <saved-init>...
               . => Computation(K := K')
          </saved-init>
          when (isBasicType(T)
                    orBool isPointerType(T)
                    orBool isBitfieldType(T))
               andBool notBool isStructType(T')
               andBool notBool isUnionType(T')
          [structural]

     // this is used to have an aggregate on the RHS of a compound init
     // fixme want to exclude strings, but not normal arrays
     syntax K ::= initFromAggregateRHS(K, Type)
     rule T:Type ~> initializeSingleInit(K:K)
          => initFromAggregateRHS(K, T)
          when isStructType(T)
               orBool isUnionType(T)
          [structural]

     syntax K ::= initFromStructRHS(K, Type)
     rule <k> initFromAggregateRHS(K:K, t(S:Set, structType(X:CId, NBits:Int, Info:FieldInfo)))
               => initFromStructRHS(K, t(S, structType(X, NBits, Info)))
          ...</k>
          <curr-subobject>
               .List => findStruct(t(S, structType(X, NBits, Info)))
          ...</curr-subobject>
          [structural]

     syntax ListItem ::= findStruct(Type)

     rule <curr-subobject>
               findStruct(T:Type) (ListItem(te(_, T':Type)) => .List)
          ...</curr-subobject>
          when T =/=K T'
          [structural]

     // fixme unsafe, might have started to initialize other things
     rule <k> initFromStructRHS(K':K, t(_, structType(S:CId, _, _))) => . ...</k>
          <curr-subobject>
               findStruct(t(_, structType(S:CId, _, _)))
                    ListItem(te(K:K, t(_, structType(S:CId, _, _)))) => next
          ...</curr-subobject>
          <incomplete-length>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incomplete-length>
          <saved-init>...
               .K => Computation(K := K')
          </saved-init>
          [structural]

     rule fillInit(SingleInit(K:K)) => initializeSingleInit(K)
          when getKLabel(K) =/=KLabel 'stringLiteral
               andBool getKLabel(K) =/=KLabel 'wstringLiteral
          [structural]

     rule <k> fillInit(SingleInit(stringLiteral(S:String)))
               => fillInit-aux(SingleInit(stringLiteral(S)))
          ...</k>
          <curr-subobject>
               ListItem(te(_:K, T:Type))
               ListItem(te(_, t(_, arrayType(T:Type, Len:Int))))
          ...</curr-subobject>
          when hasCharType(T) andBool lengthString(S) ==Int Len
          [structural]
     rule <k> fillInit(SingleInit(wstringLiteral(S:List)))
               => fillInit-aux(SingleInit(wstringLiteral(S)))
          ...</k>
          <curr-subobject>
               ListItem(te(_:K, T:Type))
               ListItem(te(_, t(_, arrayType(T:Type, Len:Int))))
          ...</curr-subobject>
          when isWCharType(T) andBool lengthList(S) ==Int Len
          [structural]
     rule <k> fillInit(SingleInit(stringLiteral(S:String)))
               => fillInit(SingleInit(stringLiteral(S +String "\x00")))
          ...</k>
          <curr-subobject>
               ListItem(te(_:K, T:Type))
               ListItem(te(_, t(_, arrayType(T:Type, Len:Int))))
          ...</curr-subobject>
          when hasCharType(T) andBool lengthString(S) <Int Len
          [structural]
     rule <k> fillInit(SingleInit(wstringLiteral(S:List)))
               => fillInit(SingleInit(wstringLiteral(S ListItem(0))))
          ...</k>
          <curr-subobject>
               ListItem(te(_:K, T:Type))
                    ListItem(te(_, t(_, arrayType(T:Type, Len:Int))))
          ...</curr-subobject>
          when isWCharType(T) andBool lengthList(S) <Int Len
          [structural]
     rule <k> fillInit(SingleInit(stringLiteral(S:String)))
               => fillInit-aux(SingleInit(stringLiteral(S +String "\x00")))
          ...</k>
          <curr-subobject>
               ListItem(te(_:K, T:Type))
               ListItem(te(_, t(_, incompleteArrayType(T:Type))))
          ...</curr-subobject>
          when hasCharType(T)
          [structural]
     rule <k> fillInit(SingleInit(wstringLiteral(S:List)))
               => fillInit-aux(SingleInit(
                    wstringLiteral(S ListItem(0))))
          ...</k>
          <curr-subobject>
               ListItem(te(_:K, T:Type))
               ListItem(te(_, t(_, incompleteArrayType(T:Type))))
          ...</curr-subobject>
          when isWCharType(T)
          [structural]
     rule <k> fillInit-aux(SingleInit(stringLiteral(S:String)))
               => fillInit(initHead(S))
               ~> fillInit-aux(initTail(S))
          ...</k>
          <curr-subobject> ListItem(te(_, T:Type)) ...</curr-subobject>
          when (S =/=String "") andBool hasCharType(T)
          [structural]

     syntax K ::= initHead(String) [function]
     syntax K ::= initTail(String) [function]
     rule initHead(S:String)
          => SingleInit(tv(ordChar(firstChar(S)), t(.Set, char)))
     rule initTail(S:String)
          => SingleInit(stringLiteral(butFirstChar(S)))

     rule <k> fillInit-aux(SingleInit(wstringLiteral(ListItem(N:Int) S:List)))
               => fillInit(SingleInit(tv(N, cfg:wcharut)))
                    ~> fillInit-aux(SingleInit(wstringLiteral(S)))
          ...</k>
          <curr-subobject>
               ListItem(te(_, T:Type))
          ...</curr-subobject>
          when isWCharType(T)
          [structural]
     // fixme not sure what happens in the case of   char *x = "";
     rule fillInit-aux(SingleInit(stringLiteral(""))) => .
          [structural]
     rule fillInit-aux(SingleInit(wstringLiteral(.List))) => .
          [structural]

     // This rule assumes all unrollings have already occurred, so it needs to
     // be a rule. Alternatively, I've added the condition below which might be
     // enough.
     rule <k> fillInit(SingleInit(stringLiteral(S:String)))
               => initializeSingleInit(stringLiteral(S))
          ...</k>
          <curr-subobject>
               ListItem(te(_, T:Type))
          ...</curr-subobject>
          when notBool hasCharType(T)
               andBool (isBasicType(T) orBool isPointerType(T)
                    orBool isBitfieldType(T))
          [structural]
     rule <k> fillInit(SingleInit(wstringLiteral(S:List)))
               => initializeSingleInit(wstringLiteral(S))
          ...</k>
          <curr-subobject>
               ListItem(te(_, T:Type))
          ...</curr-subobject>
          when notBool isWCharType(T)
               andBool (isBasicType(T) orBool isPointerType(T)
                    orBool isBitfieldType(T))
          [structural]

endmodule
