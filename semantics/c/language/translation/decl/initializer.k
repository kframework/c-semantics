module C-DECL-INITIALIZER-SYNTAX
     imports BASIC-K
     imports COMMON-SORTS
     imports C-TYPING-SORTS

     syntax KResult ::= initializer(K)

     // CId, type, initializer.
     syntax KItem ::= figureInit(CId, K, K) [strict(2)]

     syntax Bool ::= isAutoType(Type) [function]

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
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
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
               initializer(Initializer(ncle(X, T) := K)))
          requires notBool isArrayType(T)
          [structural]
     // c1x 6.7.8:11
     rule figureInit(X:CId, T:Type,
               CompoundInit(list(ListItem(InitFragment(NextInit(), SingleInit(K:K))))))
          => figureInit-aux(X, T,
               initializer(Initializer(ncle(X, T) := K)))
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

     // id, type, initializer
     syntax KItem ::= "figureInit-aux" "(" CId "," Type "," K ")" [strict(3)]
     rule <k> figureInit-aux(_:CId, t(_, _,
                    (incompleteArrayType(T:Type)
                    => arrayType(T, N))), initializer(_))
          ...</k>
          <incomplete-length> N:Int </incomplete-length>
          [structural]
     rule (.K => typeof(Expr)) ~> figureInit-aux(_:CId, t(_, _, auto-type),
               initializer(Initializer(_ := Expr:K)))
          [structural]
     rule (typeof(T:Type) => .K) ~> figureInit-aux(_:CId, t(_, _, auto-type) => T, _)
          [structural]

     rule figureInit-aux(X:CId, T:Type, initializer(K:K))
          => giveType(X, T) ~> elaborateInit(K) ~> initValue(X, T, .K)
          requires isCompleteType(T)
               andBool notBool isAutoType(T)
     rule (elaborateDone(K:K) => .K) ~> initValue(_, _, (.K => K))

     rule isAutoType(t(_, _, auto-type)) => true
     rule isAutoType(_) => false [owise]

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
          <saved-init>... .K => Zero(X) </saved-init>
          [structural]

     rule fillInits(ListItem(InitFragment(K:K, Exp:K)) L:List)
          => fillInit(InitFragment(K, Exp)) ~> fillInits(L)
          [structural]
     rule fillInits(.List) => .K
          [structural]

     syntax SubObjectControl ::= "next" | "down" | "block"

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
               (ListItem(next) ListItem(ncle(K::InitLValue [[N::Int]], T::Type))
                    => ListItem(ncle(K[[N +Int 1]], T)))
               ListItem(ncle(K, t(_, _, arrayType(_, Len::Int))))
          ...</curr-subobject>
          requires Len >Int N +Int 1
          [structural]
     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K::InitLValue [[N::Int]], _)) => ListItem(noMoreIndices))
               ListItem(ncle(K, t(_, _, arrayType(_, Len::Int))))
          ...</curr-subobject>
          requires notBool Len >Int N +Int 1
          [structural]
     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K::InitLValue [[N::Int]], T::Type))
                    => ListItem(ncle(K[[N +Int 1]], T)))
               ListItem(ncle(K, t(_, _, incompleteArrayType(_))))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K::InitLValue .init F::CId, _))
                    => ListItem(followingField(K, F, findFieldNames(T), T)))
               ListItem(ncle(K, T:StructType))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (ListItem(next) ListItem(ncle(K::InitLValue .init _, _)) => ListItem(noMoreFields))
               ListItem(ncle(K, _:UnionType))
          ...</curr-subobject>
          [structural]
     rule <curr-subobject>
               (ListItem(noMoreFields) => ListItem(next))
               ListItem(ncle(_ .init _::CId, _))
          ...</curr-subobject>
          [structural]

     syntax KItem ::= "noMoreFields" | "noMoreIndices"
     syntax KItem ::= thisField(K, CId, List, StructOrUnionType) [function]
                    | followingField(K, CId, List, StructType) [function]
                    | firstField(K, List, StructOrUnionType) [function]

     rule thisField(K:K, F::CId, ListItem(F) _::List, T::StructOrUnionType)
          => ncle(K .init F, findFieldType(F, T))
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
          => ncle(K .init F, findFieldType(F, T))
          requires notBool isNoName(F)
     rule firstField(_, _, _) => noMoreFields [owise]

     rule <k> fillInit(InitFragment(NextInit(), Exp:K)) => fillInit(Exp) ...</k>
          <curr-subobject>
               ListItem(K:KItem)
          ...</curr-subobject>
          requires K =/=K next andBool K =/=K noMoreFields
          [structural]

     rule <k> (.K => CV("CDI4", "Attempting to initialize nonexistent member."))
               ~> fillInit(InitFragment(NextInit(), _))
          ...</k>
          <curr-subobject>
               ListItem(K:KItem) L::List
          </curr-subobject>
          requires K ==K noMoreIndices orBool
               (K ==K noMoreFields andBool notBool isFieldAccess(L))

     syntax Bool ::= isFieldAccess(List) [function]
     rule isFieldAccess(ListItem(ncle(_ .init _::CId, _)) _) => true
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
                    ListItem(ncle(K::InitLValue, T:ArrayType))
          ...</curr-subobject>
          [structural]

     syntax Int ::= getTopArrayUse(K) [function]
     rule getTopArrayUse(_:KResult) => 0
     // +1 for length instead of index
     rule getTopArrayUse(_:LValue[[N::Int]]) => N +Int 1
     rule getTopArrayUse(K::InitLValue .init _) => getTopArrayUse(K)
     rule getTopArrayUse((K::InitLValue [[N::Int]])[[_]]) => getTopArrayUse(K[[N]])
     rule getTopArrayUse((K::InitLValue .init _)[[_]]) => getTopArrayUse(K)

     syntax K ::= trapPadding(K) [function]
     rule trapPadding(K::InitLValue .init F::CId) => InitPadding(K, F) ~> trapPadding(K)
     rule trapPadding(K::InitLValue [[_]]) => trapPadding(K)
     rule trapPadding(_:LValue) => .K

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
               .K => trapPadding(K) ~> Initializer(K := K')
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
          requires {L[0]}<:KItem =/=K next
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
               .K => trapPadding(K) ~> Initializer(K := K')
          </saved-init>
          [structural]

     rule fillInit(SingleInit(K:K)) => initializeSingleInit(K)
          requires getKLabel(K) =/=K #klabel(`StringLiteral`)
               andBool getKLabel(K) =/=K #klabel(`WStringLiteral`)
          [structural]

     rule <k> fillInit(SingleInit(StringLiteral(_))) ...</k>
          <curr-subobject>
               (.List => ListItem(down))
               ListItem(ncle(_, t(_, _, arrayType(_:CharType, _))))
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
               ListItem(K:KItem) => ListItem(next)
          ...</curr-subobject>
          requires notBool isSubObjectControl(K)
          [structural]
     rule <k> fillInit-aux(SingleInit(WStringLiteral(list(.List)))) => .K ...</k>
          <curr-subobject>
               ListItem(K:KItem) => ListItem(next)
          ...</curr-subobject>
          requires notBool isSubObjectControl(K)
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

endmodule
