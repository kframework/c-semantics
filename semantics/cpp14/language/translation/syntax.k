module CPP-ABSTRACT-SORTS
     syntax Decl
endmodule

module CPP-ABSTRACT-SYNTAX
     imports CPP-ABSTRACT-SORTS
     imports BOOL
     imports FLOAT-SYNTAX
     imports LIST
     imports STRING-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS
     imports COMMON-SORTS
     imports COMPAT-SORTS
     imports CPP-DEPENDENT-SYNTAX

     syntax LVal ::= LExpr
     syntax XVal ::= XExpr
     syntax PRVal ::= PRExpr
     syntax GLVal ::= GLExpr
     syntax RVal ::= RExpr
     syntax Val ::= TExpr

     syntax SymBase ::= "nonStatic" 

     syntax TypeId ::= TypeId(AType)
     syntax CId ::= TypeId

     syntax Decl ::= TranslationUnit(String, List)
                   | TypedefDecl(CId, AType) [strict(2)]
                   | TypeAliasDecl(CId, AType) [strict(2)]
                   | LinkageSpec(String, Bool, List)
                   | NamespaceDecl(CId, Bool, List)
                   | Specifier(Specifier, Decl)
                   | Declarator
                   | Constructor(List, Decl)

     context TypedefDecl(_, HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     context TypeAliasDecl(_, HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     syntax CtorInit ::= ConstructorBase(AType, Bool, Bool, Init)
                      | ConstructorMember(CId, Init)

     syntax Declarator ::= FunctionDefinition(NNS, CId, AType, List, AStmt)
                         | FunctionDecl(NNS, CId, AType, List)
                         | VarDecl(NNS, CId, AType, Init)
                         | FieldDecl(NNS, CId, AType, Init)
                         | BitFieldDecl(NNS, CId, AType, Expr)

     syntax Init ::= NoInit()

     syntax StorageClassSpecifier ::= Register() | Static() | ThreadLocal() | Extern() | Mutable()
     syntax FunctionSpecifier ::= Inline() | Virtual() | Explicit()
     syntax AccessSpecifier ::= Public() | Private() | Protected() | NoAccessSpec()
     syntax Specifier ::= StorageClassSpecifier | FunctionSpecifier
                        | Constexpr() | Friend() | Auto()

     syntax Decl ::= Template(Decl, List)
                   | TemplateWithInstantiations(Decl, List, List)
     syntax TemplateParameter ::= TypeTemplateParam(Bool, Bool, AType, AType)
                                | ValueTemplateParam(Bool, NNS, CId, AType, AExpr)
                                | TemplateTemplateParam(Bool, CId, AType, List)

     syntax TemplateArgument ::= TypeArg(AType) [strict]
                               | TemplateArg(CId)
                               | ExprArg(Expr)
                               | PackArg(List)


     context TypeArg(HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     syntax Decl ::= TemplateSpecialization(AType, Decl)
                   | TemplateInstantiationDeclaration(AType, Decl)
                   | TemplateInstantiationDefinition(AType, Decl)
                   | PartialSpecialization(List, List, Decl)

     syntax Decl ::= ClassDef(Tag, CId, NNS, List, List)
                   | TypeDecl(AType)
                   | EnumDef(CId, NNS, List)
                   | AccessSpec(AccessSpecifier)
                   | StaticAssert(Expr, Expr)
                   | UsingDecl(Bool, NNS, CId)
                   | UsingDirective(CId, NNS)

     syntax BaseSpecifier ::= BaseClass(Bool, Bool, AccessSpecifier, AType)
     syntax Enumerator ::= Enumerator(CId, AExpr)

     syntax CPPType // defined in CPP-TYPING-SYNTAX

     syntax ATypeResult ::= NoType()
     syntax KResult ::= ATypeResult

     syntax AType ::= CPPTypeExpr
                    | ATypeResult
                    | ElaboratedTypeSpecifier(Tag, CId, NNS)
                    | ElaboratedTypeSpecifier(Tag, CId, NNS, List)
                    | FunctionPrototype(AType, StrictList, ExceptionSpec, Bool) [strict(1)]
                    | BuiltinType(TypeSpecifier)
                    | PointerType(AType) [strict]
                    | MemberPointerType(AType, AType) [strict]
                    | ArrayType(AType, Int) [strict(1)]
                    | ArrayType(AType, AExpr) [strict(1)]
                    | TypedefType(CId)
                    | QualifiedTypeName(Tag, NNS, AType)
                    | Decltype(Expr)
                    | TemplateParameterType(CId)
                    | LValRefType(AType) [strict]
                    | RValRefType(AType) [strict]
                    | TemplateSpecializationType(CId)
                    | TemplateSpecializationType(CId, List)
                    | PackExpansionType(AType)
                    | AutoType(Bool)

     context FunctionPrototype(HOLE:CPPTypeExpr, _, _, _)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]
     context FunctionPrototype(_, HOLE:StrictList => typeStrict(HOLE), _, _)
     context PointerType(HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]
     context MemberPointerType(HOLE:CPPTypeExpr, _)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]
     context MemberPointerType(_, HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]
     context ArrayType(HOLE:CPPTypeExpr, _::Int)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]
     context ArrayType(HOLE:CPPTypeExpr, _::AExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]
     context LValRefType(HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]
     context RValRefType(HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     // extensions
     syntax AType ::= GnuTypeOfExpr(AType)
                    | GnuEnumUnderlyingType(AType)               

     syntax ExceptionSpec ::= NoExceptionSpec() 
                            | NoexceptSpec(AExpr)
                            | ThrowSpec(StrictList)

     syntax TypeSpecifier ::= Void() | Char() | WChar() | Char16() | Char32()
                            | Bool() | UChar() | UShort() | UInt() | ULong() 
                            | ULongLong() | SChar() | Short() | Int() | Long()
                            | LongLong() | Float() | Double() | LongDouble()

     syntax AType ::= Qualifier(Qualifier, AType) [strict(2)]
     context Qualifier(_, HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     syntax AStmt ::= Stmt
     syntax Stmt ::= DeclStmt(List)
                   | BreakStmt()
                  // GotoStmt(CId)
                   | ReturnStmt(Init)
                   | NullStmt()
                   | TemplateDefinitionStmt(K) // synthetic statement created by the body of a function template definition when it's evaluted before instantiation
      
     syntax AStmt ::= NoStatement()
                    | CompoundAStmt(List)
                    | LabelAStmt(CId, List)
                    | ForAStmt(AStmt, AExpr, AExpr, AStmt)
                    | WhileAStmt(Expr, AStmt)
                    | DoWhileAStmt(AStmt, Expr)
                    | IfAStmt(Decl, AStmt, AStmt)
                    | IfAStmt(Expr, AStmt, AStmt)
                    | TryAStmt(AStmt, List)
                    | CatchAStmt(CatchDecl, AStmt)
                    | Expr //expression statement, handled later

     syntax CatchDecl ::= Decl | Ellipsis()             

     syntax AExpr ::= Expr
                    | NoExpression()

     syntax Expr ::= MemberExpr(Bool, Bool, Name, Expr)
                   | Subscript(Expr, Expr)
                   | CallExpr(Expr, StrictList)
                   | Name
                   | UnaryOperator(OpId, Expr)
                   | BinaryOperator(OpId, Expr, Init)
                   | ConditionalOperator(Expr, Expr, Expr)
                   | ParenthesizedCast(AType, Expr)
                   | ReinterpretCast(AType, Expr)
                   | StaticCast(AType, Expr)
                   | DynamicCast(AType, Expr)
                   | ConstCast(AType, Expr)
                   | FunctionalCast(AType, List)
                   | SizeofType(AType) [strict]
                   | SizeofExpr(Expr)
                   | AlignofType(AType)
                   | AlignofExpr(Expr)
                   | SizeofPack(CId)
                   | PseudoDestructor(Expr, Bool, NNS, AType, AType)
                   | Noexcept(Expr)
                   | NewExpr(AType, AExpr, Init, List) [strict(1)]
                   | This

     syntax This ::= This()

     syntax Expr ::= Throw(Expr)
                   | Lambda(CaptureDefault, List, AType, AStmt)
                   | PackExpansionExpr(Expr)
                   | StringLiteral(CharKind, String)
                   | CharacterLiteral(CharKind, Int)
                   | IntegerLiteral(Int, AType) [strict(2)]
                   | FloatingLiteral(Float, AType) [strict(2)]
                   | NullPointerLiteral()
                   | BoolLiteral(Bool)

     syntax Expr ::= Expr "[" Expr "]"

     context IntegerLiteral(_, HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]
     context FloatingLiteral(_, HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     syntax CaptureDefault ::= NoCaptureDefault() | CopyCapture() | RefCapture()
     syntax Capture ::= LambdaCapture(CaptureKind, Bool)
     syntax CaptureKind ::= Decl | This | RefCapture(Decl) [klabel(RefCapture1)]

     syntax CharKind ::= Ascii() | Wide() | UTF8() | UTF16() | UTF32()

     syntax Init ::= BraceInit(List)

     // extensions
     syntax Expr ::= GnuTypeTrait(String, List)
                   | GnuAtomicExpr(String, List)

     // things that are not technically expressions, but will be transformed out
     // of existence by the semantics
     syntax Expr ::= MaterializeTemporaryExpr(Expr)
                   | ParenList(List)
                   | DefaultArg(Expr)

endmodule

module CPP-ABSTRACT-REWRITING
     imports CPP-SYNTAX
     imports CPP-ABSTRACT-SYNTAX

     rule Subscript(E1::Expr, E2::Expr) => BinaryOperator(operator[], E1, E2) [anywhere]
     rule E1::Expr [ E2::Expr ] => * (E1 + E2) [anywhere]
endmodule
