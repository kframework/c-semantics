module C-DECLARATION-INITIALIZATION-SYNTAX
     syntax K ::= "startInit" "(" Type "," Id "," K ")"
endmodule

module C-DECLARATION-INITIALIZATION
     imports C-DECLARATION-INITIALIZATION-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX
     imports C-DECLARATION-SYNTAX

     imports C-MEMORY-ALLOC-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX
     
     syntax K ::= "te" "(" K "," Type ")" [klabel('te)]
     syntax K ::= "getInit"
     syntax K ::= "fillInit" "(" K ")"
                | "fillInits" "(" KList ")"
                | "fillInit-aux" "(" K ")"

     rule <k> getInit => initializer(K:K) ...</k>
          <savedInitialization> K:K => . </savedInitialization> 
          <currentObject> _:List => . </currentObject> 
          <currentSubObject> _:List => . </currentSubObject> 
          [structural] 

     rule <k> 
               startInit(T:Type, X:Id, CompoundInit(klist(L:KList)))
               => fillInits(L) ~> getInit
          ...</k>
          <incompleteLength> _ => 0 </incompleteLength>
          <currentSubObject>
               .List => ListItem(te(X, T))
          </currentSubObject>
          <currentObject>
               .List => ListItem(te(X, T))
          </currentObject>
          <savedInitialization>... .K => zero(X) </savedInitialization> 
          when isUnionType(T) orBool isAggregateType(T)
          [structural] 
     
     rule fillInits((InitFragment(K:K, Exp:K),, L:KList))
          => fillInit(InitFragment(K, Exp)) ~> fillInits(L)
          [structural] 
     rule fillInits(.KList) => .
          [structural] 
     
     syntax ListItem ::= "next"
     syntax ListItem ::= "block"
     
     rule <currentSubObject> 
               ListItem(te(K:K, t(S:Set, arrayType(T:Type, Len:Int))))
               => ListItem(te(K[0], T)) 
                    ListItem(te(K, t(S, arrayType(T, Len))))
          ...</currentSubObject>
          [structural] 
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, incompleteArrayType(T:Type))))
               => ListItem(te(K[0], T))
                    ListItem(te(K, t(Se, incompleteArrayType(T))))
          ...</currentSubObject>
          [structural] 
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K . F, T)) 
                    ListItem(te(K, t(Se, structType(S))))
          ...</currentSubObject>
          <structs>... 
               S |-> aggregateInfo((typedDeclaration(T:Type, F:Id),, _), _, _)
          ...</structs> 
          [structural] 
          
     // fixme these are terrible!
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, unionType(S:Id))))
               => ListItem(te(K . F, T))
                    ListItem(te(K, t(Se, unionType(S))))
          ...</currentSubObject>
          <structs>... 
               S |-> aggregateInfo((typedDeclaration(T:Type, F:Id),, _), _, _) 
          ...</structs> 
          [structural] 
          
     // fixme should i worry about basetype here_
     rule [init-next-array-element]:
          <currentSubObject> 
               (next ListItem(te(K:K[N:Int], T:Type)) 
                    => ListItem(te(K[N +Int 1], T)))
               ListItem(te(K, t(_, arrayType(_, Len:Int))))
          ...</currentSubObject>
          when Len >Int N +Int 1
          [structural] 
     rule [init-next-array-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K[N:Int], _:Type)) => .List)
                    ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</currentSubObject>
          when notBool Len >Int N +Int 1
          [structural] 
     
     rule [init-next-incomplete-array-element]:
          <currentSubObject>
               (next ListItem(te(K:K[N:Int], T:Type)) 
                    => ListItem(te(K[N +Int 1], T))) 
               ListItem(te(K, t(_, incompleteArrayType(_))))
          ...</currentSubObject>
          [structural] 
     
     rule [init-next-struct-element]:
          <currentSubObject>
               next ListItem(te(K:K . F:Id, T:Type))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K . F', T'))
                    ListItem(te(K, t(Se, structType(S))))
          ...</currentSubObject>
          <structs>...
               S |-> aggregateInfo((_,, typedDeclaration(T, F),,
                    typedDeclaration(T':Type, F':Id),, _), _, _)
          ...</structs> 
          when F' =/=K #NoName
          [structural, large] 
      
     rule [init-next-struct-element-noname]:
          <currentSubObject>
               next ListItem(te(K:K . F:Id, T:Type))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K . F', T'))
                    ListItem(te(K, t(Se, structType(S))))
          ...</currentSubObject>
          <structs>...
               S |-> aggregateInfo((_,, typedDeclaration(T, F),,
                    typedDeclaration(_, #NoName),,
                    typedDeclaration(T':Type, F':Id),, _), _, _)
          ...</structs>
          [structural, large] 
          
     rule [init-next-struct-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K . F:Id, T:Type)) => .)
                    ListItem(te(K:K, t(_, structType(S:Id))))
          ...</currentSubObject>
          <structs>...
               S |-> aggregateInfo((_,, typedDeclaration(T, F)), _, _)
          ...</structs> 
          [structural, large] 
     rule [init-next-struct-element-done-noname]:
          <currentSubObject>
               next (ListItem(te(K:K . F:Id, T:Type)) => .)
                    ListItem(te(K:K, t(_, structType(S:Id))))
          ...</currentSubObject>
          <structs>...
               S |-> aggregateInfo((_,, 
                    typedDeclaration(T, F),,
                    typedDeclaration(_, #NoName)), _, _)
          ...</structs> 
          [structural, large] 
          
     rule [init-next-union-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K . _:Id, _:Type)) => .List)
                    ListItem(te(K:K, t(_, unionType(_:Id))))
          ...</currentSubObject>
          [structural] 
          
     rule fillInit(InitFragment(NextInit, Exp:K)) => fillInit(Exp) 
          [structural] 
          
     syntax K ::= "finishCompoundInit" "(" List ")"
     rule <k> 
               fillInit(CompoundInit(klist(L:KList)))
               => fillInits(L)
                    ~> finishCompoundInit(next ListItem(te(K, T)) Remainder)
          ...</k>
          <currentSubObject> 
               (_:List => .) 
               ListItem(te(K:K, T:Type)) 
               (Remainder:ListItem => .)
          </currentSubObject>
          <currentObject>
               (. => ListItem(te(K, T)))
          ...</currentObject>
          when isAggregateType(T) orBool isUnionType(T)
          [structural]
     rule <k> finishCompoundInit(L:List) => . ...</k>
          <currentObject>
               (ListItem(te(_:K, _:Type)) => .)
          ...</currentObject>
          <currentSubObject> (_ => L) </currentSubObject>
          [structural] 

     context fillInit(InitFragment(HOLE, _)) 
     syntax K ::= "buildDesignator" "(" K ")"
     
     // note that these clear the current subobject cell, because it will be
     // repopulated when building the designator
     rule <k> 
               fillInit(InitFragment(InFieldInit(F:Id, K':K), Exp:K))
               => fillInit(InitFragment(buildDesignator(
                    InFieldInit(F, K')), Exp))
          ...</k>
          <currentObject> ListItem(te(K:K, T:Type)) ...</currentObject>
          <currentSubObject>
               _:List => block ListItem(te(K, T))
          </currentSubObject>
          when isStructType(T) orBool isUnionType(T)
          [structural] 
     // fixme does this need to worry about incompleteLength_
     rule <k> 
               fillInit(InitFragment(AtIndexInit(Index:K, K':K), Exp:K))
               => fillInit(InitFragment(
                    buildDesignator(AtIndexInit(Index, K')), Exp))
          ...</k>
          <currentObject> ListItem(te(K:K, T:Type)) ...</currentObject>
          <currentSubObject>
               _:List => block ListItem(te(K, T))
          </currentSubObject>
          when isArrayType(T)
          [structural] 
     
     // fixme these are also too restrictive on type.  if we try to assign an
     // int to a long-int field, it will fail
     // i don't think this is true anymore
     rule <k> 
               buildDesignator(InFieldInit(F:Id, More:K)) 
               => buildDesignator(More)
          ...</k>
          <currentSubObject> 
               block (.List => ListItem(te(K . F, T)))
                    ListItem('te(K:K,, 't(_,, Lbl:KLabel(S:Id))))
          ...</currentSubObject>
          <structs>... 
               S |-> aggregateInfo(_, (_ F:Id |-> T:Type), _)
          ...</structs>
          when Lbl ==KLabel 'structType orBool Lbl ==KLabel 'unionType
          [structural] 
          
     rule <k> buildDesignator(NextInit) => NextInit ...</k>
          <currentSubObject> (block => .List) ...</currentSubObject>
          [structural] 
          
     rule [innerType-arrayType]:
          innerType(t(_, arrayType(T:Type, _:Int))) => T
     rule [innerType-incompleteArrayType]: 
          innerType(t(_, incompleteArrayType(T:Type))) => T
     rule [innerType-flexibleArrayType]: 
          innerType(t(_, flexibleArrayType(T:Type))) => T
     rule [innerType-qualifiedType]:
          innerType(t(_, qualifiedType(T:Type, _))) => innerType(T)
     rule [innerType-pointerType]:
          innerType(t(_, pointerType(T:Type))) => T
     rule [innerType-bitfieldType]:
          innerType(t(_, bitfieldType(T:Type, _:Int))) => T
     rule [innerType-functionType]:
          innerType(t(_, functionType(T:Type, _:KList))) => T

     context buildDesignator(AtIndexInit((HOLE => reval(HOLE)), _)) 
     rule <k> buildDesignator(AtIndexInit(tv(N:Int, _), More:K)) 
               => buildDesignator(More)
          ...</k>
          <currentSubObject> 
               block (.List => ListItem(te(K[N], innerType(T))))
                    ListItem(te(K:K, T:Type)) 
          ...</currentSubObject>
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
     
     syntax K ::= "initializeSingleInit" "(" K ")"
          
     rule (. => typeof(K)) ~> initializeSingleInit(K:K)
          [structural] 
     
     // fixme want to exclude strings, but not normal arrays
     rule <k> T':Type ~> initializeSingleInit(K':K) => . ...</k>
          <currentSubObject>
               (.List => next) ListItem(te(K:K, T:Type))
          ...</currentSubObject>
          <incompleteLength>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incompleteLength>
          <savedInitialization>... 
               . => Computation(allowWrite(K) := K') ~> possiblyMakeConst(T, K)
          </savedInitialization>
          when (isBasicType(T) 
                    orBool isPointerType(T) 
                    orBool isBitfieldType(T))
               andBool (notBool isStructType(T'))
               andBool (notBool isUnionType(T'))
          [structural]
     
     syntax K ::= "possiblyMakeConst" "(" Type "," K ")"
     
     rule possiblyMakeConst(T:Type, K:K) => makeUnwritableSubObject(K)
          when isConstType(T)
          [structural]
     rule possiblyMakeConst(T:Type, _) => .
          when notBool isConstType(T)
          [structural]
          
     // this is used to have an aggregate on the RHS of a compound init
     // fixme want to exclude strings, but not normal arrays
     syntax K ::= "initFromAggregateRHS" "(" K "," Type ")"
     rule T:Type ~> initializeSingleInit(K:K) 
          => initFromAggregateRHS(K, T)
          when isStructType(T)
               orBool isUnionType(T)
          [structural] 
          
     syntax K ::= "initFromStructRHS" "(" K "," Type ")"
     rule <k> initFromAggregateRHS(K:K, t(S:Set, structType(I:Id)))
               => initFromStructRHS(K, t(S, structType(I)))
          ...</k>
          <currentSubObject>
               .List => findStruct(t(S, structType(I)))
          ...</currentSubObject>
          [structural] 
          
     syntax ListItem ::= "findStruct" "(" Type ")"
          
     rule <currentSubObject>
               findStruct(T:Type) (ListItem(te(_, T':Type)) => .List)
          ...</currentSubObject>
          when T =/=K T'
          [structural] 
          
     // fixme unsafe, might have started to initialize other things
     rule <k> initFromStructRHS(K':K, t(_, structType(S:Id))) => . ...</k>
          <currentSubObject> 
               findStruct(t(_, structType(S:Id)))
                    ListItem(te(K:K, t(_, structType(S:Id)))) => next 
          ...</currentSubObject>
          <incompleteLength>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incompleteLength>
          <savedInitialization>...
               .K => Computation(allowWrite(K) := K')
          </savedInitialization> 
          [structural, large] 
     
     rule fillInit(SingleInit(K:K)) => initializeSingleInit(K)
          when getKLabel(K) =/=KLabel 'Constant
          [structural] 

     rule [fillInit-string-array-eq]:
          <k> 
               fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit-aux(SingleInit(Constant(StringLiteral(S))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:Type)) 
               ListItem(te(_, t(_, arrayType(T:Type, Len:Int))))
          ...</currentSubObject>
          when isCharType(T) andBool lengthString(S) ==Int Len
          [structural] 
     rule [fillInit-wstring-array-eq]:
          <k> 
               fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit-aux(SingleInit(Constant(WStringLiteral(S))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:Type))
               ListItem(te(_, t(_, arrayType(T:Type, Len:Int))))
          ...</currentSubObject>
          when isWCharType(T) andBool lengthKList S ==Int Len
          [structural] 
     rule [fillInit-string-array-lt]:
          <k> 
               fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit(SingleInit(Constant(
                    StringLiteral(S +String "\x00"))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:Type))
               ListItem(te(_, t(_, arrayType(T:Type, Len:Int))))
          ...</currentSubObject>
          when isCharType(T) andBool lengthString(S) <Int Len
          [structural] 
     rule [fillInit-wstring-array-lt]:
          <k> 
               fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit(SingleInit(Constant(WStringLiteral((S,, 0)))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:Type))
                    ListItem(te(_, t(_, arrayType(T:Type, Len:Int))))
          ...</currentSubObject>
          when isWCharType(T) andBool lengthKList S <Int Len
          [structural] 
     rule [fillInit-string-char]:
          <k> 
               fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit-aux(SingleInit(Constant(
                    StringLiteral(S +String "\x00"))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:Type))
               ListItem(te(_, t(_, incompleteArrayType(T:Type))))
          ...</currentSubObject>
          when isCharType(T)
          [structural] 
     rule [fillInit-wstring-wchar]:
          <k> 
               fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit-aux(SingleInit(Constant(WStringLiteral((S,, 0)))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:Type)) 
               ListItem(te(_, t(_, incompleteArrayType(T:Type))))
          ...</currentSubObject>
          when isWCharType(T)
          [structural]
     rule [fillInitAux-string-some]:
          <k> 
               fillInit-aux(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit(initHead(S, T)) ~> fillInit-aux(initTail(S))
          ...</k>
          <currentSubObject> ListItem(te(_:K, T:Type)) ...</currentSubObject>
          when S =/=String "" andBool isCharType(T)
          [structural]
          
     syntax K ::= "initHead" "(" String "," Type ")"
     syntax K ::= "initTail" "(" String ")"
     rule initHead(S:String, T:Type)
          => SingleInit(tv(ordChar(firstChar(S)),
               t(getModifiers(T), char)))
          [structural, anywhere]
     
     rule initTail(S:String) 
          => SingleInit(Constant(StringLiteral(butFirstChar(S))))
          [structural, anywhere]
          
     rule [fillInitAux-wstring-some]:
          <k> 
               fillInit-aux(SingleInit(Constant(
                    WStringLiteral((N:Int,, S:KList)))))
               => fillInit(SingleInit(tv(N, cfg:wcharut)))
                    ~> fillInit-aux(SingleInit(Constant(WStringLiteral(S)))) 
          ...</k>
          <currentSubObject> 
               ListItem(te(_:K, T:Type))
          ...</currentSubObject>
          when isWCharType(T)
          [structural]
     // fixme not sure what happens in the case of   char *x = "";
     rule [fillInitAux-string-done]:
          fillInit-aux(SingleInit(Constant(StringLiteral("")))) => .
          [structural]
     rule [fillInitAux-wstring-done]:
          fillInit-aux(SingleInit(Constant(WStringLiteral(.KList)))) => .
          [structural] 
          
     // This rule assumes all unrollings have already occurred, so it needs to
     // be a rule. Alternatively, I've added the condition below which might be
     // enough.
     rule [fillInit-string-notchar]:
          <k> 
               fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => initializeSingleInit(Constant(StringLiteral(S)))
          ...</k>
          <currentSubObject> 
               ListItem(te(_:K, T:Type)) 
          ...</currentSubObject>
          when notBool isCharType(T)
               andBool (isBasicType(T) orBool isPointerType(T)
                    orBool isBitfieldType(T))
          [structural] 
     rule [fillinit-wstring-notwchar]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => initializeSingleInit(Constant(WStringLiteral(S)))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:Type))
          ...</currentSubObject>
          when notBool isWCharType(T)
               andBool (isBasicType(T) orBool isPointerType(T)
                    orBool isBitfieldType(T))
          [structural]

     // need to worry about things that don't have definitions that may
     // override externs
     // want to make it so env is always correct local env, so need to have a
     // set of global envs, one for each tu
     
     rule [initialize-function]:
          <k> initFunction(tv(Loc:SymLoc, t(_, pointerType(T:Type))), 
                    Fun:KResult) 
               => .
          ...</k>
          <functions> M:Map => M:Map[Fun / Loc] </functions>
          when isFunctionType(T)
               andBool notBool $hasMapping(M, Loc)
          [structural]

endmodule

