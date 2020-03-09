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
     imports COMPAT-SORTS
     imports CPP-CLASS-SYNTAX
     imports CPP-DEPENDENT-SYNTAX
     imports COMMON-SYNTAX

     syntax LVal ::= LExpr

     syntax XVal ::= XExpr

     syntax PRVal ::= PRExpr

     syntax GLVal ::= GLExpr

     syntax RVal ::= RExpr

     syntax Val ::= TExpr

     syntax SymBase ::= "nonStatic"

     syntax TypeId ::= TypeId(AType)
     syntax DestructorId ::= DestructorTypeId(AType)

     syntax CId ::= TypeId

     syntax Decl ::= TranslationUnit(String, List)
                   | TypedefDecl(CId, AType) [strict(2)]
                   | TypeAliasDecl(CId, AType) [strict(2)]
                   | LinkageSpec(String, Bool, List)
                   | NamespaceDecl(CId, Bool, List)
                   | NamespaceAliasDecl(CId, CId, NNS)
                   | Specifier(Specifier, Decl)
                   | Declarator
                   | DeclLoc(CabsLoc, Decl)
                   | FriendDecl(Decl)

     syntax CtorInit ::= ConstructorBase(AType, Bool, Bool, Init)
                      | ConstructorMember(CId, Init)
                      | ConstructorDelegating(Init)

     syntax Declarator ::= FunctionDefinition(NNS, CId, CId, AType, List, AStmt) [strict(4)]
                         | FunctionDecl(NNS, CId, CId, AType, List) [strict(4)]
                         | VarDecl(NNS, CId, CId, AType, Init, isDirect: Bool) [strict(4)]
                         | FieldDecl(NNS, CId, AType, Init) [strict(3)]
                         | BitFieldDecl(NNS, CId, AType, Expr) [strict(3)]

     syntax InitOnlyIfOdrUsed ::= OnlyIfOdrUsed(Init)
     syntax Stmt ::= InitOnlyIfOdrUsed

     syntax StorageClassSpecifier ::= Mutable()

     syntax FunctionSpecifier ::= Explicit()

     syntax Specifier ::= StorageClassSpecifier | FunctionSpecifier
                        | Constexpr() | AutoSpecifier

     syntax Decl ::= Template(Decl, List)
                   | TemplateWithInstantiations(Decl, List, List)

     syntax TemplateParameter ::= TypeTemplateParam(Bool, Bool, AType, AType)
                                | ValueTemplateParam(Bool, NNS, CId, AType, AExpr)
                                | TemplateTemplateParam(Bool, CId, AType, List)

     syntax TemplateArgument ::= TypeArg(AType) [strict]
                               | TemplateArg(CId)
                               | ExprArg(Expr)
                               | PackArg(List)

     syntax Decl ::= TemplateSpecialization(AType, Decl)
                   | TemplateInstantiationDeclaration(AType, Decl)
                   | TemplateInstantiationDefinition(AType, Decl)
                   | PartialSpecialization(List, List, Decl)

     syntax Decl ::= ClassDef(Tag, CId, NNS, List, List, Bool)
                   | TypeDecl(AType)
                   | EnumDef(id: CId, nns: NNS, scoped: Bool, fixed: Bool, ut: AType, List) [strict(5)]
                   | OpaqueEnumDeclaration(id: CId, scoped: Bool, ut: AType) [strict(3)]
                   | AccessSpec(AccessSpecifier)
                   | StaticAssert(Expr, Expr)
                   | UsingDecl(Bool, NNS, CId)
                   | UsingDirective(CId, NNS)

     syntax Decl ::= DeclLoc(CabsLoc, Decl)
                   | NoDecl()

     syntax BaseSpecifier ::= BaseClass(Bool, Bool, AccessSpecifier, AType)

     syntax Enumerator ::= Enumerator(CId, AExpr)

     syntax CPPType // defined in CPP-TYPING-SYNTAX

     syntax ATypeResult ::= NoType()

     syntax KResult ::= ATypeResult

     syntax AType ::= CPPType
                    | ATypeResult
                    | ElaboratedTypeSpecifier(Tag, CId, NNS)
                    | ElaboratedTypeSpecifier(Tag, CId, NNS, List)
                    | FunctionPrototype(AType, StrictList, ExceptionSpec, Bool) [strict(1)]
                    | MethodPrototype(Bool, Bool, AType, AType) [strict(3, 4)]
                    | StaticMethodPrototype(AType) [strict]
                    | Virtual(AType) [strict]
                    | Pure(AType) [strict]
                    | Explicit(AType) [strict]
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
                    | Name

     context FunctionPrototype(_, HOLE:StrictList => typeStrict(HOLE), _, _)

     // extensions
     syntax AType ::= GnuEnumUnderlyingType2(AType, AType)
                    | GnuEnumUnderlyingType1(AType)
                    | TypeofExpression(Expr) | TypeofType(AType)

     syntax ExceptionSpec ::= NoExceptionSpec()
                            | NoexceptSpec(AExpr)
                            | ThrowSpec(StrictList) [strict]

     syntax TypeSpecifier ::= Void() | Char() | WChar() | Char16() | Char32()
                            | Bool() | UChar() | UShort() | UInt() | ULong()
                            | ULongLong() | SChar() | Short() | Int() | Long()
                            | LongLong() | Float() | Double() | LongDouble()
                            | OversizedInt() | OversizedUInt()
                            | Dependent() | NullPtr()

     syntax AType ::= RefQualifier(RefQualifier, AType) [strict(2)]

     syntax AType ::= Qualifier(Qualifier, AType) [strict(2)]

     syntax AStmt ::= Stmt

     syntax Stmt ::= DeclStmt(List)
                   | TGotoStmt(CId)
                   | TExpressionStmt(Expr) [strict(c)]
                   | TLabelStmt(CId, List)
                   | TCatchAnyOp(Stmt)
                   | TBreakStmt()
                   | ContinueStmt()
                   | ReturnStmt(Init)
                   | IfTStmt(Decl, Stmt, Stmt)
                   | IfTStmt(Expr, Stmt, Stmt)
                   | WhileTStmt(Decl, Stmt)
                   | WhileTStmt(Expr, Stmt)
                   | NullStmt()
                   | ForTStmt(Stmt, Expr, Stmt, Stmt)
                   | ForTStmt(Stmt, Decl, Stmt, Stmt)
                   | ForTStmt(Expr, Stmt, Stmt)
                   | TemplateDefinitionStmt(K) // synthetic statement created by the body of a function template definition when it's evaluted before instantiation
                   | TReturnOp(init: Expr, obj: K)

     syntax AStmt ::= NoStatement()
                    | CompoundAStmt(List)
                    | LabelAStmt(CId, List)
                    | ForAStmt(AStmt, AExpr, AExpr, AStmt)
                    | ForAStmt(AStmt, Decl, AExpr, AStmt)
                    | WhileAStmt(Decl, AStmt)
                    | WhileAStmt(Expr, AStmt)
                    | DoWhileAStmt(AStmt, Expr)
                    | IfAStmt(Decl, AStmt, AStmt)
                    | IfAStmt(Expr, AStmt, AStmt)
                    | SwitchAStmt(Decl, AStmt)
                    | SwitchAStmt(Expr, AStmt)
                    | CaseAStmt(Expr, AStmt)
                    | DefaultAStmt(AStmt)
                    | TryAStmt(AStmt, List)
                    | CatchAStmt(CatchDecl, AStmt)
                    | CatchStmt(Decl, Stmt)
                    | Expr //expression statement, handled later

     syntax Stmt ::= Defaulted()
                    | Deleted()
                    | Constructor(List, Stmt)
                    | Destructor()

     syntax CatchDecl ::= Decl | Ellipsis()

     syntax AExpr ::= Expr
                    | NoExpression()

     syntax Expr ::= MemberExpr(Bool, Bool, Name, Expr)
                   | AnonymousUnionObject(AType)
                   | Subscript(Expr, Expr)
                   | Name
                   | OverloadedCall()
                   | UnaryOperator(OpId, Expr)
                   | BinaryOperator(OpId, Expr, Init)
                   | ConditionalOperator(Expr, Expr, Expr)
                   | ParenthesizedCast(AType, Expr) [strict(c)]
                   | StaticCast(AType, Expr) [strict(c)]
                   | DynamicCast(AType, Expr)
                   | FunctionalCast(AType, List) [strict(1)]
                   | SizeofType(AType) [strict]
                   | SizeofExpr(Expr)
                   | AlignofType(AType)
                   | AlignofExpr(Expr)
                   | SizeofPack(CId)
                   | PseudoDestructor(Expr, Bool, NNS, AType, AType)
                   | Noexcept(Expr)
                   | NewExpr(Bool, AType, AExpr, Init, List) [strict(2)]
                   | DeleteExpr(Bool, Bool, Expr)

     syntax ResolvedExpr ::= CallExpr(Expr, StrictList, StrictListResult)

     syntax Expr ::= Lambda(CaptureDefault, List, AType, AStmt)
                   | PackExpansionExpr(Expr)
                   | StringLiteral(CharKind, String)
                   | CharacterLiteral(CharKind, Int)
                   | IntegerLiteral(Int, AType) [strict(2)]
                   | FloatingLiteral(Float, AType) [strict(2)]
                   | NullPointerLiteral()
                   | BoolLiteral(Bool)
                   | Throw(AExpr)

     syntax CaptureDefault ::= NoCaptureDefault() | CopyCapture() | RefCapture()

     syntax Capture ::= LambdaCapture(CaptureKind, Bool)

     syntax CaptureKind ::= Decl | This | RefCapture(Decl) [klabel(RefCapture1)]

     syntax CharKind ::= Ascii() | Wide() | UTF8() | UTF16() | UTF32()

     syntax BraceInit ::= BraceInit(List)

     syntax Init ::= BraceInit

     syntax ExpressionList ::= ExpressionList(List)

     syntax Init ::= ExpressionList

     // extensions
     syntax Expr ::= GnuTypeTrait(String, List)
                   | GnuAtomicExpr(String, List)

     // things that are not technically expressions, but will be transformed out
     // of existence by the semantics
     syntax Expr ::= MaterializeTemporaryExpr(Expr)
                   | UnresolvedConstructorCall(AType, List)
                   | TemporaryObjectExpr(AType, List)
                   | ParenList(List)
     syntax Init ::= ConstructorCall(Bool, AType, List)

     syntax AStmt ::= StmtLoc(CabsLoc, AStmt)

endmodule

module CPP-TRANSLATION-ABSTRACT-REWRITING
     imports CPP-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule MemberExpr(false, false, N::Name, E::Expr)
       => #if hasAnonymousUnionObject(E)
          #then N
          #else #if hasAnonymousUnionObject(N)
                #then E
                #else E . no-template N
                #fi
          #fi [anywhere]

     rule MemberExpr(true, false, N::Name, E::Expr) => BinaryOperator(operator->, E, N) [anywhere]

     syntax Bool ::= hasAnonymousUnionObject(Expr) [function]

     rule hasAnonymousUnionObject(ExprLoc(_, E::Expr) => E)

     rule hasAnonymousUnionObject(Name(NoNNS(), #NoName)) => true

     rule hasAnonymousUnionObject(_) => false [owise]

     rule Subscript(E1::Expr, E2::Expr) => BinaryOperator(operator[], E1, E2) [anywhere]

     rule MaterializeTemporaryExpr(E::Expr) => E [anywhere]

     // technically speaking this case could still be value initialization, but in that
     // case value initialization and default initialization have the same semantics.
     // ideally we would get the distinction between the two correct, but clang doesn't fully
     // distinguish by the time we reach the point of abstract syntax, so this will have to do.
     rule ConstructorCall(false, _, .List) => NoInit() [anywhere]

     rule ConstructorCall(true, _, .List) => ExpressionList(.List) [anywhere]

     rule ConstructorCall(_, _, ListItem(E::Expr)) => E [anywhere]

     rule ConstructorCall(_, _, L::List) => ExpressionList(L)
          requires size(L) >Int 1 [anywhere]

     rule TemporaryObjectExpr(T::AType, L::List) => FunctionalCast(T, L) [anywhere]

     rule TypeId(Name(NoNNS(), X::CId)) => ConstructorId(X) [anywhere]

     rule DestructorTypeId(Name(NoNNS(), X::CId)) => DestructorId(X) [anywhere]

     context IfTStmt((HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]

endmodule
