module CPP-CLASS-SORTS
     syntax ClassInfo
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

endmodule

module CPP-CLASS
     imports CPP-CLASS-SYNTAX
     imports K-REFLECTION
     imports C-CONFIGURATION
     imports CPP-TYPING-SYNTAX
     syntax ClassInfo ::= #getClassInfo(Class, K) [function]

     rule getClassInfo(t(... st: classType(C::Class))) => getClassInfo(C)
     rule getClassInfo(C::Class) => #getClassInfo(C, #configuration)
     rule #getClassInfo(C::Class, <generatedTop>... <curr-tu> Tu::String </curr-tu> <tu-id> Tu </tu-id> <class> <class-id> C </class-id> B::Bag </class> ...</generatedTop>) => <class> <class-id> C </class-id> B </class>
     rule #getClassInfo(_, _) => #incomplete [owise]
 endmodule
