module CPP-TRANSLATION-TYPING-DEPENDENT
     imports CPP-TYPING-SYNTAX
     imports CPP-CLASS-BASIC-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION

     syntax Bool ::= #isDependentInScope(CPPDTypeExpr, K) [function]

     // TODO(dwightguth): class member stuff
     rule isDependentInScope(T::CPPTypeExpr) => #isDependentInScope(T, #configuration)

     rule areDependentInScope(T::TemplateParams) => #areDependentInScope(T, #configuration)

     rule areDependentInScope(T::CPPTypeExprs) => #areDependentInScope(T, #configuration)

     rule #isDependentInScope(T:CPPDType, _) => false

     rule #isDependentInScope(t(_, _, classType(_ :: Class(_, _, L::TemplateParams))), Config:K) => #areDependentInScope(L, Config)

     rule #isDependentInScope(t(_, _, functionType(... returnType: T::CPPTypeExpr, paramTypes: L::CPPTypeExprs)), Config:K) => #isDependentInScope(T, Config) orBool #areDependentInScope(L, Config)

     rule #isDependentInScope(t(_, _, pointerType(T::CPPTypeExpr)), Config:K) => #isDependentInScope(T, Config)

     rule #isDependentInScope(t(_, _, lvRefType(T::CPPTypeExpr)), Config:K) => #isDependentInScope(T, Config)

     rule #isDependentInScope(t(_, _, rvRefType(T::CPPTypeExpr)), Config:K) => #isDependentInScope(T, Config)

     rule #isDependentInScope(t(_, _, dependentType(Arg::String, I::Int)), <generatedTop>... <template-arguments> Args::Map </template-arguments> ...</generatedTop>) => notBool dependentType(Arg, I) in_keys(Args)

     rule #isDependentInScope(t(_, _, T:CPPSimpleAutoType), <generatedTop>... <template-arguments> Args::Map </template-arguments> ...</generatedTop>) => notBool T in_keys(Args)

     syntax Bool ::= #areDependentInScope(TemplateParams, K) [function]

     syntax Bool ::= #areDependentInScope(CPPTypeExprs, K) [function]

     rule #areDependentInScope(T:CPPTypeExpr, L::TemplateParams, Config:K) => #isDependentInScope(T, Config) orBool #areDependentInScope(L, Config)

     rule #areDependentInScope(T:CPPDTypeExpr, L::CPPTypeExprs, Config:K) => #isDependentInScope(T, Config) orBool #areDependentInScope(L, Config)

     rule #areDependentInScope(.TemplateParams, _) => false

     rule #areDependentInScope(.CPPTypeExprs, _) => false

     rule isAuto(T:CPPDType) => false

     rule isAuto(t(_, _, classType(_ :: Class(_, _, L::TemplateParams)))) => areAuto(L)

     rule isAuto(t(_, _, functionType(... returnType: T::CPPTypeExpr, paramTypes: L::CPPTypeExprs))) => isAuto(T) orBool areAuto(L)

     rule isAuto(t(_, _, pointerType(T::CPPTypeExpr))) => isAuto(T)

     rule isAuto(t(_, _, lvRefType(T::CPPTypeExpr))) => isAuto(T)

     rule isAuto(t(_, _, rvRefType(T::CPPTypeExpr))) => isAuto(T)

     rule isAuto(t(_, _, auto)) => true

     rule isAuto(t(_, _, dependentType(...))) => false

     syntax Bool ::= areAuto(CPPTypeExprs) [function]

     syntax Bool ::= areAuto(TemplateParams) [function]

     rule areAuto(T::CPPTypeExpr, Ts::TemplateParams) => isAuto(T) orBool areAuto(Ts)

     rule areAuto(T::CPPTypeExpr, Ts::CPPTypeExprs) => isAuto(T) orBool areAuto(Ts)

     rule areAuto(.TemplateParams) => false

     rule areAuto(.CPPTypeExprs) => false

endmodule
