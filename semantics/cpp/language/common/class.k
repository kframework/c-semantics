module CPP-CLASS-SORTS
     syntax ClassInfo
     syntax ClassDataMember
     syntax ClassFunctionMember
endmodule

module CPP-CLASS-SYNTAX
     imports CPP-CLASS-SORTS
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     imports INT
     syntax ClassOffset ::= classOffset(naoffset:Int, offset: Int)
     syntax Expr ::= evalBraceOrEqualInitializer(class: Class, object: Expr, initializer: Expr) [strict(2)]
     syntax KItem ::= returnFromBraceOrEqualInitializer(LVal, Scope)
     syntax This ::= This()
     syntax Expr ::= This
     syntax Expr ::= contrivedObject(CPPType)
     syntax ValResult ::= noObject()
     syntax NoArg ::= NoArg()
     syntax ValResult ::= NoArg
     syntax CId ::= unnamedObject(Class)
     syntax Expr ::= beginConstruction(Expr, isBaseClassSubobject: Bool) [strict]
     syntax Expr ::= endConstruction(Expr, isConstructor: Bool) [strict]
     syntax BaseClass ::= baseClass(Class)
     syntax CId ::= BaseClass
     syntax Stmt ::= "writeVTables"
     syntax ClassInfo ::= getClassInfo(CPPClassType) [function]
                        | getClassInfo(Class) [function, klabel(getClassInfoOfClass)]
     syntax ClassInfo ::= ClassCell | IncompleteInfo

     syntax ClassDataMember ::= "Class.DataMember" "(" CId "," CPPType ")"
     syntax ClassDataMember ::= "Class.FunctionMember" "(" CId "," CPPType ")"

endmodule

module CPP-CLASS
     imports CPP-CLASS-SYNTAX
     imports K-REFLECTION
     imports C-CONFIGURATION
     imports CPP-TYPING-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX

     syntax ClassInfo ::= #getClassInfo(Class, K) [function]

     rule getClassInfo(t(... st: classType(C::Class))) => getClassInfo(C)
     rule getClassInfo(C::Class) => #getClassInfo(C, getCurrentTranslationUnit())
     rule #getClassInfo(C::Class, <tu>... <class> <class-id> C </class-id> B::Bag </class> ...</tu>) => <class> <class-id> C </class-id> B </class>
     rule #getClassInfo(_, _) => #incomplete [owise]
 endmodule
