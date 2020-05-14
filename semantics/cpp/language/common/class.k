// ------------------------------
//      CPP-CLASS-BASIC
// ------------------------------

module CPP-CLASS-BASIC-SORTS

     syntax Class

     syntax ClassQualifier

     syntax LocalQualifier

     syntax LocalClass

     syntax InnerClass

     syntax ClassSpecifier

endmodule // CPP-CLASS-BASIC-SORTS

module CPP-CLASS-BASIC-SYNTAX
     imports CPP-CLASS-BASIC-SORTS // self

     imports COMMON-SORTS // CId
     imports CPP-SORTS // Tag
     imports CPP-NAMESPACE-SORTS // Namespace

     // remote sorts
     syntax TemplateArgs

     syntax BlockScope

     syntax LocalQualifier ::= localQual(BlockScope)

     // a large amount of code changes behavior based on whether it is within a namespace, a class, or a block.
     // in the event that new values must be added to this sort, please make sure to extensively examine existing
     // code involving ClassQualifier and NNSVal.
     syntax ClassQualifier ::= Namespace | Class | LocalQualifier

     syntax Class ::= ClassQualifier "::" ClassSpecifier [klabel(classId)]

     syntax LocalClass ::= LocalQualifier "::" ClassSpecifier [klabel(classId)]

     syntax Class ::= LocalClass
     syntax Class ::= InnerClass

     syntax InnerClass ::= Class "::" ClassSpecifier [klabel(classId)]

     syntax LocalInnerClass ::= LocalClass
                             | LocalInnerClass "::" ClassSpecifier [klabel(classId)]

     syntax ClassSpecifier ::= Class(Tag, CId, TemplateArgs) [klabel(classSpecifier)]

     syntax CId ::= "Class.id" "(" Class ")" [function, klabel(Class.Class.idClass)]

     syntax CId ::= "Class.id" "(" ClassSpecifier ")" [function, klabel(Class.Class.idClassSpecifier)]

endmodule // CPP-CLASS-BASIC-SYNTAX

module CPP-CLASS-BASIC
     imports CPP-CLASS-BASIC-SYNTAX // self

     rule Class.id(Class(_, X::CId, _)) => X

     rule Class.id(_ :: S::ClassSpecifier) => Class.id(S)

endmodule // CPP-CLASS-BASIC

// ------------------------------
//      CPP-CLASS-INFO
// ------------------------------

module CPP-CLASS-INFO-SORTS

     syntax ClassInfo

endmodule // CPP-CLASS-INFO-SORTS

module CPP-CLASS-INFO-SYNTAX
     imports CPP-CLASS-INFO-SORTS // self
     imports CPP-TYPING-SORTS // CPPType, IncompleteInfo

     // foreign sort
     syntax Class

     syntax ClassInfo ::= getClassInfo(CPPType) [function]
                        | getClassInfo(Class) [function, klabel(getClassInfoOfClass)]

     syntax ClassCell
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

     imports CPP-CLASS-BASIC-SORTS
     imports CPP-CLASS-INFO-SORTS
     imports CPP-CLASS-MEMBER-SORTS

endmodule

module CPP-CLASS-SYNTAX
     imports CPP-CLASS-BASIC-SYNTAX
     imports CPP-CLASS-INFO-SYNTAX
     imports CPP-CLASS-MEMBER-SYNTAX

     imports CPP-CLASS-SORTS
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     imports INT
     syntax ClassOffset ::= classOffset(naoffset:Int, offset: Int)

     syntax Expr ::= evalBraceOrEqualInitializer(class: Class, object: Expr, initializer: Expr) [strict(c; 2)]

     syntax KItem ::= returnFromBraceOrEqualInitializer(Expr, Scope)

     syntax This ::= This() [symbol]

     syntax Expr ::= This

     syntax Expr ::= contrivedObject(CPPType)

     syntax ValResult ::= noObject()

     syntax NoArg ::= NoArg()

     syntax ValResult ::= NoArg

     syntax CId ::= unnamedObject(Class)

     syntax Expr ::= beginConstruction(Expr, isBaseClassSubobject: Bool) [strict(c; 1)]

     syntax Expr ::= endConstruction(Expr, isConstructor: Bool) [strict(c; 1)]

     syntax Expr ::= finishConstruction(Expr, isConstructor: Bool) [strict(c; 1)]

     syntax BaseClass ::= baseClass(Class)

     syntax CId ::= BaseClass

     syntax Stmt ::= "writeVTables"

endmodule

module CPP-CLASS

     imports CPP-CLASS-BASIC
     imports CPP-CLASS-INFO
     imports CPP-CLASS-MEMBER

endmodule
