module C-DECLARATION-INITIALIZATION-SYNTAX
     syntax K ::= "startInit" "(" Type "," Id "," K ")"
endmodule

module C-DECLARATION-INITIALIZATION
     imports C-DECLARATION-INITIALIZATION-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX
     imports C-DECLARATION-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C11-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX
     
     syntax K ::= "te" "(" K "," Type ")" [klabel('te)]
     syntax K ::= "getInit"
     syntax K ::= "fillInit" "(" K ")"
     syntax K ::= "fillInit-aux" "(" K ")"
     syntax K ::= "fillInit" "(" KList ")"
     syntax C ::= "completeInitFragment" "(" K "," K ")"
     syntax KResult ::= "initializerFragment" "(" K ")"
     
     rule <k> getInit => initializer(K:K) ...</k>
          <savedInitialization> K:K => . </savedInitialization> 
          <currentObject> _:List => . </currentObject> 
          <currentSubObject> _:List => . </currentSubObject> 
          [structural] 

     rule <k> startInit(T:KResult, X:Id, CompoundInit(klist(L:KList)))
               => fillInit(L) 
               ~> getInit
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
     
     rule fillInit((InitFragment(K:K, Exp:K),, L:KList))
          => fillInit(InitFragment(K:K, Exp:K)) 
          ~> fillInit(L:KList)
          [structural] 
     rule fillInit(.KList) => .
          [structural] 
     
     syntax ListItem ::= "next"
     syntax ListItem ::= "block"
     
     rule <currentSubObject> 
               ListItem(te(K:K, t(S:Set, arrayType(T:KResult, Len:Int))))
               => ListItem(te(K:K[0], T:KResult))
                    ListItem(te(K:K, t(S:Set, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          [structural] 
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, incompleteArrayType(T:KResult))))
               => ListItem(te(K:K[0], T:KResult))
                    ListItem(te(K:K, t(Se:Set, incompleteArrayType(T:KResult))))
          ...</currentSubObject>
          [structural] 
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K:K . F:Id, T:KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
          ...</currentSubObject>
          <structs>... 
               S:Id |-> aggregateInfo((typedDeclaration(T:KResult, F:Id),, _), _, _)
          ...</structs> 
          [structural] 
          
     // fixme these are terrible!
     rule <currentSubObject> 
               ListItem(te(K:K, t(Se:Set, unionType(S:Id))))
               => ListItem(te(K:K . F:Id, T:KResult))
                    ListItem(te(K:K, t(Se:Set, unionType(S:Id))))
          ...</currentSubObject>
          <structs>... 
               S |-> aggregateInfo((typedDeclaration(T, F),, _), _, _) 
          ...</structs> 
          [structural] 
          
     // fixme should i worry about basetype here_
     rule [init-next-array-element]:
          <currentSubObject> 
               (next ListItem(te(K:K[N:Int], T:KResult)) 
                    => ListItem(te(K:K[N:Int +Int 1], T:KResult)))
               ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</currentSubObject>
          when Len:Int >Int N:Int +Int 1
          [structural] 
     rule [init-next-array-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K[N:Int], _:KResult)) => .List)
                    ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</currentSubObject>
          when notBool Len:Int >Int N:Int +Int 1
          [structural] 
     
     rule [init-next-incomplete-array-element]:
          <currentSubObject>
               (next ListItem(te(K:K[N:Int], T:KResult)) 
                    => ListItem(te(K:K[N:Int +Int 1], T:KResult))) 
               ListItem(te(K:K, t(_, incompleteArrayType(_))))
          ...</currentSubObject>
          [structural] 
     
     rule [init-next-struct-element]:
          <currentSubObject>
               next ListItem(te(K:K . F:Id, T:KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K:K . F':Id, T':KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),,
                    typedDeclaration(T':KResult, F':Id),, _), _, _)
          ...</structs> 
          when F':Id =/=K #NoName
          [structural, large] 
      
     rule [init-next-struct-element-noname]:
          <currentSubObject>
               next ListItem(te(K:K . F:Id, T:KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
               => ListItem(te(K:K . F':Id, T':KResult))
                    ListItem(te(K:K, t(Se:Set, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id),,
                    typedDeclaration(_, #NoName),,
                    typedDeclaration(T':KResult, F':Id),, _), _, _)
          ...</structs>
          [structural, large] 
          
     rule [init-next-struct-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K . F:Id, T:KResult)) => .)
                    ListItem(te(K:K, t(_, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, typedDeclaration(T:KResult, F:Id)), _, _)
          ...</structs> 
          [structural, large] 
     rule [init-next-struct-element-done-noname]:
          <currentSubObject>
               next (ListItem(te(K:K . F:Id, T:KResult)) => .)
                    ListItem(te(K:K, t(_, structType(S:Id))))
          ...</currentSubObject>
          <br/>
          <structs>...
               S:Id |-> aggregateInfo((_,, 
                    typedDeclaration(T:KResult, F:Id),,
                    typedDeclaration(_, #NoName)), _, _)
          ...</structs> 
          [structural, large] 
          
     rule [init-next-union-element-done]:
          <currentSubObject>
               next (ListItem(te(K:K . _:Id, _:KResult)) => .List)
                    ListItem(te(K:K, t(_, unionType(_:Id))))
          ...</currentSubObject>
          [structural] 
          
     rule fillInit(InitFragment(NextInit, Exp:K)) => fillInit(Exp:K) 
          [structural] 
          
     syntax K ::= "finishCompoundInit" "(" List ")"
     rule <k> fillInit(CompoundInit(klist(L:KList)))
               => fillInit(L:KList)
                    ~> finishCompoundInit(
                    next ListItem(te(K:K, T:KResult)) Remainder:ListItem)
          ...</k>
          <currentSubObject> 
               (_:List => .) ListItem(te(K:K, T:KResult))
                    (Remainder:ListItem => .)
          </currentSubObject>
          <currentObject>
               (. => ListItem(te(K:K, T:KResult)))
          ...</currentObject>
          when isAggregateType(T:KResult) orBool isUnionType(T:KResult)
          [structural]
     rule <k> finishCompoundInit(L:List) => . ...</k>
          <currentObject>
               (ListItem(te(_:K, _:KResult)) => .)
          ...</currentObject>
          <currentSubObject> (_ => L:List) </currentSubObject>
          [structural] 
               
     context fillInit(InitFragment(HOLE, _)) 
     syntax K ::= "buildDesignator" "(" K ")"
     
     // note that these clear the current subobject cell, because it will be
     // repopulated when building the designator
     rule <k> fillInit(InitFragment(InFieldInit(F:Id, K':K), Exp:K))
               => fillInit(InitFragment(buildDesignator(
                    InFieldInit(F:Id, K':K)), Exp:K))
          ...</k>
          <currentObject> ListItem(te(K:K, T:KResult)) ...</currentObject>
          <currentSubObject>
               _:List => block ListItem(te(K:K, T:KResult))
          </currentSubObject>
          when isStructType(T:KResult) orBool isUnionType(T:KResult)
          [structural] 
     // fixme does this need to worry about incompleteLength_
     rule <k> fillInit(InitFragment(AtIndexInit(Index:K, K':K), Exp:K))
               => fillInit(InitFragment(
                    buildDesignator(AtIndexInit(Index:K, K':K)), Exp:K))
          ...</k>
          <currentObject> ListItem(te(K:K, T:KResult)) ...</currentObject>
          <currentSubObject>
               _:List => block ListItem(te(K:K, T:KResult))
          </currentSubObject>
          when isArrayType(T:KResult)
          [structural] 
          
     
     // fixme these are also too restrictive on type.  if we try to assign an
     // int to a long-int field, it will fail
     // i don't think this is true anymore
     rule <k> buildDesignator(InFieldInit(F:Id, More:K)) 
               => buildDesignator(More:K)
          ...</k>
          <currentSubObject> 
               block (.List => ListItem(te(K:K . F:Id, T:KResult)))
                    ListItem('te(K:K,, 't(_,, KL:KLabel(S:Id))))
          ...</currentSubObject>
          <structs>... 
               S:Id |-> aggregateInfo(_, (_ F:Id |-> T:KResult), _)
          ...</structs>
          when KL:KLabel ==KLabel 'structType 
               orBool KL:KLabel ==KLabel 'unionType
          [structural] 
          
     rule <k> buildDesignator(NextInit) => NextInit ...</k>
          <currentSubObject> (block => .List) ...</currentSubObject>
          [structural] 
          
     rule [innerType-arrayType]:
          innerType(t(_, arrayType(T:KResult, _:Int))) => T:KResult
     rule [innerType-incompleteArrayType]: 
          innerType(t(_, incompleteArrayType(T:KResult))) => T:KResult
     rule [innerType-flexibleArrayType]: 
          innerType(t(_, flexibleArrayType(T:KResult))) => T:KResult
     rule [innerType-qualifiedType]:
          innerType(t(_, qualifiedType(T:KResult, _))) => innerType(T:KResult)
     rule [innerType-pointerType]:
          innerType(t(_, pointerType(T:KResult))) => T:KResult
     rule [innerType-bitfieldType]:
          innerType(t(_, bitfieldType(T:KResult, _:Int))) => T:KResult
     rule [innerType-functionType]:
          innerType(t(_, functionType(T:KResult, _:KList))) => T:KResult

     context buildDesignator(AtIndexInit((HOLE => reval(HOLE)), _)) 
     rule <k> buildDesignator(AtIndexInit(tv(N:Int, _), More:K)) 
               => buildDesignator(More:K)
          ...</k>
          <currentSubObject> 
               block (.List => ListItem(te(K:K[N:Int], innerType(T:KResult))))
                    ListItem(te(K:K, T:KResult)) 
          ...</currentSubObject>
          when isArrayType(T:KResult)
          [structural] 
     
     syntax K ::= "popInit"
     
     syntax Int ::= getTopArrayUse(K) [function]
     rule getTopArrayUse(_:Id) => 0
     // +1 for length instead of index
     rule getTopArrayUse(_:Id[N:Int]) => N:Int +Int 1
     rule getTopArrayUse(K:K . _:Id) => getTopArrayUse(K:K)
     rule getTopArrayUse((K:K[N:Int])[_]) => getTopArrayUse(K:K[N:Int])
     rule getTopArrayUse((K:K . _:Id)[_]) => getTopArrayUse(K:K)
     
     syntax K ::= "initializeSingleInit" "(" K ")"
          
     rule (. => typeof(K)) ~> initializeSingleInit(K:K)
          [structural] 
     
     // fixme want to exclude strings, but not normal arrays
     rule <k> T':KResult ~> initializeSingleInit(K':K) => . ...</k>
          <currentSubObject>
               (.List => next) ListItem(te(K:K, T:KResult))
          ...</currentSubObject>
          <incompleteLength>
               N:Int => maxInt(N:Int, getTopArrayUse(K:K))
          </incompleteLength>
          <savedInitialization>... 
               .K => Computation(allowWrite(K:K) := K':K) 
                    ~> possiblyMakeConst(T:KResult, K:K)
          </savedInitialization>
          when (isBasicType(T:KResult) 
                    orBool isPointerType(T:KResult) 
                    orBool isBitfieldType(T:KResult))
               andBool (notBool isStructType(T':KResult))
               andBool (notBool isUnionType(T':KResult))
          [structural]
     
     syntax K ::= "possiblyMakeConst" "(" Type "," K ")"
     
     rule possiblyMakeConst(T:KResult, K:K) => makeUnwritableSubObject(K)
          when isConstType(T)
          [structural]
     rule possiblyMakeConst(T:KResult, _) => .
          when notBool isConstType(T)
          [structural]
          
     // this is used to have an aggregate on the RHS of a compound init
     // fixme want to exclude strings, but not normal arrays
     syntax K ::= "initFromAggregateRHS" "(" K "," Type ")"
     rule T:KResult ~> initializeSingleInit(K:K) 
          => initFromAggregateRHS(K:K, T:KResult)
          when isStructType(T:KResult)
               orBool isUnionType(T:KResult)
          [structural] 
          
     syntax K ::= "initFromStructRHS" "(" K "," Type ")"
     rule <k> initFromAggregateRHS(K:K, t(S:Set, structType(I:Id)))
               => initFromStructRHS(K:K, t(S:Set, structType(I:Id)))
          ...</k>
          <currentSubObject>
               .List => findStruct(t(S:Set, structType(I:Id)))
          ...</currentSubObject>
          [structural] 
          
     syntax ListItem ::= "findStruct" "(" Type ")"
          
     rule <currentSubObject>
               findStruct(T:KResult) (ListItem(te(_, T':KResult)) => .List)
          ...</currentSubObject>
          when T:KResult =/=K T':KResult
          [structural] 
          
     // fixme unsafe, might have started to initialize other things
     rule <k> initFromStructRHS(K':K, t(_, structType(S:Id))) => . ...</k>
          <currentSubObject> 
               findStruct(t(_, structType(S:Id)))
                    ListItem(te(K:K, t(_, structType(S:Id)))) => next 
          ...</currentSubObject>
          <br/>
          <incompleteLength>
               N:Int => maxInt(N:Int, getTopArrayUse(K:K))
          </incompleteLength>
          <savedInitialization>...
               .K => Computation(allowWrite(K:K) := K':K)
          </savedInitialization> 
          [structural, large] 
     
     rule fillInit(SingleInit(K:K)) => initializeSingleInit(K:K)
          when getKLabel(K:K) =/=KLabel 'Constant
          [structural] 

     rule [fillInit-string-array-eq]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit-aux(SingleInit(Constant(StringLiteral(S:String))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          when isCharType(T:KResult)
               andBool lengthString(S:String) ==Int Len:Int
          [structural] 
     rule [fillInit-wstring-array-eq]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit-aux(SingleInit(Constant(WStringLiteral(S:KList))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          when isWCharType(T:KResult)
               andBool lengthKList S:KList  ==Int Len:Int
          [structural] 
     rule [fillInit-string-array-lt]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit(SingleInit(Constant(
                    StringLiteral(S:String +String "\0"))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          when isCharType(T:KResult)
               andBool lengthString(S:String) <Int Len:Int
          [structural] 
     rule [fillInit-wstring-array-lt]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit(SingleInit(Constant(WStringLiteral((S:KList,, 0)))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, arrayType(T:KResult, Len:Int))))
          ...</currentSubObject>
          when isWCharType(T:KResult)
               andBool lengthKList S:KList <Int Len:Int
          [structural] 
     rule [fillInit-string-char]:
          <k> fillInit(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit-aux(SingleInit(Constant(
                    StringLiteral(S:String +String "\0"))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
                    ListItem(te(_, t(_, incompleteArrayType(T:KResult))))
          ...</currentSubObject>
          when isCharType(T:KResult)
          [structural] 
     rule [fillInit-wstring-wchar]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => fillInit-aux(SingleInit(Constant(
                    WStringLiteral((S:KList,, 0)))))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult)) ListItem(te(_, t(_, incompleteArrayType(T:KResult))))
          ...</currentSubObject>
          when isWCharType(T:KResult)
          [structural]
     rule [fillInitAux-string-some]:
          <k> fillInit-aux(SingleInit(Constant(StringLiteral(S:String))))
               => fillInit(initHead(S:String, T:KResult)) 
               ~> fillInit-aux(initTail(S:String))
          ...</k>
          <currentSubObject> ListItem(te(_:K, T:KResult)) ...</currentSubObject>
          when S:String =/=String ""
               andBool isCharType(T:KResult)
          [structural]
          
     syntax K ::= "initHead" "(" K "," K ")"
     syntax K ::= "initTail" "(" K ")"
     rule initHead(S:String, T:KResult)
          => SingleInit(tv(asciiString(firstChar(S:String)),
               t(getModifiers(T:KResult), char)))
          [structural, anywhere]
     
     rule initTail(S:String) 
          => SingleInit(Constant(StringLiteral(butFirstChar(S:String))))
          [structural, anywhere]
          
     rule [fillInitAux-wstring-some]:
          <k> 
               fillInit-aux(SingleInit(Constant(
                    WStringLiteral((N:Int,, S:KList)))))
               => fillInit(SingleInit(tv(N:Int, cfg:wcharut)))
                    ~> fillInit-aux(SingleInit(Constant(
                    WStringLiteral(S:KList)))) 
          ...</k>
          <currentSubObject> 
               ListItem(te(_:K, T:KResult))
          ...</currentSubObject>
          when isWCharType(T:KResult)
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
               => initializeSingleInit(Constant(StringLiteral(S:String)))
          ...</k>
          <currentSubObject> 
               ListItem(te(_:K, T:KResult)) 
          ...</currentSubObject>
          when notBool isCharType(T:KResult)
               andBool (isBasicType(T:KResult) orBool isPointerType(T:KResult)
                    orBool isBitfieldType(T:KResult))
          [structural] 
     rule [fillinit-wstring-notwchar]:
          <k> fillInit(SingleInit(Constant(WStringLiteral(S:KList))))
               => initializeSingleInit(Constant(WStringLiteral(S:KList)))
          ...</k>
          <currentSubObject>
               ListItem(te(_:K, T:KResult))
          ...</currentSubObject>
          when notBool isWCharType(T:KResult)
               andBool (isBasicType(T:KResult) orBool isPointerType(T:KResult)
                    orBool isBitfieldType(T:KResult))
          [structural]
endmodule

