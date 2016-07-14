module CPP-ABSTRACT-SYNTAX
     imports CPP-SYNTAX

     imports CPP-DYNAMIC-SYNTAX
     imports COMPAT-SYNTAX

     syntax LVal ::= LExpr
     syntax XVal ::= XExpr
     syntax PRVal ::= PRExpr
     syntax GLVal ::= GLExpr
     syntax RVal ::= RExpr
     syntax Val ::= TExpr

     syntax Decl ::= TranslationUnit(String, List)
                   | LinkageSpec(String, List)
                   | Declarator
                   | Specifier(Specifier, Decl)
     syntax Declarator ::= FunctionDecl(Namespace, CId, AType)
                         | VarDecl(Namespace, CId, AType, Expr)
                         | FunctionDefinition(Namespace, CId, AType, AStmt)

     syntax StorageClassSpecifier ::= Register() | Static() | ThreadLocal() | Extern() | Mutable()
     syntax FunctionSpecifier ::= Inline() | Virtual() | Explicit()
     syntax Specifier ::= StorageClassSpecifier | FunctionSpecifier

     syntax Expr ::= "NoInit"

     syntax CPPType // defined in CPP-TYPING-SYNTAX

     syntax AType ::= CPPType
                    | FunctionPrototype(AType, List, List, Expr, Bool)
                    | BuiltinType(AType)
                    | PointerType(AType)

     syntax AType ::= Void() | Char() | Bool() | UChar() | UShort() 
                    | UInt() | ULong() | ULongLong() | SChar() | Short()
                    | Int() | Long() | LongLong() | Float() | Double()
                    | LongDouble()

     syntax AType ::= Qualifier(Qualifier, AType)

     syntax AStmt ::= CompoundAStmt(List)
                   | LabelAStmt(CId, List)
                   | Expr //expression statement, handled later

     syntax AStmt ::= Stmt

     syntax Stmt ::= ReturnStmt(Init)

     syntax Expr ::= CallExpr(Expr, StrictList)
                   | StringLiteral(String)
                   | NoExpression()

endmodule
