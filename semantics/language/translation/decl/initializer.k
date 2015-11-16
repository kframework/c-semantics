module C-DECL-INITIALIZER-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax KResult ::= initializer(K)

     // CId, type, initializer.
     syntax KItem ::= figureInit(CId, K, K) [strict(2)]

endmodule

module C-DECL-INITIALIZER
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX

     imports C-ABSTRACT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-LITERAL-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule figureInit(X:CId, T:Type, CodeLoc(K:K, L::CabsLoc))
          => CodeLoc(.K, L) ~> figureInit(X, T, K)
          [structural]

     rule figureInit(X:CId, T:Type, NoInit) => initValue(X, T, .K)
          [structural]

     // aggregates
     rule figureInit(X:CId, T:AggregateOrUnionType, CompoundInit(L:K))
          => giveType(X, T)
          ~> figureInit-aux(X, T, startInit(T, X, CompoundInit(L)))
          [structural]

     rule figureInit(
               _,
               t(_, arrayType(_:CharType, Len:Int)),
               (SingleInit(stringLiteral(S:String))
               => CompoundInit(list(ListItem(InitFragment(NextInit,
                    SingleInit(stringLiteral(S)))))))
          )
          requires (lengthString(S) <=Int Len)
          [structural]

     rule figureInit(
               _,
               t(_, arrayType(T:Type, Len:Int)),
               (SingleInit(wstringLiteral(S:List))
               => CompoundInit(list(ListItem(InitFragment(NextInit,
                    SingleInit(wstringLiteral(S)))))))
          )
          requires isWCharType(T) andBool (size(S) <=Int Len)
          [structural]

     rule figureInit(_, t(_, (incompleteArrayType(T:CharType)
          => arrayType(T, lengthString(S) +Int 1))),
               SingleInit(stringLiteral(S:String)))
          [structural]

     rule figureInit(_, t(_, (incompleteArrayType(T:Type)
          => arrayType(T, size(S) +Int 1))),
               SingleInit(wstringLiteral(S:List)))
          requires isWCharType(T)
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
               initializer(Computation(ncle(X, T) := K)))
          requires notBool isArrayType(T)
          [structural]
     // c1x 6.7.8:11
     rule figureInit(X:CId, T:Type,
               CompoundInit(list(ListItem(InitFragment(NextInit, SingleInit(K:K))))))
          => figureInit-aux(X, T,
               initializer(Computation(ncle(X, T) := K)))
          requires notBool isAggregateOrUnionType(T)
          [structural]

     rule (.K => UNDEF("CDI1",
               "Initializer for scalar contains multiple expressions", "6.7.9:11, J.2:1 item 81"))
          ~> figureInit(_, T:Type, CompoundInit(list(L:List)))
          requires notBool isAggregateOrUnionType(T)
               andBool size(L) >Int 1
     rule (_:ErrorExit => .K) ~> figureInit(_, T:Type, CompoundInit(list(ListItem(_) (L:List => .List))))
          requires notBool isAggregateOrUnionType(T)
               andBool isErrorRecovery andBool size(L) >Int 0

     rule (.K => UNDEF("CDI2",
               "Initializer for scalar contains multiple levels of braces", "6.7.9:11, J.2:1 item 81"))
          ~> figureInit(_, T:Type,
               CompoundInit(list(ListItem(InitFragment(NextInit, CompoundInit(_))))))
          requires notBool isAggregateOrUnionType(T)
     rule (_:ErrorExit => .K) ~> figureInit(_, T:Type, (CompoundInit(list(ListItem(InitFragment(NextInit, CompoundInit(L:K))))) => CompoundInit(L)))
          requires notBool isAggregateOrUnionType(T) andBool isErrorRecovery

     rule (.K => UNDEF("CDI3",
               "Invalid initializer for aggregate type", "6.7.9:16, J.2:1 item 83"))
          ~> figureInit(_, t(_, incompleteArrayType(T:Type)), SingleInit(K:K))
          requires notBool isWCharType(T) orBool getKLabel(K) =/=K #klabel(`wstringLiteral`)

     rule <k> figureInit-aux(_:CId, t(_,
                    (incompleteArrayType(T:Type)
                    => arrayType(T, N))), initializer(_))
          ...</k>
          <incomplete-length> N:Int </incomplete-length>
          [structural]

   // id, type, initializer
     syntax KItem ::= "figureInit-aux" "(" CId "," Type "," K ")" [strict(3)]
     rule figureInit-aux(X:CId, T:Type, initializer(K:K))
          => giveType(X, T) ~> elaborateInit(K) ~> initValue(X, T, .K)
          requires isCompleteType(T)
     rule (elaborateDone(K:K) => .K) ~> initValue(_, _, (.K => K))

     // Special array designator syntax so that it doesn't get caught by the
     // X[Y] => *(X + Y) macro.
     syntax KItem ::= K "[[" Int "]]"
     rule K:K [[ N:Int ]] => K[N]::Expression

     syntax KItem ::= "getInit"
     syntax KItem ::= fillInit(K)
                | fillInits(List)
                | "fillInit-aux" "(" K ")"

     rule <k> getInit => initializer(K) ...</k>
          <curr-subobject> _:List => .List </curr-subobject>
          <curr-object> _:List => .List </curr-object>
          <saved-init> K:K => .K </saved-init>

     syntax KItem ::= startInit(Type, CId, K)
     rule <k> startInit(T:AggregateOrUnionType, X:CId, CompoundInit(list(L:List)))
               => fillInits(L) ~> getInit
          ...</k>
          <incomplete-length> _ => 0 </incomplete-length>
          <curr-subobject>
               .List => ListItem(ncle(ncle(X, T), T))
          </curr-subobject>
          <curr-object>
               .List => ListItem(ncle(ncle(X, T), T))
          </curr-object>
          <saved-init>... .K => zero(X) </saved-init>
          [structural]

     rule fillInits(ListItem(InitFragment(K:K, Exp:K)) L:List)
          => fillInit(InitFragment(K, Exp)) ~> fillInits(L)
          [structural]
     rule fillInits(.List) => .K
          [structural]

     syntax KItem ::= "next"
     syntax KItem ::= "block"

     rule <curr-subobject>
               (.List => ListItem(ncle(K[[0]], T)))
               ListItem(ncle(K:K, t(_, arrayType(T:Type, _))))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (.List => ListItem(ncle(K[[0]], T)))
               ListItem(ncle(K:K, t(_, incompleteArrayType(T:Type))))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (.List => ListItem(ncle(K . F, T)))
               ListItem(ncle(K:K, t(_, structType(S:StructId))))
          ...</curr-subobject>
          <structs>... S |-> fieldInfo(ListItem(typedDeclaration(T:Type, F:CId)) _, _, _, _) ...</structs>
          [structural]

     // fixme these are terrible!
     rule <curr-subobject>
               (.List => ListItem(ncle(K . F, T)))
               ListItem(ncle(K:K, t(_, unionType(S:StructId))))
          ...</curr-subobject>
          <structs>... S |-> fieldInfo(ListItem(typedDeclaration(T:Type, F:CId)) _, _, _, _) ...</structs>
          [structural]

     // fixme should i worry about basetype here_
     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K:K[[N:Int]], T:Type))
                    => ListItem(ncle(K[[N +Int 1]], T)))
               ListItem(ncle(K, t(_, arrayType(_, Len:Int))))
          ...</curr-subobject>
          requires Len >Int N +Int 1
          [structural]
     rule <curr-subobject>
               ListItem(next)
               (ListItem(ncle(K:K[[N:Int]], _:Type)) => .List)
               ListItem(ncle(K:K, t(_, arrayType(_, Len:Int))))
          ...</curr-subobject>
          requires notBool Len >Int N +Int 1
          [structural]

     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K:K[[N:Int]], T:Type))
                    => ListItem(ncle(K[[N +Int 1]], T)))
               ListItem(ncle(K, t(_, incompleteArrayType(_))))
          ...</curr-subobject>
          [structural]

     // define a extra constructor in List to get the
     // information of next T' and F' if we have next operator
     // TODO(liyi): no associative matching. increase speed
     syntax Type ::= "noResultOfSearchType" | "matchResultOfSearchType"

     syntax KItem ::= searchInFieldInfoList(Type, CId, List) [function]
                    | continueInFieldInfoList(List) [function]

     syntax KItem ::= resultInFieldInfoList(Type)

     rule searchInFieldInfoList(T:Type, F:CId,
               ListItem(typedDeclaration(T, F)) L:List)
          => continueInFieldInfoList(L)
     rule searchInFieldInfoList(_, _, .List)
          => resultInFieldInfoList(noResultOfSearchType)
     rule searchInFieldInfoList(T:Type, F:CId, ListItem(K:K) L:List)
          => searchInFieldInfoList(T, F, L)
          requires getKLabel(K) =/=K #klabel(`typedDeclaration`)
     rule searchInFieldInfoList(T:Type, F:CId,
               ListItem(typedDeclaration(T':Type, F':CId)) L:List)
          => searchInFieldInfoList(T, F, L)
          requires T =/=K T' orBool F =/=K F'

     rule continueInFieldInfoList(.List)
          => resultInFieldInfoList(matchResultOfSearchType)
     rule continueInFieldInfoList(
               ListItem(typedDeclaration(T:Type, F:CId)) _)
          => resultInFieldInfoList(typedDeclaration(T, F))
          requires F =/=K #NoName
     rule continueInFieldInfoList(
               ListItem(typedDeclaration(_, #NoName))
               ListItem(typedDeclaration(T':Type, F':CId)) _)
          => resultInFieldInfoList(typedDeclaration(T':Type, F':CId))
     rule continueInFieldInfoList(
               ListItem(typedDeclaration(_, #NoName)))
          => resultInFieldInfoList(matchResultOfSearchType)

     rule <k> (.K => searchInFieldInfoList(T, F, L)) ...</k>
          <curr-subobject>
               ListItem(next) (.List => ListItem(block)) ListItem(ncle(K:K . F:CId, T:Type))
               ListItem(ncle(K:K, t(_, structType(S:StructId))))
          ...</curr-subobject>
          <structs>... S |-> fieldInfo(L:List, _, _, _) ...</structs>
          [structural]

     rule <k> resultInFieldInfoList(typedDeclaration(T':Type, F':CId))
               => .K
          ...</k>
          <curr-subobject>
               (ListItem(next) ListItem(block) ListItem(ncle(K:K . _, _))
                    => ListItem(ncle(K . F', T')))
               ListItem(ncle(K:K, t(_, structType(_))))
          ...</curr-subobject>
          [structural]

     rule <k> resultInFieldInfoList(matchResultOfSearchType) => .K ...</k>
          <curr-subobject>
               ListItem(next)
               (ListItem(block) ListItem(ncle(K:K . _, _)) => .List)
               ListItem(ncle(K:K, t(_, structType(_))))
          ...</curr-subobject>
          [structural]

     rule <curr-subobject>
               ListItem(next)
               (ListItem(ncle(K:K . _, _)) => .List)
               ListItem(ncle(K:K, t(_, unionType(_))))
          ...</curr-subobject>
          [structural]

     rule <k> fillInit(InitFragment(NextInit, Exp:K)) => fillInit(Exp) ...</k>
          <curr-subobject>
            ListItem(K:K)
          ...</curr-subobject>
          requires K =/=K next
          [structural]

     rule <k> (.K => CV("CDI4", "Attempting to initialize nonexistent member.",
               "6.7.9:2"))
               ~> fillInit(InitFragment(NextInit, _))
          ...</k>
          <curr-subobject>
               ListItem(next) ListItem(ncle(_, T:Type))
          </curr-subobject>
          requires isAggregateOrUnionType(T) 

     syntax KItem ::= finishCompoundInit(List)
     rule <k> fillInit(CompoundInit(list(L:List)))
               => fillInits(L)
               ~> finishCompoundInit(ListItem(next) ListItem(ncle(K, T)) ListItem(Remainder))
          ...</k>
          <curr-subobject>
               (_:List => .List)
               ListItem(ncle(K:K, T:AggregateOrUnionType))
               (ListItem(Remainder:K) => .List)
          </curr-subobject>
          <curr-object>
               .List => ListItem(ncle(K, T))
          ...</curr-object>
          [structural]
     rule <k> finishCompoundInit(L:List) => .K ...</k>
          <curr-subobject> (_ => L) </curr-subobject>
          <curr-object>
               ListItem(ncle(_, _)) => .List
          ...</curr-object>
          [structural]

     context fillInit(InitFragment(HOLE:KItem, _))

     // note that these clear the current subobject cell, because it will be
     // repopulated when building the designator
     rule <k> fillInit(InitFragment(InFieldInit(F:CId, K':K), Exp:K))
               => fillInit(InitFragment(buildDesignator(
                    InFieldInit(F, K')), Exp))
          ...</k>
          <curr-subobject>
               _:List => ListItem(block) ListItem(ncle(K, T))
          </curr-subobject>
          <curr-object> ListItem(ncle(K:K, T:StructOrUnionType)) ...</curr-object>
          [structural]
     // fixme does this need to worry about incompleteLength_
     rule <k> fillInit(InitFragment(AtIndexInit(Index:K, K':K), Exp:K))
               => fillInit(InitFragment(
                    buildDesignator(AtIndexInit(Index, K')), Exp))
          ...</k>
          <curr-subobject>
               _:List => ListItem(block) ListItem(ncle(K, T))
          </curr-subobject>
          <curr-object> ListItem(ncle(K:K, T:ArrayType)) ...</curr-object>
          [structural]

     syntax KItem ::= buildDesignator(K)
     rule <k> buildDesignator(InFieldInit(F:CId, More:K))
               => buildDesignator(More)
          ...</k>
          <curr-subobject>
               ListItem(block) (.List => ListItem(ncle(K . F, T)))
                    ListItem(ncle(K:K, t(_, Lbl:KLabel(S:StructId))))
          ...</curr-subobject>
          <structs>...
               S |-> fieldInfo(_, _, (_ F:CId |-> T:Type), _)
          ...</structs>
          requires #klabel(Lbl) ==K #klabel(`structType`) orBool #klabel(Lbl) ==K #klabel(`unionType`)
          [structural]

     rule <k> buildDesignator(NextInit) => NextInit ...</k>
          <curr-subobject> (ListItem(block) => .List) ...</curr-subobject>
          [structural]

     context buildDesignator(AtIndexInit((HOLE:KItem => reval(HOLE)), _))
          [result(RValue)]
     rule <k> buildDesignator(AtIndexInit(tv(N:Int, _), More:K))
               => buildDesignator(More)
          ...</k>
          <curr-subobject>
               ListItem(block) (.List => ListItem(ncle(K[[N]], innerType(T))))
                    ListItem(ncle(K:K, T:ArrayType))
          ...</curr-subobject>
          [structural]

     syntax KItem ::= "popInit"

     syntax Int ::= getTopArrayUse(K) [function]
     rule getTopArrayUse(_:KResult) => 0
     // +1 for length instead of index
     rule getTopArrayUse(_:KResult[[N:Int]]) => N +Int 1
     rule getTopArrayUse(K:K . _:CId) => getTopArrayUse(K)
     rule getTopArrayUse((K:K[[N:Int]])[[_]]) => getTopArrayUse(K[[N]])
     rule getTopArrayUse((K:K . _:CId)[[_]]) => getTopArrayUse(K)

     syntax KItem ::= initializeSingleInit(K)

     rule (.K => typeof(K)) ~> initializeSingleInit(K:K)
          [structural]
     rule (typeof(T:Type) => T) ~> initializeSingleInit(_)
          [structural]

     // fixme want to exclude strings, but not normal arrays
     rule <k> T':Type ~> initializeSingleInit(K':K) => .K ...</k>
          <curr-subobject>
               (.List => ListItem(next)) ListItem(ncle(K:K, T:Type))
          ...</curr-subobject>
          <incomplete-length>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incomplete-length>
          <saved-init>...
               .K => Computation(K := K')
          </saved-init>
          requires (isBasicType(T)
                    orBool isPointerType(T)
                    orBool isBitfieldType(T))
               andBool notBool isStructOrUnionType(T')
          [structural]

     // this is used to have an aggregate on the RHS of a compound init
     // fixme want to exclude strings, but not normal arrays
     syntax KItem ::= initFromAggregateRHS(K, Type)
     rule T:StructOrUnionType ~> initializeSingleInit(K:K)
          => initFromAggregateRHS(K, T)
          [structural]

     syntax KItem ::= initFromStructRHS(K, Type)
     rule <k> initFromAggregateRHS(K:K, t(S:Set, structType(X:StructId)))
               => initFromStructRHS(K, t(S, structType(X)))
          ...</k>
          <curr-subobject>
               (.List => ListItem(findStruct(t(S, structType(X)))))
               L:List
          </curr-subobject>
          requires L[0]<:K =/=K next
          [structural]

     syntax KItem ::= findStruct(Type)

     rule <curr-subobject>
               ListItem(findStruct(T:Type)) (ListItem(ncle(_, T':Type)) => .List)
          ...</curr-subobject>
          requires T =/=Type T'
          [structural]

     // fixme unsafe, might have started to initialize other things
     rule <k> initFromStructRHS(K':K, t(_, structType(S:StructId))) => .K ...</k>
          <curr-subobject>
               ListItem(findStruct(t(_, structType(S:StructId))))
               ListItem(ncle(K:K, t(_, structType(S:StructId))))
               => ListItem(next)
          ...</curr-subobject>
          <incomplete-length>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incomplete-length>
          <saved-init>...
               .K => Computation(K := K')
          </saved-init>
          [structural]

     rule fillInit(SingleInit(K:K)) => initializeSingleInit(K)
          requires getKLabel(K) =/=K #klabel(`stringLiteral`)
               andBool getKLabel(K) =/=K #klabel(`wstringLiteral`)
          [structural]

     rule <k> fillInit(SingleInit(stringLiteral(S:String)))
               => fillInit-aux(SingleInit(stringLiteral(S)))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_:K, T:CharType))
               ListItem(ncle(_, t(_, arrayType(T, Len:Int))))
          ...</curr-subobject>
          requires lengthString(S) ==Int Len
          [structural]
     rule <k> fillInit(SingleInit(wstringLiteral(S:List)))
               => fillInit-aux(SingleInit(wstringLiteral(S)))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_:K, T:Type))
               ListItem(ncle(_, t(_, arrayType(T:Type, Len:Int))))
          ...</curr-subobject>
          requires isWCharType(T) andBool size(S) ==Int Len
          [structural]
     rule <k> fillInit(SingleInit(stringLiteral(S:String)))
               => fillInit(SingleInit(stringLiteral(S +String "\x00")))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_:K, T:CharType))
               ListItem(ncle(_, t(_, arrayType(T, Len:Int))))
          ...</curr-subobject>
          requires lengthString(S) <Int Len
          [structural]
     rule <k> fillInit(SingleInit(wstringLiteral(S:List)))
               => fillInit(SingleInit(wstringLiteral(S ListItem(0))))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_:K, T:Type))
                    ListItem(ncle(_, t(_, arrayType(T:Type, Len:Int))))
          ...</curr-subobject>
          requires isWCharType(T) andBool size(S) <Int Len
          [structural]
     rule <k> fillInit(SingleInit(stringLiteral(S:String)))
               => fillInit-aux(SingleInit(stringLiteral(S +String "\x00")))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_:K, T:CharType))
               ListItem(ncle(_, t(_, incompleteArrayType(T))))
          ...</curr-subobject>
          [structural]
     rule <k> fillInit(SingleInit(wstringLiteral(S:List)))
               => fillInit-aux(SingleInit(wstringLiteral(S ListItem(0))))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_:K, T:Type))
               ListItem(ncle(_, t(_, incompleteArrayType(T:Type))))
          ...</curr-subobject>
          requires isWCharType(T)
          [structural]
     rule <k> fillInit-aux(SingleInit(stringLiteral(S:String)))
               => fillInit(initHead(S))
               ~> fillInit-aux(initTail(S))
          ...</k>
          <curr-subobject> ListItem(ncle(_, _:CharType)) ...</curr-subobject>
          requires (S =/=String "")
          [structural]

     syntax KItem ::= initHead(String) [function]
     syntax KItem ::= initTail(String) [function]
     rule initHead(S:String)
          => SingleInit(tv(ordChar(firstChar(S)), t(.Set, char)))
     rule initTail(S:String)
          => SingleInit(stringLiteral(butFirstChar(S)))

     rule <k> fillInit-aux(SingleInit(wstringLiteral(ListItem(N:Int) S:List)))
               => fillInit(SingleInit(tv(N, t(.Set, cfg:wcharut))))
                    ~> fillInit-aux(SingleInit(wstringLiteral(S)))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T:Type))
          ...</curr-subobject>
          requires isWCharType(T)
          [structural]
     // fixme not sure what happens in the case of   char *x = "";
     rule fillInit-aux(SingleInit(stringLiteral(""))) => .K
          [structural]
     rule fillInit-aux(SingleInit(wstringLiteral(.List))) => .K
          [structural]

     // This rule assumes all unrollings have already occurred, so it needs to
     // be a rule. Alternatively, I've added the condition below which might be
     // enough.
     rule <k> fillInit(SingleInit(stringLiteral(S:String)))
               => initializeSingleInit(stringLiteral(S))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T:Type))
          ...</curr-subobject>
          requires notBool isCharType(T:Type)
               andBool (isBasicType(T) orBool isPointerType(T)
                    orBool isBitfieldType(T))
          [structural]
     rule <k> fillInit(SingleInit(wstringLiteral(S:List)))
               => initializeSingleInit(wstringLiteral(S))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T:Type))
          ...</curr-subobject>
          requires notBool isWCharType(T)
               andBool (isBasicType(T) orBool isPointerType(T)
                    orBool isBitfieldType(T))
          [structural]

     // c1x 6.7.9:10 If an object that has automatic storage duration is not
     // initialized explicitly, its value is indeterminate. If an object that
     // has static or thread storage duration is not initialized explicitly,
     // then:
     // -- if it has pointer type, it is initialized to a null pointer;
     // -- if it has arithmetic type, it is initialized to (positive or
     // unsigned) zero;
     // -- if it is an aggregate, every member is initialized (recursively)
     // according to these rules, and any padding is initialized to zero bits;
     // -- if it is a union, the first named member is initialized
     // (recursively) according to these rules, and any padding is initialized
     // to zero bits;

     syntax KItem ::= zero(CId)
     rule <k> zero(X:CId) => zeroType(ncle(X, T), T) ...</k>
          <types>... X |-> T:Type ...</types>

     syntax KItem ::= zeroType(K, Type)
     rule zeroType(X:K, T:Type)
          => Computation(X := tv(getZero(T), stripQualifiers(T)))
          requires isPointerType(T) orBool isArithmeticType(T)
          [structural]

     rule (.K => zeroType(X[Len -Int 1]::Expression, T))
          ~> zeroType(X:K, t(_, arrayType(T:Type, (Len:Int => Len -Int 1))))
          requires Len >Int 0
          [structural]
     rule zeroType(_, t(_, arrayType(_:Type, 0))) => .K
          [structural]

     rule <k> zeroType(X:K, t(_, structType(S:StructId)))
              => zeroStruct(X, Fields) ...</k>
          <structs>... S |-> fieldInfo(Fields:List, _, _, _) ...</structs>
          [structural]

     rule <k> zeroType(X:K, t(_, unionType(S:StructId)))
              => zeroType(X . F, T) ...</k>
          <structs>... S |-> fieldInfo(ListItem(typedDeclaration(T:Type, F:CId)) _, _, _, _) ...</structs>
          [structural]

     rule zeroType(_, _:FunctionType) => .K
          [structural]

     rule zeroType(_, t(_, flexibleArrayType(_))) => .K
          [structural]

     syntax KItem ::= zeroStruct(K, List)
     rule zeroStruct(X:K, ListItem(typedDeclaration(T:Type, F:CId)) L:List)
          => zeroType(X . F, T) ~> zeroStruct(X, L)
          requires F =/=K #NoName
          [structural]
     rule zeroStruct(X:K, ListItem(typedDeclaration(T:Type, #NoName)) L:List)
          => zeroStruct(X, L)
     rule zeroStruct(_, .List) => .K
          [structural]

     syntax CValue ::= getZero(Type) [function]
     rule getZero(_:IntegerType) => 0
     rule getZero(_:FloatType) => 0.0
     rule getZero(_:PointerType) => NullPointer

     syntax KItem ::= fillEnums(K)
     syntax KItem ::= "fillEnums-aux" "(" K "," Int ")"

     rule EnumDef(X:CId, L:K) => fillEnums(EnumDef(X, L))
          [structural]

     rule fillEnums(K:K) => fillEnums-aux(K, 0)
          [structural]

     rule fillEnums-aux(EnumDef(X:CId, list(ListItem(EnumItem(E:CId)) L:List)), Value:Int)
          => initEnum(E, tv(Value, t(SetItem(IntegerConstant), int)))
          ~> fillEnums-aux(
               EnumDef(X, list(L)), Value +Int 1)
          [structural]
     context fillEnums-aux(EnumDef(_, list(ListItem(EnumItemInit(_, HOLE:KItem)) _)), _)
     rule fillEnums-aux(EnumDef(X:CId, list(
               ListItem(EnumItemInit(E:CId, R:RValue)) L:List)), _)
          => initEnum(E, R)
          ~> fillEnums-aux(
               EnumDef(X, list(L)), incrementIfInt(value(R)))
          [structural]
     rule fillEnums-aux(EnumDef(_, list(.List)), _) => .K
          [structural]

     syntax Int ::= incrementIfInt(K) [function]
     rule incrementIfInt(I:Int) => I +Int 1
     rule incrementIfInt(_) => 0 [owise] //in this case, the configuration should be about to get stuck, so it doesn't matter

     syntax KItem ::= initEnum(CId, RValue)
     rule <k> initEnum(X:CId, tv(Value:Int, T:Type)) => addEnum(X, Value) ...</k>
          requires isIntegerType(T) andBool IntegerConstant in getModifiers(T)
     rule (.K => CV("CDE1", "Enum initializer not an integer constant expression.", "6.7.2.2:2"))
          ~> initEnum(_, R:RValue)
          requires isHold(R) orBool notBool isIntegerType(type(R)) orBool notBool IntegerConstant in getModifiers(type(R))

endmodule
