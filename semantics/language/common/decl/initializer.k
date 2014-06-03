module C-DECL-INITIALIZER-SYNTAX
     syntax KResult ::= initializer(K)

     // Function id, param ids, prototype, body.
     syntax Value ::= functionObject(CId, List, Type, K)

     // CId, type, initializer.
     syntax KItem ::= figureInit(CId, K, K) [strict(2)] 

     // These are also used by compound literals.
     syntax KResult ::= initValue(CId, Type, K)

     syntax KItem ::= allowWrite(K) [strict]
     syntax Type ::= initializerType(Type) [function]

     syntax KItem ::= singleIntInit(K) [strict]
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

     rule initializerType(T:Type) => addStorage(Initializer, T)

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
          when isWCharType(T) andBool (size(S) <=Int Len)
          [structural] 
     
     rule figureInit(_, t(_, (incompleteArrayType(T:Type) 
          => arrayType(T, lengthString(S) +Int 1))),
               SingleInit(stringLiteral(S:String))) 
          when hasCharType(T)
          [structural]

     rule figureInit(_, t(_, (incompleteArrayType(T:Type)
          => arrayType(T, size(S) +Int 1))),
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
               initializer(Computation(allowWrite(X) := K)))
          when notBool isArrayType(T)
          [structural] 
     // c1x 6.7.8:11
     rule figureInit(X:CId, T:Type,
               CompoundInit(list(ListItem(InitFragment(NextInit, SingleInit(K:K))))))
          => figureInit-aux(X, T,
               initializer(Computation(allowWrite(X) := K)))
          when notBool (isAggregateType(T) orBool isUnionType(T))
          [structural] 

     // id, type, initializer
     syntax KItem ::= "figureInit-aux" "(" CId "," Type "," K ")" [strict(3)]
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
          
     syntax KItem ::= te(K, Type) [klabel('te)]
     syntax KItem ::= "getInit"
     syntax KItem ::= fillInit(K)
                | fillInits(List)
                | "fillInit-aux" "(" K ")"

     rule <k> getInit => initializer(K:K) ...</k>
          <saved-init> K:K => . </saved-init> 
          <curr-object> _:List => .List </curr-object> 
          <curr-subobject> _:List => .List </curr-subobject> 
          [structural] 

     syntax KItem ::= startInit(Type, CId, K)
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
     
     syntax KItem ::= "next"
     syntax KItem ::= "block"
     
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
               (ListItem(next) ListItem(te(K:K[N:Int], T:Type)) 
                    => ListItem(te(K[N +Int 1], T)))
               ListItem(te(K, t(_, arrayType(_, Len:Int))))
          ...</curr-subobject>
          when Len >Int N +Int 1
          [structural] 
     rule <curr-subobject>
               ListItem(next) (ListItem(te(K:K[N:Int], _:Type)) => .List)
                    ListItem(te(K:K, t(_, arrayType(_, Len:Int))))
          ...</curr-subobject>
          when notBool Len >Int N +Int 1
          [structural] 
     
     rule <curr-subobject>
               (ListItem(next) ListItem(te(K:K[N:Int], T:Type)) 
                    => ListItem(te(K[N +Int 1], T))) 
               ListItem(te(K, t(_, incompleteArrayType(_))))
          ...</curr-subobject>
          [structural] 

     //define a extra constructor in List to get the 
     //information of next T' and F' if we have next operator
     syntax List ::= searchInFieldInfoList(Type,CId,List,List) [function]
		   | resultInFieldInfoList(List,List)
     
     rule searchInFieldInfoList(_:Type,_:CId,.List,L:List)
				 => resultInFieldInfoList(.List,L)
     rule searchInFieldInfoList(T:Type,F:CId,
			ListItem(typedDeclaration(T, F)) 
			ListItem(typedDeclaration(T':Type, F':CId)) 
							_:List,L1:List) 
		=> resultInFieldInfoList(
			ListItem(typedDeclaration(T':Type, F':CId)),L1)
	 when F' =/=K #NoName

     rule searchInFieldInfoList(T:Type,F:CId,
			ListItem(typedDeclaration(T, F)) 
			ListItem(typedDeclaration(_, #NoName))
			ListItem(typedDeclaration(T':Type, F':CId)) 
							_:List,L1:List) 
		=> resultInFieldInfoList(
				ListItem(typedDeclaration(T':Type, F':CId)),L1)

     rule searchInFieldInfoList(T:Type,F:CId,
			ListItem(typedDeclaration(T, F)),L1:List) 
				=> resultInFieldInfoList(.List,L1)
     rule searchInFieldInfoList(T:Type,F:CId,
			ListItem(typedDeclaration(T, F))
			ListItem(typedDeclaration(_, #NoName)),L1:List)
			 => resultInFieldInfoList(.List,L1)
     rule searchInFieldInfoList(T:Type,F:CId,
			ListItem(typedDeclaration(T':Type, F':CId)) L:List,L1:List) 
			=> searchInFieldInfoList(T:Type, F:CId,
				 L:List,L1) when T =/=K T' andBool F =/=K F'
     
     rule <curr-subobject>
               ListItem(next) ListItem(te(K:K . F:CId, T:Type)) 
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo( (L:List => searchInFieldInfoList(T,F,L,L)), _, _)
               ))))
          ...</curr-subobject>
          [structural] 

     rule <curr-subobject>
               ListItem(next) (ListItem(te(K:K . _:CId, _:Type)) => .List) 
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo((resultInFieldInfoList(.List,L:List) => L), _, _)
               ))))
          ...</curr-subobject>
          [structural] 

     rule <curr-subobject>
               (ListItem(next) ListItem(te(K:K . _:CId, _:Type)) 
                    => ListItem(te(K . F', T')))
               ListItem(te(K:K, t(_, structType(_, _,
                    fieldInfo((resultInFieldInfoList(ListItem(typedDeclaration(T':Type, F':CId)),L:List) => L), _, _)
               ))))
          ...</curr-subobject>
          [structural] 
          
     rule <curr-subobject>
               ListItem(next) (ListItem(te(K:K . _, _)) => .List)
               ListItem(te(K:K, t(_, unionType(_, _, _))))
          ...</curr-subobject>
          [structural] 
          
     rule fillInit(InitFragment(NextInit, Exp:K)) => fillInit(Exp) 
          [structural] 
          
     syntax KItem ::= finishCompoundInit(List)
     rule <k> fillInit(CompoundInit(list(L:List)))
               => fillInits(L)
               ~> finishCompoundInit(ListItem(next) ListItem(te(K, T)) ListItem(Remainder))
          ...</k>
          <curr-subobject> 
               (_:List => .List) 
               ListItem(te(K:K, T:Type)) 
               (ListItem(Remainder:K) => .List)
          </curr-subobject>
          <curr-object>
               (.List => ListItem(te(K, T)))
          ...</curr-object>
          when isAggregateType(T) orBool isUnionType(T)
          [structural]
     rule <k> finishCompoundInit(L:List) => . ...</k>
          <curr-object>
               (ListItem(te(_:K, _:Type)) => .List)
          ...</curr-object>
          <curr-subobject> (_ => L) </curr-subobject>
          [structural] 

     context fillInit(InitFragment(HOLE, _)) 
     syntax KItem ::= buildDesignator(K)
     
     // note that these clear the current subobject cell, because it will be
     // repopulated when building the designator
     rule <k> fillInit(InitFragment(InFieldInit(F:CId, K':K), Exp:K))
               => fillInit(InitFragment(buildDesignator(
                    InFieldInit(F, K')), Exp))
          ...</k>
          <curr-object> ListItem(te(K:K, T:Type)) ...</curr-object>
          <curr-subobject>
               _:List => ListItem(block) ListItem(te(K, T))
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
               _:List => ListItem(block) ListItem(te(K, T))
          </curr-subobject>
          when isArrayType(T)
          [structural] 
     
     rule <k> buildDesignator(InFieldInit(F:CId, More:K)) 
               => buildDesignator(More)
          ...</k>
          <curr-subobject> 
               ListItem(block) (.List => ListItem(te(K . F, T)))
                    ListItem('te(K:K,, 't(_,, Lbl:KLabel(S:CId,, _))))
          ...</curr-subobject>
          <structs>... 
               S |-> fieldInfo(_, (_ F:CId |-> T:Type), _)
          ...</structs>
          when Lbl ==KLabel 'structType orBool Lbl ==KLabel 'unionType
          [structural] 
          
     rule <k> buildDesignator(NextInit) => NextInit ...</k>
          <curr-subobject> (ListItem(block) => .List) ...</curr-subobject>
          [structural] 

     context buildDesignator(AtIndexInit((HOLE => reval(HOLE)), _)) 
     rule <k> buildDesignator(AtIndexInit(tv(N:Int, _), More:K)) 
               => buildDesignator(More)
          ...</k>
          <curr-subobject> 
               ListItem(block) (.List => ListItem(te(K[N], innerType(T))))
                    ListItem(te(K:K, T:Type)) 
          ...</curr-subobject>
          when isArrayType(T)
          [structural] 
     
     syntax KItem ::= "popInit"
     
     syntax Int ::= getTopArrayUse(K) [function]
     rule getTopArrayUse(_:CId) => 0
     // +1 for length instead of index
     rule getTopArrayUse(_:CId[N:Int]) => N +Int 1
     rule getTopArrayUse(K:K . _:CId) => getTopArrayUse(K)
     rule getTopArrayUse((K:K[N:Int])[_]) => getTopArrayUse(K[N])
     rule getTopArrayUse((K:K . _:CId)[_]) => getTopArrayUse(K)
     
     syntax KItem ::= initializeSingleInit(K)
          
     rule (. => typeof(K)) ~> initializeSingleInit(K:K)
          [structural] 
     
     // fixme want to exclude strings, but not normal arrays
     rule <k> T':Type ~> initializeSingleInit(K':K) => . ...</k>
          <curr-subobject>
               (.List => ListItem(next)) ListItem(te(K:K, T:Type))
          ...</curr-subobject>
          <incomplete-length>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incomplete-length>
          <saved-init>... 
               . => Computation(allowWrite(K) := K')
          </saved-init>
          when (isBasicType(T) 
                    orBool isPointerType(T) 
                    orBool isBitfieldType(T))
               andBool notBool isStructType(T')
               andBool notBool isUnionType(T')
          [structural]
          
     // this is used to have an aggregate on the RHS of a compound init
     // fixme want to exclude strings, but not normal arrays
     syntax KItem ::= initFromAggregateRHS(K, Type)
     rule T:Type ~> initializeSingleInit(K:K) 
          => initFromAggregateRHS(K, T)
          when isStructType(T)
               orBool isUnionType(T)
          [structural] 
          
     syntax KItem ::= initFromStructRHS(K, Type)
     rule <k> initFromAggregateRHS(K:K, t(S:Set, structType(X:CId, NBits:Int, Info:FieldInfo)))
               => initFromStructRHS(K, t(S, structType(X, NBits, Info)))
          ...</k>
          <curr-subobject>
               .List => ListItem(findStruct(t(S, structType(X, NBits, Info))))
          ...</curr-subobject>
          [structural] 
          
     syntax KItem ::= findStruct(Type)
          
     rule <curr-subobject>
               ListItem(findStruct(T:Type)) (ListItem(te(_, T':Type)) => .List)
          ...</curr-subobject>
          when T =/=K T'
          [structural] 
          
     // fixme unsafe, might have started to initialize other things
     rule <k> initFromStructRHS(K':K, t(_, structType(S:CId, _, _))) => . ...</k>
          <curr-subobject> 
               ListItem(findStruct(t(_, structType(S:CId, _, _))))
                    ListItem(te(K:K, t(_, structType(S:CId, _, _)))) => ListItem(next) 
          ...</curr-subobject>
          <incomplete-length>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incomplete-length>
          <saved-init>...
               .K => Computation(allowWrite(K) := K')
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
          when isWCharType(T) andBool size(S) ==Int Len
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
          when isWCharType(T) andBool size(S) <Int Len
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
          
     syntax KItem ::= initHead(String) [function]
     syntax KItem ::= initTail(String) [function]
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
