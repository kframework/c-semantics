module C-DECL-INITIALIZER-SYNTAX
     syntax KResult ::= initializer(K)

     // Function id, param ids, body.
     syntax Value ::= functionObject(Id, List, K)

     // Id, type, initializer.
     syntax K ::= figureInit(Id, K, K) [strict(2)] 

     // These are also used by compound literals.
     syntax KResult ::= initValue(Id, Type, K)

     syntax K ::= allowWrite(K) [strict]
     syntax Type ::= initializerType(Type) [function]
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

     rule allowWrite(lval(N:SymLoc, T:Type))
          => lv(N, initializerType(T))
          [structural]

     rule initializerType(T:Type)
          => addStorage(Initializer, stripConst(T))

     rule figureInit(X:Id, T:Type, CodeLoc(K:K, L:K)) 
          => CodeLoc(.K, L) ~> figureInit(X, T, K) 
          [structural]

     rule figureInit(X:Id, T:Type, NoInit) 
          => initValue(X, T, .K)
          [structural]
     
     // aggregates
     rule figureInit(X:Id, T:Type, CompoundInit(L:K))
          => giveType(X, T)
          ~> figureInit-aux(X, T, startInit(T, X, CompoundInit(L)))
          when isAggregateType(T) orBool isUnionType(T)
          [structural] 

     rule figureInit(
               _, 
               t(_, arrayType(T:Type, Len:CSize)), 
               (SingleInit(stringLiteral(S:String))
               => CompoundInit(list(ListItem(InitFragment(NextInit,
                    SingleInit(stringLiteral(S)))))))
          )
          when isCharType(T) andBool (lengthString(S) <=Int Len)
          [structural]

     rule figureInit(
               _, 
               t(_, arrayType(T:Type, Len:CSize)), 
               (SingleInit(wstringLiteral(S:List)) 
               => CompoundInit(list(ListItem(InitFragment(NextInit,
                    SingleInit(wstringLiteral(S)))))))
          )
          when isWCharType(T) andBool (lengthList(S) <=Int Len)
          [structural] 
     
     rule figureInit(_, t(_, (incompleteArrayType(T:Type) 
          => arrayType(T, lengthString(S) +Int 1))),
               SingleInit(stringLiteral(S:String))) 
          when isCharType(T)
          [structural]

     rule figureInit(_, t(_, (incompleteArrayType(T:Type)
          => arrayType(T, lengthList(S) +Int 1))),
               SingleInit(wstringLiteral(S:List))) 
          when isWCharType(T)
          [structural] 
          
     rule figureInit(X:Id, t(Mods:Set, incompleteArrayType(T:Type)),
               CompoundInit(list(ListItem(InitFragment(NextInit,
               SingleInit(stringLiteral(S:String)))))))
          => figureInit(X, t(Mods, incompleteArrayType(T)),
               SingleInit(stringLiteral(S)))
          [structural] 
          
     // this comes from function declarations.  should probably adjust this
     rule figureInit(X:Id, T:Type, initializer(K:K))
          => figureInit-aux(X, T, initializer(K))
          [structural] 
     
     // base types
     rule figureInit(X:Id, T:Type, SingleInit(K:K))
          => figureInit-aux(X, T, 
               initializer(Computation(allowWrite(X) := K)))
          when notBool isArrayType(T)
          [structural] 
     // c1x 6.7.8:11
     rule figureInit(X:Id, T:Type,
               CompoundInit(list(ListItem(InitFragment(NextInit, SingleInit(K:K))))))
          => figureInit-aux(X, T,
               initializer(Computation(allowWrite(X) := K)))
          when notBool (isAggregateType(T) orBool isUnionType(T))
          [structural] 

     // id, type, initializer
     syntax K ::= "figureInit-aux" "(" Id "," Type "," K ")" [strict(3)]
     rule figureInit-aux(X:Id, T:Type, initializer(K:K))
          => initValue(X, T, K)
          when isCompleteType(T)
          [structural]
               
     rule <k> figureInit-aux(_:Id, t(_, 
                    (incompleteArrayType(T:Type) 
                    => arrayType(T, N))), initializer(_))
          ...</k>
          <incomplete-length> N:Int </incomplete-length>
          [structural] 
          
     syntax K ::= te(K, Type) [klabel('te)]
     syntax K ::= "getInit"
     syntax K ::= fillInit(K)
                | fillInits(List)
                | "fillInit-aux" "(" K ")"

     rule <k> getInit => initializer(K:K) ...</k>
          <saved-init> K:K => . </saved-init> 
          <curr-object> _:List => . </curr-object> 
          <curr-subobject> _:List => . </curr-subobject> 
          [structural] 

     syntax K ::= startInit(Type, Id, K)
     rule <k> startInit(T:Type, X:Id, CompoundInit(list(L:List)))
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
               => ListItem(te(K[0], T)) 
                    ListItem(te(K, t(Mods, arrayType(T, Len))))
          ...</curr-subobject>
          [structural] 
     rule <curr-subobject> 
               ListItem(te(K:K, t(Mods:Set, incompleteArrayType(T:Type))))
               => ListItem(te(K[0], T))
                    ListItem(te(K, t(Mods, incompleteArrayType(T))))
          ...</curr-subobject>
          [structural] 
     rule <curr-subobject> 
               (.List => ListItem(te(K . F, T)))
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(ListItem(typedDeclaration(T:Type, F:Id)) _, _, _)
               ))))
          ...</curr-subobject>
          [structural] 
          
     // fixme these are terrible!
     rule <curr-subobject> 
               (.List => ListItem(te(K . F, T)))
               ListItem(te(K:K, t(_, unionType(_, _,
                    fieldInfo(ListItem(typedDeclaration(T:Type, F:Id)) _, _, _) 
               ))))
          ...</curr-subobject>
          [structural] 
          
     // fixme should i worry about basetype here_
     rule <curr-subobject> 
               (next ListItem(te(K:K[N:Int], T:Type)) 
                    => ListItem(te(K[N +Int 1], T)))
               ListItem(te(K, t(_, arrayType(_, Len:Int))))
          ...</curr-subobject>
          when Len >Int N +Int 1
          [structural] 
     rule <curr-subobject>
               next (ListItem(te(K:K[N:Int], _:Type)) => .List)
                    ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</curr-subobject>
          when notBool Len >Int N +Int 1
          [structural] 
     
     rule <curr-subobject>
               (next ListItem(te(K:K[N:Int], T:Type)) 
                    => ListItem(te(K[N +Int 1], T))) 
               ListItem(te(K, t(_, incompleteArrayType(_))))
          ...</curr-subobject>
          [structural] 
     
     rule <curr-subobject>
               (next ListItem(te(K:K . F:Id, T:Type))
                    => ListItem(te(K . F', T')))
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(_ 
                         ListItem(typedDeclaration(T, F))
                         ListItem(typedDeclaration(T':Type, F':Id)) _, _, _)
               ))))
          ...</curr-subobject>
          when F' =/=K #NoName
          [structural, large] 
      
     rule <curr-subobject>
               (next ListItem(te(K:K . F:Id, T:Type)) 
                    => ListItem(te(K . F', T')))
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(_ 
                         ListItem(typedDeclaration(T, F))
                         ListItem(typedDeclaration(_, #NoName))
                         ListItem(typedDeclaration(T':Type, F':Id)) _, _, _)
               ))))
          ...</curr-subobject>
          [structural, large] 
          
     rule <curr-subobject>
               next (ListItem(te(K:K . F:Id, T:Type)) => .List)
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(_ ListItem(typedDeclaration(T, F)), _, _)
               ))))
          ...</curr-subobject>
          [structural, large] 
     rule <curr-subobject>
               next (ListItem(te(K:K . F:Id, T:Type)) => .List)
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo(_
                         ListItem(typedDeclaration(T, F))
                         ListItem(typedDeclaration(_, #NoName)), _, _)
               ))))
          ...</curr-subobject>
          [structural, large] 
          
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
               ~> finishCompoundInit(next ListItem(te(K, T)) Remainder)
          ...</k>
          <curr-subobject> 
               (_:List => .) 
               ListItem(te(K:K, T:Type)) 
               (Remainder:ListItem => .)
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
     syntax K ::= buildDesignator(K)
     
     // note that these clear the current subobject cell, because it will be
     // repopulated when building the designator
     rule <k> fillInit(InitFragment(InFieldInit(F:Id, K':K), Exp:K))
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
     
     rule <k> buildDesignator(InFieldInit(F:Id, More:K)) 
               => buildDesignator(More)
          ...</k>
          <curr-subobject> 
               block (.List => ListItem(te(K . F, T)))
                    ListItem('te(K:K,, 't(_,, Lbl:KLabel(S:Id,, _))))
          ...</curr-subobject>
          <structs>... 
               S |-> fieldInfo(_, (_ F:Id |-> T:Type), _)
          ...</structs>
          when Lbl ==KLabel 'structType orBool Lbl ==KLabel 'unionType
          [structural] 
          
     rule <k> buildDesignator(NextInit) => NextInit ...</k>
          <curr-subobject> (block => .List) ...</curr-subobject>
          [structural] 

     context buildDesignator(AtIndexInit((HOLE => reval(HOLE)), _)) 
     rule <k> buildDesignator(AtIndexInit(tv(N:Int, _), More:K)) 
               => buildDesignator(More)
          ...</k>
          <curr-subobject> 
               block (.List => ListItem(te(K[N], innerType(T))))
                    ListItem(te(K:K, T:Type)) 
          ...</curr-subobject>
          when isArrayType(T)
          [structural] 
     
     syntax K ::= "popInit"
     
     syntax Int ::= getTopArrayUse(K) [function]
     rule getTopArrayUse(_:Id) => 0
     // +1 for length instead of index
     rule getTopArrayUse(_:Id[N:Int]) => N +Int 1
     rule getTopArrayUse(K:K . _:Id) => getTopArrayUse(K)
     rule getTopArrayUse((K:K[N:Int])[_]) => getTopArrayUse(K[N])
     rule getTopArrayUse((K:K . _:Id)[_]) => getTopArrayUse(K)
     
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
               . => Computation(allowWrite(K) := K') ~> possiblyMakeConst(T, K)
          </saved-init>
          when (isBasicType(T) 
                    orBool isPointerType(T) 
                    orBool isBitfieldType(T))
               andBool notBool isStructType(T')
               andBool notBool isUnionType(T')
          [structural]
     
     syntax K ::= possiblyMakeConst(Type, K)
     
     rule possiblyMakeConst(T:Type, K:K) => makeUnwritableSubObject(K)
          when isConstType(T)
          [structural]
     rule possiblyMakeConst(T:Type, _) => .
          when notBool isConstType(T)
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
     rule <k> initFromAggregateRHS(K:K, t(S:Set, structType(X:Id, NBits:Int, Info:FieldInfo)))
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
     rule <k> initFromStructRHS(K':K, t(_, structType(S:Id, _, _))) => . ...</k>
          <curr-subobject> 
               findStruct(t(_, structType(S:Id, _, _)))
                    ListItem(te(K:K, t(_, structType(S:Id, _, _)))) => next 
          ...</curr-subobject>
          <incomplete-length>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incomplete-length>
          <saved-init>...
               .K => Computation(allowWrite(K) := K')
          </saved-init> 
          [structural, large] 
     
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
          when isCharType(T) andBool lengthString(S) ==Int Len
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
          when isCharType(T) andBool lengthString(S) <Int Len
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
          when isCharType(T)
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
          when (S =/=String "") andBool isCharType(T)
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
          when notBool isCharType(T)
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
