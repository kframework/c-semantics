module C-DECL-INITIALIZER-SYNTAX
     imports BASIC-K
     imports COMMON-SORTS

     syntax KResult ::= initializer(K)

     // CId, type, initializer.
     syntax KItem ::= figureInit(CId, K, K) [strict(2)]

endmodule

module C-DECL-INITIALIZER
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports K-REFLECTION
     imports LIST
     imports STRING
     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-EXPR-SYNTAX
     imports C-TYPING-SYNTAX

     rule figureInit(X:CId, T:Type, CodeLoc(K:K, L::CabsLoc))
          => CodeLoc(.K, L) ~> figureInit(X, T, K)
          [structural]

     rule figureInit(X:CId, T:Type, NoInit()) => initValue(X, T, .K)
          [structural]

     // aggregates
     rule figureInit(X:CId, T:AggregateOrUnionType, CompoundInit(L:K))
          => giveType(X, T)
          ~> figureInit-aux(X, T, startInit(T, X, CompoundInit(L)))
          [structural]

     rule figureInit(
               _,
               t(_, _, arrayType(_:CharType, Len:Int)),
               (SingleInit(StringLiteral(S:String))
               => CompoundInit(list(ListItem(InitFragment(NextInit(),
                    SingleInit(StringLiteral(S)))))))
          )
          requires lengthString(S) <=Int Len
          [structural]

     rule figureInit(
               _,
               t(_, _, arrayType(T:Type, Len:Int)),
               (SingleInit(WStringLiteral(list(S:List)))
               => CompoundInit(list(ListItem(InitFragment(NextInit(),
                    SingleInit(WStringLiteral(list(S))))))))
          )
          requires isWCharType(T) andBool (size(S) <=Int Len)
          [structural]

     rule figureInit(_, t(_, _, (incompleteArrayType(T:CharType)
          => arrayType(T, lengthString(S) +Int 1))),
               SingleInit(StringLiteral(S:String)))
          [structural]

     rule figureInit(_, t(_, _, (incompleteArrayType(T:Type)
          => arrayType(T, size(S) +Int 1))),
               SingleInit(WStringLiteral(list(S:List))))
          requires isWCharType(T)
          [structural]

     rule figureInit(X:CId, t(Qs::Quals, Mods::Set, incompleteArrayType(T:CharType)),
               CompoundInit(list(ListItem(InitFragment(NextInit(),
               SingleInit(StringLiteral(S:String)))))))
          => figureInit(X, t(Qs, Mods, incompleteArrayType(T)),
               SingleInit(StringLiteral(S)))
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
               CompoundInit(list(ListItem(InitFragment(NextInit(), SingleInit(K:K))))))
          => figureInit-aux(X, T,
               initializer(Computation(ncle(X, T) := K)))
          requires notBool isAggregateOrUnionType(T)
          [structural]

     rule (.K => UNDEF("CDI1",
               "Initializer for scalar contains multiple expressions."))
          ~> figureInit(_, T:Type, CompoundInit(list(L:List)))
          requires notBool isAggregateOrUnionType(T)
               andBool size(L) >Int 1

     rule (.K => UNDEF("CDI2",
               "Initializer for scalar contains multiple levels of braces."))
          ~> figureInit(_, T:Type,
               CompoundInit(list(ListItem(InitFragment(NextInit(), CompoundInit(_))))))
          requires notBool isAggregateOrUnionType(T)

     rule (.K => UNDEF("CDI3",
               "Invalid initializer for aggregate type."))
          ~> figureInit(_, t(_, _, incompleteArrayType(T::Type)), SingleInit(K:K))
          requires (notBool isWCharType(T) orBool getKLabel(K) =/=K #klabel(`WStringLiteral`))
               andBool (notBool isCharType(T) orBool getKLabel(K) =/=K #klabel(`StringLiteral`))

     rule <k> figureInit-aux(_:CId, t(_, _,
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
               .List => ListItem(down) ListItem(ncle(ncle(X, T), T))
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

     syntax KItem ::= "next" | "down" | "block"

     rule <curr-subobject>
               (ListItem(down) => ListItem(ncle(K[[0]], T)))
               ListItem(ncle(K:K, t(_, _, arrayType(T::Type, _))))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (ListItem(down) => ListItem(ncle(K[[0]], T)))
               ListItem(ncle(K:K, t(_, _, incompleteArrayType(T::Type))))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (ListItem(down) => ListItem(firstField(K, findFieldNames(T), T)))
               ListItem(ncle(K:K, T:StructOrUnionType))
          ...</curr-subobject>
          [structural]

     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K:K[[N::Int]], T::Type))
                    => ListItem(ncle(K[[N +Int 1]], T)))
               ListItem(ncle(K, t(_, _, arrayType(_, Len::Int))))
          ...</curr-subobject>
          requires Len >Int N +Int 1
          [structural]
     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K:K[[N::Int]], _)) => ListItem(noMoreIndices))
               ListItem(ncle(K:K, t(_, _, arrayType(_, Len::Int))))
          ...</curr-subobject>
          requires notBool Len >Int N +Int 1
          [structural]
     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K:K[[N::Int]], T::Type))
                    => ListItem(ncle(K[[N +Int 1]], T)))
               ListItem(ncle(K, t(_, _, incompleteArrayType(_))))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K:K . F::CId, _))
                    => ListItem(followingField(K, F, findFieldNames(T), T)))
               ListItem(ncle(K:K, T:StructType))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K:K . _, _)) => ListItem(noMoreFields))
               ListItem(ncle(K:K, _:UnionType))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               ListItem(noMoreFields => next)
               ListItem(ncle(_ . _::CId, _))
          ...</curr-subobject>
          [structural]

     syntax KItem ::= "noMoreFields" | "noMoreIndices"
     syntax KItem ::= thisField(K, CId, List, StructOrUnionType) [function]
                    | followingField(K, CId, List, StructType) [function]
                    | firstField(K, List, StructOrUnionType) [function]

     rule thisField(K:K, F::CId, ListItem(F) _::List, T::StructOrUnionType)
          => ncle(K . F, findFieldType(F, T))
     rule thisField(_, F::CId, (ListItem(F'::CId) => .List) _, _)
          requires F =/=K F'
     rule thisField(_, _, _, _) => noMoreFields [owise]

     rule followingField(K:K, F::CId, ListItem(F) L::List, T::StructType)
          => firstField(K, L, T)
     rule followingField(_, F::CId, (ListItem(F'::CId) => .List) _, _)
          requires F =/=K F'
     rule followingField(_, _, _, _) => noMoreFields [owise]

     rule firstField(K:K, (ListItem(_:NoName) => .List) _, _)
     rule firstField(K:K, ListItem(F::CId) _, T::StructOrUnionType)
          => ncle(K . F, findFieldType(F, T))
          requires notBool isNoName(F)
     rule firstField(_, _, _) => noMoreFields [owise]

     rule <k> fillInit(InitFragment(NextInit(), Exp:K)) => fillInit(Exp) ...</k>
          <curr-subobject>
               ListItem(K:K)
          ...</curr-subobject>
          requires K =/=K next andBool K =/=K noMoreFields
          [structural]

     rule <k> (.K => CV("CDI4", "Attempting to initialize nonexistent member."))
               ~> fillInit(InitFragment(NextInit(), _))
          ...</k>
          <curr-subobject>
               ListItem(K:K) L::List
          </curr-subobject>
          requires K ==K noMoreIndices orBool
               (K ==K noMoreFields andBool notBool isFieldAccess(L))

     syntax Bool ::= isFieldAccess(List) [function]
     rule isFieldAccess(ListItem(ncle(_ . _::CId, _)) _) => true
     rule isFieldAccess(_) => false [owise]

     rule <k> fillInit(CompoundInit(list(L::List)))
               => fillInits(L)
               ~> finishCompoundInit(ListItem(next) ListItem(ncle(K, T)) Remainder)
          ...</k>
          <curr-subobject>
               (.List => ListItem(down))
               ListItem(ncle(K:K, T:AggregateOrUnionType))
               Remainder::List
          </curr-subobject>
          <curr-object>
               .List => ListItem(ncle(K, T))
          ...</curr-object>
          [structural]

     syntax KItem ::= finishCompoundInit(List)
     rule <k> finishCompoundInit(L::List) => .K ...</k>
          <curr-subobject> _ => L </curr-subobject>
          <curr-object>
               ListItem(ncle(_, _)) => .List
          ...</curr-object>
          [structural]

     rule <k> (.K => CV("CDI5", "Unexpected compound initializer (possibly attempting to directly initialize an anonymous member)."))
               ~> fillInit(CompoundInit(list(L::List)))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T::Type))
          ...</curr-subobject>
          requires notBool isAggregateOrUnionType(T)
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
               ListItem(block) (.List => ListItem(thisField(K, F, findFieldNames(T), T)))
                    ListItem(ncle(K:K, T:StructOrUnionType))
          ...</curr-subobject>
          [structural]

     rule <k> buildDesignator(NextInit()) => NextInit() ...</k>
          <curr-subobject> ListItem(block) => .List ...</curr-subobject>
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

     syntax Int ::= getTopArrayUse(K) [function]
     rule getTopArrayUse(_:KResult) => 0
     // +1 for length instead of index
     rule getTopArrayUse(_:KResult[[N:Int]]) => N +Int 1
     rule getTopArrayUse(K:K . _:CId) => getTopArrayUse(K)
     rule getTopArrayUse((K:K[[N:Int]])[[_]]) => getTopArrayUse(K[[N]])
     rule getTopArrayUse((K:K . _:CId)[[_]]) => getTopArrayUse(K)

     syntax KItem ::= initializeSingleInit(K) [strict]

     rule (.K => typeof(K)) ~> initializeSingleInit(K:KResult)
          [structural]
     rule (typeof(T:Type) => T) ~> initializeSingleInit(_)
          [structural]

     rule <k> T':Type ~> initializeSingleInit(K':KResult) => .K ...</k>
          <curr-subobject>
               (.List => ListItem(next)) ListItem(ncle(K:K, T::Type))
          ...</curr-subobject>
          <incomplete-length>
               N::Int => maxInt(N, getTopArrayUse(K))
          </incomplete-length>
          <saved-init>...
               .K => Computation(K := K')
          </saved-init>
          requires notBool isAggregateOrUnionType(T)
               andBool notBool isStructOrUnionType(T')
          [structural]
     rule <k> T':Type ~> initializeSingleInit(_) ...</k>
          <curr-subobject>
               (.List => ListItem(down)) ListItem(ncle(K:K, T::Type))
          ...</curr-subobject>
          requires isAggregateOrUnionType(T)
               andBool notBool isAggregateOrUnionType(T')
          [structural]
     syntax KItem ::= initFromAggregateRHS(K, Type)
     rule T:StructOrUnionType ~> initializeSingleInit(K:KResult)
          => initFromAggregateRHS(K, T)
          [structural]

     syntax KItem ::= initFromStructRHS(K, Type)
     rule <k> initFromAggregateRHS(K:K, t(Qs::Quals, S::Set, structType(X::TagId)))
               => initFromStructRHS(K, t(Qs, S, structType(X)))
          ...</k>
          <curr-subobject>
               (.List => ListItem(findStruct(t(Qs, S, structType(X)))))
               L:List
          </curr-subobject>
          requires {L[0]}<:K =/=K next
          [structural]

     syntax KItem ::= findStruct(Type)

     rule <curr-subobject>
               ListItem(findStruct(T::Type)) (ListItem(ncle(_, T'::Type)) => .List)
          ...</curr-subobject>
          requires T =/=Type T'
          [structural]

     // fixme unsafe, might have started to initialize other things
     rule <k> initFromStructRHS(K':K, t(_, _, structType(S::TagId))) => .K ...</k>
          <curr-subobject>
               (ListItem(findStruct(t(_, _, structType(S::TagId))))
               => ListItem(next))
               ListItem(ncle(K:K, t(_, _, structType(S::TagId))))
          ...</curr-subobject>
          <incomplete-length>
               N:Int => maxInt(N, getTopArrayUse(K))
          </incomplete-length>
          <saved-init>...
               .K => Computation(K := K')
          </saved-init>
          [structural]

     rule fillInit(SingleInit(K:K)) => initializeSingleInit(K)
          requires getKLabel(K) =/=K #klabel(`StringLiteral`)
               andBool getKLabel(K) =/=K #klabel(`WStringLiteral`)
          [structural]

     rule <k> fillInit(SingleInit(StringLiteral(_))) ...</k>
          <curr-subobject>
               (.List => ListItem(down))
               ListItem(ncle(_, t(_, _, arrayType(T:CharType, _))))
          ...</curr-subobject>
          [structural]
     rule <k> fillInit(SingleInit(WStringLiteral(_))) ...</k>
          <curr-subobject>
               (.List => ListItem(down))
               ListItem(ncle(_, t(_, _, arrayType(T::Type, _))))
          ...</curr-subobject>
          requires isWCharType(T)
          [structural]

     rule <k> fillInit(SingleInit(StringLiteral(S:String)))
               => fillInit-aux(SingleInit(StringLiteral(S)))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T:CharType))
               ListItem(ncle(_, t(_, _, arrayType(T, Len::Int))))
          ...</curr-subobject>
          requires lengthString(S) ==Int Len
          [structural]
     rule <k> fillInit(SingleInit(WStringLiteral(list(S:List))))
               => fillInit-aux(SingleInit(WStringLiteral(list(S))))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T::Type))
               ListItem(ncle(_, t(_, _, arrayType(T, Len:Int))))
          ...</curr-subobject>
          requires isWCharType(T) andBool size(S) ==Int Len
          [structural]
     rule <k> fillInit(SingleInit(StringLiteral(S:String)))
               => fillInit(SingleInit(StringLiteral(S +String "\x00")))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T:CharType))
               ListItem(ncle(_, t(_, _, arrayType(T, Len:Int))))
          ...</curr-subobject>
          requires lengthString(S) <Int Len
          [structural]
     rule <k> fillInit(SingleInit(WStringLiteral(list(S:List))))
               => fillInit(SingleInit(WStringLiteral(list(S ListItem(0)))))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T::Type))
               ListItem(ncle(_, t(_, _, arrayType(T, Len:Int))))
          ...</curr-subobject>
          requires isWCharType(T) andBool size(S) <Int Len
          [structural]
     rule <k> fillInit(SingleInit(StringLiteral(S:String)))
               => fillInit-aux(SingleInit(StringLiteral(S +String "\x00")))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T:CharType))
               ListItem(ncle(_, t(_, _, incompleteArrayType(T))))
          ...</curr-subobject>
          [structural]
     rule <k> fillInit(SingleInit(WStringLiteral(list(S:List))))
               => fillInit-aux(SingleInit(WStringLiteral(list(S ListItem(0)))))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T::Type))
               ListItem(ncle(_, t(_, _, incompleteArrayType(T))))
          ...</curr-subobject>
          requires isWCharType(T)
          [structural]
     rule <k> fillInit-aux(SingleInit(StringLiteral(S:String)))
               => fillInit(initHead(S))
               ~> fillInit-aux(initTail(S))
          ...</k>
          <curr-subobject> ListItem(ncle(_, _:CharType)) ...</curr-subobject>
          requires S =/=String ""
          [structural]

     syntax KItem ::= initHead(String) [function]
     syntax KItem ::= initTail(String) [function]
     rule initHead(S:String)
          => SingleInit(tv(ordChar(firstChar(S)), utype(char)))
     rule initTail(S:String)
          => SingleInit(StringLiteral(butFirstChar(S)))

     rule <k> fillInit-aux(SingleInit(WStringLiteral(list(ListItem(N:Int) S:List))))
               => fillInit(SingleInit(tv(N, utype(cfg:wcharut))))
                    ~> fillInit-aux(SingleInit(WStringLiteral(list(S))))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T:Type))
          ...</curr-subobject>
          requires isWCharType(T)
          [structural]
     rule <k> fillInit-aux(SingleInit(StringLiteral(""))) => .K ...</k>
          <curr-subobject>
               ListItem(noMoreIndices => next)
          ...</curr-subobject>
          [structural]
     rule <k> fillInit-aux(SingleInit(WStringLiteral(list(.List)))) => .K ...</k>
          <curr-subobject>
               ListItem(noMoreIndices => next)
          ...</curr-subobject>
          [structural]

     // This rule assumes all unrollings have already occurred, so it needs to
     // be a rule. Alternatively, I've added the condition below which might be
     // enough.
     rule <k> fillInit(SingleInit(StringLiteral(S:String)))
               => initializeSingleInit(StringLiteral(S))
          ...</k>
          <curr-subobject>
               ListItem(ncle(_, T:Type))
          ...</curr-subobject>
          requires notBool isCharType(T:Type)
               andBool (isBasicType(T) orBool isPointerType(T)
                    orBool isBitfieldType(T))
          [structural]
     rule <k> fillInit(SingleInit(WStringLiteral(list(S:List))))
               => initializeSingleInit(WStringLiteral(list(S)))
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

     syntax KItem ::= zeroType(K, Type) [function]
     rule zeroType(X:K, T::Type)
          => Computation(X := tv(getZero(T), utype(T)))
          requires isPointerType(T) orBool isArithmeticType(T)
     rule zeroType(X:K, t(Qs::Quals, Mods::Set, arrayType(T::Type, Len::Int)))
          => zeroType(X[Len -Int 1]::Expression, T)
          ~> zeroType(X, t(Qs, Mods, arrayType(T, Len -Int 1)))
          requires Len >Int 0
     rule zeroType(_, _) => .K [owise]

     rule zeroType(X:K, T:StructType) => zeroStruct(X, findFieldNames(T), T)
     rule zeroType(X:K, T:UnionType)
          => zeroStruct(X, ListItem({(findFieldNames(T))[0]}<:K), T)

     rule zeroType(_, _:FunctionType) => .K

     rule zeroType(_, t(_, _, flexibleArrayType(_))) => .K

     syntax KItem ::= zeroStruct(K, List, StructOrUnionType) [function]
     rule zeroStruct(X:K, ListItem(F::CId) L:List, T::StructOrUnionType)
          => zeroType(X . F, findFieldType(F, T)) ~> zeroStruct(X, L, T)
     rule zeroStruct(_, _, _) => .K [owise]

     syntax CValue ::= getZero(Type) [function]
     rule getZero(t(_, _, T:SimpleFloatType)) => zeroCFloat(utype(T))
     rule getZero(_:PointerType) => NullPointer
     rule getZero(_) => 0 [owise]

endmodule
