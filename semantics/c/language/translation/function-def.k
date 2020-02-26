module C-FUNCTION-DEF-SYNTAX
     imports BASIC-K
     imports COMMON-SORTS
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS

     syntax KItem ::= initFunction(KItem, CId, Type) [strict(1)]
endmodule

module C-FUNCTION-DEF
     imports C-FUNCTION-DEF-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports LIST
     imports STRING
     imports COMPAT-SYNTAX
     imports OPTIONS-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-ANNOTATION-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-PROCESS-LABEL-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-SYNTAX

     // we need to ensure that the use of &X in the function definition
     // does not count as linking dependency
     syntax KItem ::= doNotRecordLinkingDeps(KItem)
                    | #doNotRecordLinkingDeps()

     rule <k> doNotRecordLinkingDeps(X::KItem)
          => X ~> #doNotRecordLinkingDeps()
          ...</k>
          <do-not-record-linking-deps> false => true </do-not-record-linking-deps>

     rule <k> (X:KResult ~> #doNotRecordLinkingDeps())
          => X
          ...</k>
          <do-not-record-linking-deps> true => false </do-not-record-linking-deps>

     rule FunctionDefinition(typedDeclaration(t(... st: functionType(...)) #as T::Type, X:CId), Blk:KItem)
          => declare'(
               typedDeclaration(toPrototype(emptyToVoid(T)), X),
               initializer(initFunction(
                    doNotRecordLinkingDeps(&(X)),
                    X,
                    // The return and parameter types from the definition.
                    t(getQualifiers(T), getModifiers(T), functionType(utype(elideDeclParams(innerType(T))),
                         elideList(getParams(emptyToVoid(T)))))
               ))
          )
          ~> processFunDef(X, Blk)
          requires notBool hasDupParams(T)
          [structural]
     rule (.K => CV("FD1", "Duplicate parameters in "
               +String "function definition."))
          ~> FunctionDefinition(typedDeclaration(T:Type, _), _)
          requires hasDupParams(T)

     // TODO(chathhorn): possibly check that old-style declarations are
     // promoted types?

     syntax Type ::= emptyToVoid(Type) [function]
     rule emptyToVoid(t(... st: functionType(...)) #as T::Type)
          => setParams(T, ListItem(typedDeclaration(type(void), #NoName)))
          requires (getParams(T) ==K .List)
     rule emptyToVoid(T:Type) => T [owise]

     syntax KItem ::= processFunDef(CId, K)
     rule <k> processFunDef(X:CId, Blk:K)
               => checkFunDefType(X, elideDeclParams(DefT))
               ~> staticEval(X, Base, DefT, Blk)
          ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <functions>...
               Base |-> functionObject(... defType: DefT::Type)
          ...</functions>
          <curr-function> _ => Base </curr-function>
          [structural]

     syntax KItem ::= checkFunDefType(CId, Type)
     rule checkFunDefType(X:CId, t(_, _, functionType(R::UType, P:List))) => .K
          requires notBool isArrayOrFunctionUType(R)
               andBool areVoidOrComplete(P)
               andBool (X =/=K Identifier("main"))
          [structural]
     rule checkFunDefType(X:CId, T:Type) => checkMainDef(T)
          requires isVoidOrComplete(innerType(T))
               andBool areVoidOrComplete(getParams(T))
               andBool (X ==K Identifier("main"))
          [structural]
     rule (.K => CV("FD2", "Invalid return type in function definition."))
          ~> checkFunDefType(_, t(_, _, functionType(arrayOrFunctionUType, _)))
          [structural]
     rule (.K => CV("FD3", "Incomplete parameter type in "
               +String "function definition."))
          ~> checkFunDefType(_, T:Type)
          requires notBool areVoidOrComplete(getParams(T))
          [structural]

     syntax Bool ::= isVoidOrComplete(K) [function]
     rule isVoidOrComplete(T:Type)
          => isCompleteType(T) orBool isVoidType(T)
               orBool isIncompleteArrayType(T)
     rule isVoidOrComplete(_) => true [owise]

     syntax Bool ::= areVoidOrComplete(List) [function]
     rule areVoidOrComplete(ListItem(K:KItem) L:List) => false
          requires notBool isVoidOrComplete(K)
     rule areVoidOrComplete(.List) => true
     rule areVoidOrComplete((ListItem(_) => .List) _) [owise]

     syntax KItem ::= checkMainDef(Type)
     rule checkMainDef(t(_, _, functionType(ut(_, int),
               ListItem(t(_, _, void)))))
          => .K
          [structural]
     rule checkMainDef(t(_, Mods:Set, functionType(ut(_, int),
               ListItem(t(_, _, int)) ListItem(T:Type))))
          => .K
          requires (notBool oldStyle in Mods) andBool isArgvType(T)
          [structural]
     rule (.K => UNDEF("FD4", "Definition of main requires a prototype.") )
          ~> checkMainDef(t(_, Mods:Set, functionType(ut(_, int), ListItem(T:Type) _)))
          requires (oldStyle in Mods) andBool notBool isVoidType(T)
          [structural]
     rule (.K => UNDEF("FD5", "Function main must return an int.") )
          ~> checkMainDef(t(_, _, functionType(ut(_, T::SimpleUType), _)))
          requires notBool isSimpleIntType(T)
          [structural]
     rule (.K => UNDEF("FD6", "If main has parameters, the type of the first parameter must be equivalent to int.") )
          ~> checkMainDef(t(_, _, functionType(_, ListItem(t(_, _, T::SimpleType)) _)))
          requires notBool isSimpleIntType(T) andBool T =/=K void
          [structural]
     rule (.K => UNDEF("FD7", "If main has parameters, the type of the second parameter must be equivalent to char**.") )
          ~> checkMainDef(t(_, _, functionType(_, ListItem(_) ListItem(T:Type))))
          requires notBool isArgvType(T)
          [structural]
     rule (.K => UNDEF("FD8", "Function main must have zero or two parameters.") )
          ~> checkMainDef(t(_, _, functionType(_, Params::List)))
          requires size(Params) >Int 2
          [structural]
     rule (.K => UNDEF("FD9", "Function main must have zero or two parameters.") )
          ~> checkMainDef(t(_, _, functionType(_, ListItem(t(_, _, T::SimpleType)))))
          requires T =/=K void
          [structural]

     syntax Bool ::= isArgvType(Type) [function]
     rule isArgvType(t(_, _, incompleteArrayType(t(quals(.Set), _, pointerType(t(quals(.Set), _, char))))))
          => true
     rule isArgvType(t(_, _, pointerType(t(quals(.Set), _, pointerType(t(quals(.Set), _, char))))))
          => true
     rule isArgvType(_) => false [owise]

     rule <k> initFunction(tv(Loc:SymLoc, T::UType), X:CId, DefT::Type) => .K ...</k>
          <elab>... .K => initFunction(doNotRecordLinkingDeps(&(X)), X, DefT) </elab>
          requires isLinkerLoc(Loc)
     rule <k> initFunction(tv(Loc:SymLoc, ut(_, pointerType(t(... st: functionType(...))))), X::CId, DefT::Type)
               => .K
          ...</k>
          <functions> M:Map => M[base(Loc) <- functionObject(X, DefT, .List, .Map)] </functions>
          requires notBool isLinkerLoc(Loc)

     syntax K ::= safeBody(CId, K) [function]
     rule safeBody(X:CId, Blk:K)
          => Blk ~> Return(NothingExpression())
          requires X =/=K Identifier("main")
     rule safeBody(Identifier("main"), Blk:K)
          => Blk ~> Return(tv(0, utype(int)))

     syntax KItem ::= staticEval(CId, SymBase, Type, K)
     rule staticEval(X::CId, Base::SymBase, DefT::Type, Blk:K)
          => scope(blockScope(X, Base, 0),
               generateRuleAnnotation(X)
               ~> elaborate(dummyBind(getParams(DefT)) ~> Label(funLabel, safeBody(X, Blk)))
               ~> calculateGotoMap(.K))

     rule elaborateDone(K:K) ~> calculateGotoMap(.K)
          => calculateGotoMap(K)

     syntax Bool ::= hasDupParams(Type) [function]
     rule hasDupParams(t(_, _, functionType(_, P:List))) => hasDupIds(P)
     rule hasDupParams(_) => false [owise]

     // TODO(liyili2): no associative matching in Java currently, we will do it once we
     // have the associative matching.
     syntax Bool ::= hasDupIds(List) [function]
     syntax Bool ::= idInList(CId, List) [function]

     rule idInList(_, .List) => false
     rule idInList(X:CId, ListItem(typedDeclaration(_, X)) _)
          => true
     rule idInList(X:CId, ListItem(typedDeclaration(_, Y:CId)) Tail:List => Tail)
          requires X =/=K Y
     rule idInList(_, ListItem(_:Type) Tail:List => Tail)
     rule idInList(_, ListItem(_:Variadic) Tail:List => Tail)

     rule hasDupIds(.List) => false
     rule hasDupIds(
               ListItem(typedDeclaration(_, X:CId))
               Tail:List)
          => true
          requires idInList(X, Tail)
     rule hasDupIds(
               ListItem(typedDeclaration(_, X:CId))
               Tail:List => Tail)
          requires notBool idInList(X, Tail)
     rule hasDupIds(ListItem(_:Type) Tail:List => Tail)
     rule hasDupIds(ListItem(_:Variadic) Tail:List => Tail)

     syntax KItem ::= dummyBind(List)
     rule dummyBind(.List) => .K
          [structural]
     rule dummyBind(ListItem(variadic)) => .K
          [structural]
     rule dummyBind(ListItem(typedDeclaration(t(... st: void), _))) => .K
          [structural]
     rule dummyBind(ListItem(typedDeclaration(T:Type, X:CId)) Params:List)
          => addToEnv(X, T, nonStatic)
          ~> giveType(X, T)
          ~> dummyBind(Params)
          requires notBool isVoidType(T)
          [structural]

     // Falling back on native implementation of functions:

     // Function with external linkage.
     rule <k> OtherStatement() => lintFunElide(X) ...</k>
          <external-defs>... X |-> Def::SymBase => .Map ...</external-defs>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> Env::Map => Env[X <- obj(0, 0, nativeSymbol(S))] </genv>
          <curr-scope> blockScope(... functionId: Identifier(S::String) #as X::CId) </curr-scope>
          <block-stack>... ListItem(<block-control>... <env> Env::Map => Env[X <- obj(0, 0, nativeSymbol(S))] </env> ...</block-control>) </block-stack>
          <function-tus>... .Map => X |-> Tu </function-tus>
          <options> Opts::Set </options>
          requires notBool (NoNativeFallback() in Opts)
               andBool S =/=String "main"
     // Function with internal linkage.
     rule <k> OtherStatement() => lintFunElide(X) ...</k>
          <external-defs> Exts::Map </external-defs>
          <external-types> ExtTypes::Map => ExtTypes[Identifier(S +String Uuid) <- T] </external-types>
          <types>... X |-> T::Type ...</types>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv>... X |-> Def::SymBase ...</genv>
          <curr-scope> blockScope(... functionId: Identifier(S::String) #as X::CId) </curr-scope>
          <linkings> Linkings::Map => Linkings[Def <- obj(0, 0, nativeSymbol(S +String Uuid))] </linkings>
          <function-tus> FunctionTUs::Map => FunctionTUs[Identifier(S +String Uuid) <- Tu] </function-tus>
          <uuid> Uuid::String </uuid>
          <options> Opts::Set </options>
          requires notBool (X in_keys(Exts))
               andBool notBool (Identifier(S +String Uuid) in_keys(ExtTypes))
               andBool notBool isNativeLoc(Def)
               andBool notBool (NoNativeFallback() in Opts)
               andBool S =/=String "main"
     rule <k> OtherStatement() => .K ...</k>
          <external-types> ExtTypes::Map </external-types>
          <genv>... X |-> Def::SymBase ...</genv>
          <curr-scope> blockScope(... functionId: Identifier(S::String) #as X::CId) </curr-scope>
          <uuid> Uuid::String </uuid>
          requires isNativeLoc(Def)
               orBool (Identifier(S +String Uuid) in_keys(ExtTypes))
     rule <k> OtherStatement() => .K ...</k>
          <options> Opts::Set </options>
          <curr-scope> S::Scope </curr-scope>
          requires notBool isBlockScope(S)
               orBool NoNativeFallback() in Opts
               orBool isMainScope(S)

     syntax Bool ::= isMainScope(Scope) [function]
     rule isMainScope(blockScope(... functionId: Identifier("main"))) => true
     rule isMainScope(_) => false [owise]

     syntax KItem ::= lintFunElide(CId)
     rule lintFunElide(_) => .K
          requires notBool hasLint

endmodule
