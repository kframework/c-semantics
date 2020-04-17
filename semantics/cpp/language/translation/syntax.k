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

     syntax TypeId ::= TypeId(AType) [symbol]
     syntax DestructorId ::= DestructorTypeId(AType) [symbol]

     syntax CId ::= TypeId

     syntax Decl ::= TranslationUnit(String, List) [symbol]
                   | TypedefDecl(CId, AType) [strict(2), symbol]
                   | TypeAliasDecl(CId, AType) [strict(2), symbol]
                   | LinkageSpec(String, Bool, List) [symbol]
                   | NamespaceDecl(CId, Bool, List) [symbol]
                   | NamespaceAliasDecl(CId, CId, NNS) [symbol]
                   | Specifier(Specifier, Decl) [symbol]
                   | Declarator
                   | FriendDecl(Decl) [symbol]

     syntax CtorInit ::= ConstructorBase(AType, Bool, Bool, Init) [symbol]
                      | ConstructorMember(CId, Init) [symbol]
                      | ConstructorDelegating(Init) [symbol]

     syntax Declarator ::= FunctionDefinition(NNS, CId, CId, AType, List, AStmt) [symbol]
                         | FunctionDecl(NNS, CId, CId, AType, List) [symbol]
                         | VarDecl(NNS, CId, CId, AType, Init, isDirect: Bool) [symbol]
                         | FieldDecl(NNS, CId, AType, Init) [strict(3), symbol]
                         | BitFieldDecl(NNS, CId, AType, Expr) [strict(3), symbol]

     syntax InitOnlyIfOdrUsed ::= OnlyIfOdrUsed(Init) [symbol]
     syntax Stmt ::= InitOnlyIfOdrUsed

     syntax StorageClassSpecifier ::= Mutable() [symbol]

     syntax FunctionSpecifier ::= Explicit()

     syntax Specifier ::= StorageClassSpecifier | FunctionSpecifier
                        | Constexpr() [symbol]
                        | AutoSpecifier

     syntax Decl ::= Template(Decl, List) [symbol]
                   | TemplateWithInstantiations(Decl, List, List) [symbol]

     syntax TemplateParameter ::= TypeTemplateParam(Bool, Bool, AType, AType) [symbol]
                                | ValueTemplateParam(Bool, NNS, CId, AType, AExpr) [symbol]
                                | TemplateTemplateParam(Bool, CId, AType, List) [symbol]

     syntax TemplateArgument ::= TypeArg(AType) [strict, symbol]
                               | TemplateArg(CId) [symbol]
                               | ExprArg(Expr) [symbol]
                               | PackArg(List) [symbol]

     syntax Decl ::= TemplateSpecialization(AType, Decl) [symbol]
                   | TemplateInstantiationDeclaration(AType, Decl) [symbol]
                   | TemplateInstantiationDefinition(AType, Decl) [symbol]
                   | PartialSpecialization(List, List, Decl) [symbol]

     syntax Decl ::= ClassDef(Tag, CId, NNS, List, List, Bool) [symbol]
                   | TypeDecl(AType) [symbol]
                   | EnumDef(id: CId, nns: NNS, scoped: Bool, fixed: Bool, ut: AType, List) [strict(5), symbol]
                   | OpaqueEnumDeclaration(id: CId, scoped: Bool, ut: AType) [strict(3), symbol]
                   | AccessSpec(AccessSpecifier) [symbol]
                   | StaticAssert(Expr, Expr) [symbol]
                   | UsingDecl(Bool, NNS, CId) [symbol]
                   | UsingDirective(CId, NNS) [symbol]

     syntax Decl ::= DeclLoc(CabsLoc, Decl) [symbol]
                   | NoDecl() [symbol]

     syntax BaseSpecifier ::= BaseClass(Bool, Bool, AccessSpecifier, AType) [symbol]

     syntax Enumerator ::= Enumerator(CId, AExpr) [symbol]

     syntax CPPType // defined in CPP-TYPING-SYNTAX

     syntax ATypeResult ::= NoType() [symbol]

     syntax KResult ::= ATypeResult

     syntax AType ::= CPPType
                    | ATypeResult
                    | ElaboratedTypeSpecifier(Tag, CId, NNS) [symbol]
                    | ElaboratedTypeSpecifier(Tag, CId, NNS, List)
                    | FunctionPrototype(AType, StrictList, ExceptionSpec, Bool) [strict(1), symbol]
                    | MethodPrototype(Bool, Bool, AType, AType) [strict(3, 4), symbol]
                    | StaticMethodPrototype(AType) [strict, symbol]
                    | Virtual(AType) [strict, symbol]
                    | Pure(AType) [strict, symbol]
                    | Explicit(AType) [strict, symbol]
                    | BuiltinType(TypeSpecifier) [symbol]
                    | PointerType(AType) [strict, symbol]
                    | MemberPointerType(AType, AType) [strict, symbol]
                    | ArrayType(AType, Int) [strict(1), symbol]
                    | ArrayTypeAExpr(AType, AExpr) [strict(1), symbol]
                    | TypedefType(CId) [symbol]
                    | QualifiedTypeName(Tag, NNS, AType) [symbol]
                    | Decltype(Expr) [symbol]
                    | TemplateParameterType(CId) [symbol]
                    | LValRefType(AType) [strict, symbol]
                    | RValRefType(AType) [strict, symbol]
                    | TemplateSpecializationType(CId, List) [symbol]
                    | TemplateSpecializationType2(CId) [symbol]
                    | PackExpansionType(AType) [symbol]
                    | AutoType(Bool) [symbol]
                    | Name

     context FunctionPrototype(_, HOLE:StrictList => typeStrict(HOLE), _, _)

     // extensions
     syntax AType ::= GnuEnumUnderlyingType2(AType, AType) [symbol]
                    | GnuEnumUnderlyingType1(AType) [symbol]
                    | TypeofExpression(Expr) [symbol]
                    | TypeofType(AType) [symbol]

     syntax ExceptionSpec ::= NoExceptionSpec() [symbol]
                            | NoexceptSpec(AExpr) [symbol]
                            | ThrowSpec(StrictList) [strict, symbol]

     syntax TypeSpecifier ::= Void() [symbol]
                            | Char() [symbol]
                            | WChar() [symbol]
                            | Char16() [symbol]
                            | Char32() [symbol]
                            | Bool() [symbol]
                            | UChar() [symbol]
                            | UShort() [symbol]
                            | UInt() [symbol]
                            | ULong() [symbol]
                            | ULongLong() [symbol]
                            | SChar() [symbol]
                            | Short() [symbol]
                            | Int() [symbol]
                            | Long() [symbol]
                            | LongLong() [symbol]
                            | Float() [symbol]
                            | Double() [symbol]
                            | LongDouble() [symbol]
                            | OversizedInt() [symbol]
                            | OversizedUInt() [symbol]
                            | Dependent() [symbol]
                            | NullPtr() [symbol]

     syntax AType ::= RefQualifier(RefQualifier, AType) [strict(2), symbol]

     syntax AType ::= Qualifier(Qualifier, AType) [strict(2), symbol]

     syntax AStmt ::= Stmt

     syntax Stmt ::= DeclStmt(List) [symbol]
                   | TGotoStmt(CId) [symbol]
                   | TExpressionStmt(Expr) [strict(c), symbol]
                   | TLabelStmt(CId, List) [symbol]
                   | TCatchAnyOp(Stmt) [symbol]
                   | TBreakStmt() [symbol]
                   | ContinueStmt() [symbol]
                   | ReturnStmt(Init) [symbol]
                   | IfTStmt(Decl, Stmt, Stmt)
                   | IfTStmt(Expr, Stmt, Stmt)
                   | WhileTStmt(Decl, Stmt)
                   | WhileTStmt(Expr, Stmt)
                   | NullStmt() [symbol]
                   | ForTStmt(Stmt, Expr, Stmt, Stmt)
                   | ForTStmt(Stmt, Decl, Stmt, Stmt)
                   | ForTStmt(Expr, Stmt, Stmt)
                   | TemplateDefinitionStmt(K) [symbol] // synthetic statement created by the body of a function template definition when it's evaluted before instantiation
                   | TReturnOp(init: Expr, obj: K) [symbol]

     syntax AStmt ::= NoStatement() [symbol]
                    | CompoundAStmt(List) [symbol]
                    | LabelAStmt(CId, List) [symbol]
                    | ForAStmt(AStmt, AExpr, AExpr, AStmt) [symbol]
                    | ForAStmt(AStmt, Decl, AExpr, AStmt)
                    | WhileAStmt(Decl, AStmt)
                    | WhileAStmt(Expr, AStmt) [symbol]
                    | DoWhileAStmt(AStmt, Expr) [symbol]
                    | IfAStmtD(Decl, AStmt, AStmt) [symbol]
                    | IfAStmt(Expr, AStmt, AStmt) [symbol]
                    | SwitchAStmtD(Decl, AStmt) [symbol]
                    | SwitchAStmt(Expr, AStmt) [symbol]
                    | CaseAStmt(Expr, AStmt) [symbol]
                    | DefaultAStmt(AStmt) [symbol]
                    | TryAStmt(AStmt, List) [symbol]
                    | CatchAStmt(CatchDecl, AStmt) [symbol]
                    | CatchStmt(Decl, Stmt) [symbol]
                    | Expr //expression statement, handled later

     syntax Stmt ::= Defaulted() [symbol]
                    | Deleted() [symbol]
                    | Constructor(List, Stmt) [symbol]
                    | Destructor() [symbol]

     syntax CatchDecl ::= Decl | Ellipsis() [symbol]

     syntax AExpr ::= Expr
                    | NoExpression() [symbol]

     syntax Expr ::= MemberExpr(Bool, Bool, Name, Expr) [symbol]
                   | AnonymousUnionObject(AType) [symbol]
                   | Subscript(Expr, Expr) [symbol]
                   | Name
                   | OverloadedCall() [symbol]
                   | UnaryOperator(OpId, Expr) [symbol]
                   | BinaryOperator(OpId, Expr, Init) [symbol]
                   | ConditionalOperator(Expr, Expr, Expr) [symbol]
                   | ParenthesizedCast(AType, Expr) [strict(c), symbol]
                   | StaticCast(AType, Expr) [strict(c), symbol]
                   | DynamicCast(AType, Expr) [symbol]
                   | FunctionalCast(AType, List) [strict(1), symbol]
                   | SizeofType(AType) [strict, symbol]
                   | SizeofExpr(Expr) [symbol]
                   | AlignofType(AType) [symbol]
                   | AlignofExpr(Expr) [symbol]
                   | SizeofPack(CId) [symbol]
                   | PseudoDestructor(Expr, Bool, NNS, AType, AType) [symbol]
                   | Noexcept(Expr) [symbol]
                   | NewExpr(Bool, AType, AExpr, Init, List) [strict(2), symbol]
                   | DeleteExpr(Bool, Bool, Expr) [symbol]

     syntax ResolvedExpr ::= CallExpr(Expr, StrictList, StrictListResult) [symbol]

     syntax Expr ::= Lambda(CaptureDefault, List, AType, AStmt) [symbol]
                   | PackExpansionExpr(Expr) [symbol]
                   | StringLiteral(CharKind, String) [symbol]
                   | CharacterLiteral(CharKind, Int) [symbol]
                   | IntegerLiteral(Int, AType) [strict(2), symbol]
                   | FloatingLiteral(Float, AType) [strict(2), symbol]
                   | NullPointerLiteral() [symbol]
                   | BoolLiteral(Bool) [symbol]
                   | Throw(AExpr) [symbol]

     syntax CaptureDefault ::= NoCaptureDefault() [symbol]
                             | CopyCapture() [symbol]
                             | RefCapture() [symbol]

     syntax Capture ::= LambdaCapture(CaptureKind, Bool) [symbol]

     syntax CaptureKind ::= Decl | This | RefCapture(Decl) [klabel(RefCapture1), symbol]

     syntax CharKind ::= Ascii() [symbol]
                       | Wide() [symbol]
                       | UTF8() [symbol]
                       | UTF16() [symbol]
                       | UTF32() [symbol]

     syntax Init ::= BraceInit(List) [symbol]

     syntax ExpressionList ::= ExpressionList(List) [symbol]

     syntax Init ::= ExpressionList

     // extensions
     syntax Expr ::= GnuTypeTrait(String, List) [symbol]
                   | GnuAtomicExpr(String, List) [symbol]

     // things that are not technically expressions, but will be transformed out
     // of existence by the semantics
     syntax Expr ::= MaterializeTemporaryExpr(Expr) [symbol]
                   | UnresolvedConstructorCall(AType, List) [symbol]
                   | TemporaryObjectExpr(AType, List) [symbol]
                   | ParenList(List) [symbol]
     syntax Init ::= ConstructorCall(Bool, AType, List) [symbol]

     syntax AStmt ::= StmtLoc(CabsLoc, AStmt) [symbol]

     syntax Bool ::= "#isBraceInit" "(" KItem ")" [function]

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

     rule hasAnonymousUnionObject(ExprLoc(_, E:Expr) => E)

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

     rule #isBraceInit(ExprLoc(_, X::KItem) => X)

     rule #isBraceInit(BraceInit(_)) => true

     rule #isBraceInit(_) => false [owise]

endmodule
