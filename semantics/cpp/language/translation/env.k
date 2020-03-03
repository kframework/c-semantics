module CPP-TRANSLATION-ENV-SYNTAX
     imports BASIC-K
     imports BOOL-SYNTAX
     imports COMPAT-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SYMLOC-SORTS
     imports CPP-TYPING-SORTS

     // identifier, type, location, is using declaration
     syntax KItem ::= addToEnv(QualId, CPPType, SymBase, Bool)
                    | scope(Scope, K)
                    | setScope(Scope)
                    | clearScope()
                    | noEval(K)
                    | "skipToScopeEnd"

     syntax KItem ::= "pushLocals" | "popLocals"

     syntax KItem ::= updateDefaultArguments(QualId, CPPType, DefaultArguments) [strict(3)]

     syntax DefaultArguments ::= defArgs(vals: StrictList, types: StrictList, cats: StrictList) [strict(1)]

     syntax DefaultArguments ::= DefaultArgumentsResult

     syntax DefaultArgumentsResult ::= defArgs(vals: StrictListResult, types: StrictListResult, cats: StrictListResult)

     syntax KResult ::= DefaultArgumentsResult

     syntax List ::= getDefaultArgsVals(DefaultArgumentsResult) [function]

     syntax List ::= getDefaultArgsTypes(DefaultArgumentsResult) [function]

     syntax List ::= getDefaultArgsCats(DefaultArgumentsResult) [function]

endmodule

module CPP-TRANSLATION-ENV
    imports CPP-TRANSLATION-ENV-SYNTAX
    imports C-CONFIGURATION
    imports BOOL
    imports K-EQUAL
    imports COMPAT-SYNTAX
    imports CPP-ABSTRACT-SYNTAX
    imports CPP-DYNAMIC-SYNTAX
    imports CPP-SYMLOC-SYNTAX
    imports CPP-TYPING-SYNTAX
    imports CPP-TYPE-MAP-SYNTAX

    rule updateDefaultArguments(_, T::CPPType, _) => .K
         requires notBool isCPPFunctionType(T)

    rule <k> addToEnv(N:Namespace :: X::CId, t(... st: functionType(...)) #as T::CPPType, Base::SymBase, IsUsing::Bool)
             => .K
         ...</k>
         <curr-tr-tu> Tu::String </curr-tr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv> NE::Map => NE[X <- updateFnEnv(NE, X, T, Base, IsUsing)] </nenv>
         requires N =/=K NoNamespace()

    rule <k> updateDefaultArguments(N:Namespace :: X::CId, t(... st: functionType(...)) #as T::CPPType, A1:DefaultArgumentsResult) => .K ...</k>
         <curr-tr-tu> Tu::String </curr-tr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv>... X |-> (_::Map stripType(T) |-> (_, envEntry(... defaultArgs: A2::DefaultArgumentsResult => #updateDefaultArgs(A1, A2)))) ...</nenv>
         requires N =/=K NoNamespace()

    rule <k> addToEnv(N:Namespace :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool)
             => .K
         ...</k>
         <curr-tr-tu> Tu::String </curr-tr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv> NE::Map => NE[X <- stripType(T) |-> (T, envEntry(Base, IsUsing, NoDefArgs()))] </nenv>
         requires N =/=K NoNamespace() andBool notBool isCPPFunctionType(T)

    rule <k> addToEnv(NoNamespace() :: X::CId, t(... st: functionType(...)) #as T::CPPType, Base::SymBase, IsUsing::Bool)
             => .K
         ...</k>
         <tr-env> NE::Map => NE[X <- updateFnEnv(NE, X, T, Base, IsUsing)] </tr-env>

    rule <k> updateDefaultArguments(NoNamespace() :: X::CId, t(... st: functionType(...)) #as T::CPPType, A1:DefaultArgumentsResult) => .K ...</k>
         <tr-env>... X |-> (_::Map stripType(T) |-> (_, envEntry(... defaultArgs: A2::DefaultArgumentsResult => #updateDefaultArgs(A1, A2)))) ...</tr-env>

    rule <k> addToEnv(NoNamespace() :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool)
             => .K
         ...</k>
         <tr-env> NE::Map => NE[X <- stripType(T) |-> (T, envEntry(Base, IsUsing, NoDefArgs()))] </tr-env>
         requires notBool isCPPFunctionType(T)

    rule <k> addToEnv(C:Class :: X::CId, t(... st: functionType(...)) #as T::CPPType, Base::SymBase, IsUsing::Bool)
             => .K
         ...</k>
         <class-id> C </class-id>
         <cenv> CE::Map => CE[X <- updateFnEnv(CE, X, T, Base, IsUsing)] </cenv>

     rule <k> updateDefaultArguments(C:Class :: X::CId, t(... st: functionType(...)) #as T::CPPType, A1:DefaultArgumentsResult) => .K ...</k>
          <class-id> C </class-id>
          <cenv>... X |-> (_::Map stripType(T) |-> (_, envEntry(... defaultArgs: A2::DefaultArgumentsResult => #updateDefaultArgs(A1, A2)))) ...</cenv>

    rule <k> addToEnv(C:Class :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool)
             => .K
         ...</k>
         <class-id> C </class-id>
         <cenv> CE::Map => CE[X <- stripType(T) |-> (T, envEntry(Base, IsUsing, NoDefArgs()))] </cenv>
         requires notBool isCPPFunctionType(T)

     rule getDefaultArgsVals(defArgs(... vals: krlist(Args::List))) => Args

     rule getDefaultArgsTypes(defArgs(... types: krlist(Types::List))) => Types

     rule getDefaultArgsCats(defArgs(... cats: krlist(Cats::List))) => Cats

     syntax Map ::= updateFnEnv(Map, CId, CPPType, SymBase, Bool) [function]

     rule updateFnEnv(Env::Map, X::CId, T::CPPType, Base::SymBase, IsUsing::Bool) => stripType(T) |-> (T, envEntry(Base, IsUsing, emptyDefaultArguments(T)))
          requires notBool X in_keys(Env)

     rule updateFnEnv(_ X |-> XEnv::Map, X::CId, T::CPPType, Base::SymBase, IsUsing::Bool)
          => #updateFnEnv(XEnv, T, Base, IsUsing)

     syntax Map ::= #updateFnEnv(Map, CPPType, SymBase, Bool) [function]

     rule #updateFnEnv(XEnv::Map stripType(T) |-> (_, Entry:EnvEntry), T::CPPType, Base::SymBase, IsUsing::Bool)
          => XEnv stripType(T) |-> (T, #fun(envEntry(... base: _ => Base, using: _ => IsUsing))(Entry))

     rule #updateFnEnv(XEnv::Map, T::CPPType, Base::SymBase, IsUsing::Bool) => XEnv stripType(T) |-> (T, envEntry(Base, IsUsing, emptyDefaultArguments(T))) [owise]

     syntax DefaultArgumentsResult ::= #updateDefaultArgs(newArgs: DefaultArgumentsResult, oldArgs: DefaultArgumentsResult) [function]

     rule #updateDefaultArgs(NewArgs::DefaultArgumentsResult, OldArgs::DefaultArgumentsResult)
          => #updateDefaultArgs(NewArgs, OldArgs, defArgs(krlist(.List), krlist(.List), krlist(.List)))

     syntax DefaultArgumentsResult ::= #updateDefaultArgs(newArgs: DefaultArgumentsResult, oldArgs: DefaultArgumentsResult, resultArgs: DefaultArgumentsResult) [function, klabel(updateDefaultArgsHelper)]

    // The next rule compensates for the clang policy to aggregate existing default args from previous declarations
    // Hence, we'll trust clang to check that the user does not redefine an old def. arg.
     rule #updateDefaultArgs(
            defArgs(krlist((ListItem(_) => .List) _),
                    krlist((ListItem(_) => .List) _),
                    krlist((ListItem(_) => .List) _)),
            defArgs(krlist((ListItem(I:KItem) => .List) _),
                    krlist((ListItem(T::CPPDType) => .List) _),
                    krlist((ListItem(C::ValueCategory) => .List) _)),
            defArgs(krlist(_::List (.List => ListItem(I:KItem))),
                    krlist(_::List (.List => ListItem(T::CPPDType))),
                    krlist(_::List (.List => ListItem(C::ValueCategory)))))
          requires I =/=K NoArg()

     rule #updateDefaultArgs(
            defArgs(krlist((ListItem(I:KItem) => .List) _),
                    krlist((ListItem(T::CPPDType) => .List) _),
                    krlist((ListItem(C::ValueCategory) => .List) _)),
            defArgs(krlist((ListItem(NoArg()) => .List) _),
                    krlist((ListItem(_) => .List) _),
                    krlist((ListItem(_) => .List) _)),
            defArgs(krlist(_::List (.List => ListItem(I:KItem))),
                    krlist(_::List (.List => ListItem(T::CPPDType))),
                    krlist(_::List (.List => ListItem(C::ValueCategory)))))

     rule #updateDefaultArgs(
            defArgs(krlist(.List), krlist(.List), krlist(.List)),
            defArgs(krlist(.List), krlist(.List), krlist(.List)),
            DA::DefaultArgumentsResult) => DA

     rule <k> clearScope() => .K ...</k>
          (<tr-block-control> _::Bag </tr-block-control>
           => <tr-block-control>
                <tr-env> .Map </tr-env>
                <tr-types> .Map </tr-types>
                <enums> .Map </enums>
                <using-namespaces> .Set </using-namespaces>
                <tr-block-history> .List </tr-block-history>
                <tr-this> .K </tr-this>
              </tr-block-control> )
 
     rule <k> scope(Scope::Scope, K:K)
              => pushLocals ~> K ~> popLocals ~> setScope(OldScope)
          ...</k>
          <curr-tr-scope> OldScope::Scope => Scope </curr-tr-scope>

     rule <k> setScope(Scope::Scope) => .K ...</k>
          <curr-tr-scope> _ => Scope </curr-tr-scope>

     rule <k> pushLocals => .K ...</k>
          <tr-block-control> C::Bag </tr-block-control>
          <tr-block-stack>
               .List => ListItem(<tr-block-control> C </tr-block-control>)
          ...</tr-block-stack>

     rule <k> popLocals => .K ...</k>
          (_:TrBlockControlCell => L)
          <tr-block-stack>
               ListItem(L:TrBlockControlCell) => .List
          ...</tr-block-stack>

     rule <k> noEval(K:K)
              => setEval(noEval) ~> pushLocals ~> K ~> popLocals ~> setEval(OldEval)
          ...</k>
          <curr-eval-context> OldEval::EvalContext </curr-eval-context>

     syntax KItem ::= setEval(EvalContext)

     rule <k> setEval(Eval::EvalContext) => .K ...</k>
          <curr-eval-context> _ => Eval </curr-eval-context>

     rule skipToScopeEnd ~> (K:KItem => .K)
          requires K =/=K popLocals

     rule (skipToScopeEnd => .K) ~> popLocals

endmodule
