module CPP-TYPING-DEPENDENT
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION

     syntax Bool ::= #isDependentInScope(CPPDTypeExpr, K) [function]

     // TODO(dwightguth): class member stuff
     rule isDependentInScope(T::CPPTypeExpr) => #isDependentInScope(T, #configuration)
     rule areDependentInScope(T::TemplateParams) => #areDependentInScope(T, #configuration)
     rule areDependentInScope(T::CPPTypeExprs) => #areDependentInScope(T, #configuration)
     rule #isDependentInScope(T:CPPDType, _) => false
     rule #isDependentInScope(t(_, _, classType(_ :: Class(_, _, L::TemplateParams))), Config:K) => #areDependentInScope(L, Config)
     rule #isDependentInScope(t(_, _, functionType(T::CPPTypeExpr, L::CPPTypeExprs, _)), Config:K) => #isDependentInScope(T, Config) orBool #areDependentInScope(L, Config)
     rule #isDependentInScope(t(_, _, pointerType(T::CPPTypeExpr)), Config:K) => #isDependentInScope(T, Config)
     rule #isDependentInScope(t(_, _, dependentType(Arg::String)), <generatedTop>... <template-arguments> Args::Map </template-arguments> ...</generatedTop>) => notBool Arg in_keys(Args)
     syntax Bool ::= #areDependentInScope(TemplateParams, K) [function]
     syntax Bool ::= #areDependentInScope(CPPTypeExprs, K) [function]
     rule #areDependentInScope(T:CPPTypeExpr, L::TemplateParams, Config:K) => #isDependentInScope(T, Config) orBool #areDependentInScope(L, Config)
     rule #areDependentInScope(T:CPPDTypeExpr, L::CPPTypeExprs, Config:K) => #isDependentInScope(T, Config) orBool #areDependentInScope(L, Config)
     rule #areDependentInScope(.TemplateParams, _) => false
     rule #areDependentInScope(.CPPTypeExprs, _) => false

endmodule
