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

     syntax CtorInit ::= ConstructorBase(AType, Bool, Bool, Init)
                      | ConstructorMember(CId, Init)

     syntax Declarator ::= FunctionDefinition(NNS, CId, AType, AStmt)
                         | FunctionDecl(NNS, CId, AType)
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
     syntax TemplateParameter ::= TypeTemplateParam(Bool, Bool, AType, AType)
                                | ValueTemplateParam(Bool, NNS, CId, AType, AExpr)
                                | TemplateTemplateParam(Bool, CId, AType, List)

     syntax TemplateArgument ::= TypeArg(AType)
                               | TemplateArg(TemplateName)
                               | ExprArg(Expr)
                               | PackArg(List)

     syntax TemplateName ::= TemplateName(CId)

     syntax Decl ::= TemplateSpecialization(AType, Decl)
                   | TemplateInstantiation(AType, Decl)
                   | PartialSpecialization(List, List, Decl)

     syntax Tag ::= Struct() | Union() | Class() | Enum() | Typename() | NoTag()

     syntax Decl ::= ClassDef(Tag, CId, NNS, List, List)
                   | EnumDef(CId, NNS, List)
                   | TypeDecl(AType)
                   | AccessSpec(AccessSpecifier)
                   | StaticAssert(Expr, Expr)
                   | UsingDecl(Bool, NNS, CId)
                   | UsingDirective(CId, NNS)

     syntax BaseSpecifier ::= BaseClass(Bool, Bool, AccessSpecifier, AType)
     syntax Enumerator ::= Enumerator(CId, AExpr)

     syntax CPPType // defined in CPP-TYPING-SYNTAX

     syntax ATypeResult ::= NoType()
     syntax KResult ::= ATypeResult

     syntax AType ::= CPPType
                    | ATypeResult
                    | ElaboratedTypeSpecifier(Tag, CId, NNS)
                    | FunctionPrototype(AType, StrictList, ExceptionSpec, Bool) [strict(1, 2)]
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
                    | TemplateSpecializationType(TemplateName, List)
                    | PackExpansionType(AType)
                    | AutoType(Bool)
 
     // extensions
     syntax AType ::= GnuTypeOfExpr(AType)
                    | GnuEnumUnderlyingType(AType)               

     syntax ExceptionSpec ::= NoExceptionSpec() 
                            | NoexceptSpec(AExpr)
                            | ThrowSpec(StrictList) [strict]

     syntax TypeSpecifier ::= Void() | Char() | WChar() | Char16() | Char32()
                            | Bool() | UChar() | UShort() | UInt() | ULong() 
                            | ULongLong() | SChar() | Short() | Int() | Long()
                            | LongLong() | Float() | Double() | LongDouble()

     syntax AType ::= Qualifier(Qualifier, AType) [strict(2)]

     syntax AStmt ::= Stmt
     syntax Stmt ::= DeclStmt(List)
                   | BreakStmt()
                  // GotoStmt(CId)
                   | ReturnStmt(Init)
                   | NullStmt()
      
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
                   | BinaryOperator(OpId, Expr, Expr)
                   | ConditionalOperator(Expr, Expr, Expr)
                   | ParenthesizedCast(AType, Expr)
                   | ReinterpretCast(AType, Expr)
                   | StaticCast(AType, Expr)
                   | DynamicCast(AType, Expr)
                   | ConstCast(AType, Expr)
                   | FunctionalCast(AType, List)
                   | SizeofType(AType)
                   | SizeofExpr(Expr)
                   | AlignofType(AType)
                   | AlignofExpr(Expr)
                   | SizeofPack(CId)
                   | PseudoDestructor(Expr, Bool, NNS, AType, AType)
                   | Noexcept(Expr)
                   | NewExpr(AType, AExpr, AExpr, List)
                   | This

     syntax This ::= This()

     syntax Expr ::= Throw(Expr)
                   | Lambda(CaptureDefault, List, AType, AStmt)
                   | PackExpansionExpr(Expr)
                   | StringLiteral(CharKind, String)
                   | CharacterLiteral(Int)
                   | IntegerLiteral(Int, AType) [strict(2)]
                   | FloatingLiteral(Float, AType) [strict(2)]
                   | NullPointerLiteral()
                   | BoolLiteral(Bool)

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
