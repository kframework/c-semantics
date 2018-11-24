// ------------------------------
//      CPP-CLASS-INFO
// ------------------------------

module CPP-CLASS-INFO-SORTS

     syntax ClassInfo

endmodule // CPP-CLASS-INFO-SORTS

module CPP-CLASS-INFO-SYNTAX
     imports CPP-CLASS-INFO-SORTS // self
     imports CPP-TYPING-SORTS // CPPClassType, IncompleteInfo

     // foreign sort
     syntax Class

     syntax ClassInfo ::= getClassInfo(CPPClassType) [function]
                        | getClassInfo(Class) [function, klabel(getClassInfoOfClass)]

     syntax ClassInfo ::= ClassCell | IncompleteInfo

endmodule // CPP-CLASS-INFO-SYNTAX

module CPP-CLASS-INFO
     imports CPP-CLASS-INFO-SYNTAX // self

     imports K-REFLECTION
     imports C-CONFIGURATION
     imports CPP-TYPING-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX

     syntax ClassInfo ::= #getClassInfo(Class, K) [function]

     rule getClassInfo(t(... st: classType(C::Class)))
          => getClassInfo(C)

     rule getClassInfo(C::Class)
          => #getClassInfo(C, getCurrentTranslationUnit())

     rule #getClassInfo(C::Class, <tu>... <class> <class-id> C </class-id> B::Bag </class> ...</tu>)
          => <class> <class-id> C </class-id> B </class>

     rule #getClassInfo(_, _) => #incomplete [owise]

endmodule // CPP-CLASS-INFO

// ------------------------------
//      CPP-CLASS-MEMBER
// ------------------------------

module CPP-CLASS-MEMBER-SORTS

     syntax ClassMember

endmodule // CPP-CLASS-MEMBER-SORTS

module CPP-CLASS-MEMBER-SYNTAX
     imports CPP-CLASS-MEMBER-SORTS // self

     imports COMMON-SORTS     // CId
     imports CPP-TYPING-SORTS // CPPType

     syntax ClassMember ::= "Class.DataMember" "(" CId "," CPPType ")"
     syntax ClassMember ::= "Class.FunctionMember" "(" CId "," CPPType ")"

endmodule // CPP-CLASS-MEMBER-SYNTAX

module CPP-CLASS-MEMBER
     imports CPP-CLASS-MEMBER-SYNTAX // self

     // nothing yet

endmodule // CPP-CLASS-MEMBER

// ------------------------------
//      CPP-CLASS
// ------------------------------

module CPP-CLASS-SORTS

     imports CPP-CLASS-INFO-SORTS
     imports CPP-CLASS-MEMBER-SORTS

endmodule

module CPP-CLASS-SYNTAX
     imports CPP-CLASS-INFO-SYNTAX
     imports CPP-CLASS-MEMBER-SYNTAX

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

endmodule

module CPP-CLASS

     imports CPP-CLASS-INFO
     imports CPP-CLASS-MEMBER

endmodule

