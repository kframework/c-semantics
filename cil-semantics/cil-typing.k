// vim: set ts=2 sw=2:
module CIL-TYPING-SYNTAX
  syntax NormType ::= nt(Type)
  syntax Type ::= NormType

  // Checks if a normalized type is a pointer type.
  syntax Bool ::= isPtrType(Type) [function]

  // Checks if a normalized type is an array type.
  syntax Bool ::= isArrayType(Type) [function]

  // Checks if a normalized type is a function type.
  syntax Bool ::= isFunType(Type) [function]

  // Add a layer of indirection to a normalized pointer type.
  syntax Type ::= upPtr(Type) [function]

  // Remove a layer of indirection (from a normalized pointer type).
  syntax Type ::= downPtr(Type) [function]

  // Remove a layer of indirection (from a normalized array type).
  syntax Type ::= downArray(Type) [function]

  // Remove a layer of indirection (from a normalized function type), i.e.,
  // extract the function result type.
  syntax Type ::= downFun(Type) [function]

  // Returns the size of a normalized array type.
  syntax Int ::= getArraySize(Type) [function]

  // Get the function parameters of the top-level identifier (not very useful
  // if the declarator has been normalized).
  syntax Params ::= getParams(Declarator) [function]

  // Extract the top-level identifier from the very heart of a (non-normalized)
  // declarator.
  syntax CId ::= getId(Declarator) [function]

  syntax Type ::= expandTypedefs(Type, Map) [function]

  syntax Type ::= normType(Type) [function]
endmodule

module CIL-TYPING
  imports CIL-TYPING-SYNTAX
  imports CIL-SYNTAX
  imports CIL-COMMON
  imports CIL-COMMON-TYPED-VALUE
  imports K-FUNCTIONAL-VISITOR

  syntax SymId ::= "#__id__"
  syntax DirectDecl ::= SymId

  // Visits only the leftmost branch of the AST (except when an exception node
  // is encountered, then it visits the next-to-leftmost branch).
  // AST to search, the transformation to apply, extra trans arg, the
  // predicate, the exception.
  syntax K ::= #leftVisit(K, KLabel, KList, KLabel, KLabel) [function]
  syntax K ::= #leftVisit(K, KLabel, KLabel, KLabel) [function]
  rule #leftVisit(K:K, Trans:KLabel, Pred:KLabel, Except:KLabel)
    => #leftVisit(K, Trans, .KList, Pred, Except)
  rule #leftVisit(K:K, Trans:KLabel, Arg:KList, Pred:KLabel, _)
    => Trans(K,, Arg)
    when Pred(K) ==K true
  rule 
    #leftVisit(
      Lbl:KLabel(P:K,, K:K,, L:KList), 
      Trans:KLabel, Arg:KList, Pred:KLabel, Except:KLabel)
    => Lbl(P:K,, #leftVisit(K, Trans, Arg, Pred, Except),, L)
    when (Pred(Lbl(P,, K,, L)) =/=K true) 
      andBool (getKLabel(P) ==KLabel Except)
  rule 
    #leftVisit(
      Lbl:KLabel(K:K,, L:KList), 
      Trans:KLabel, Arg:KList, Pred:KLabel, Except:KLabel)
    => Lbl(#leftVisit(K, Trans, Arg, Pred, Except),, L)
    when (Pred(Lbl(K,, L)) =/=K true)
      andBool (getKLabel(K) =/=KLabel Except)
  rule #leftVisit(Lbl:KLabel(.KList), _, _, Pred:KLabel, _)
    => Lbl(.KList)
    when Pred(Lbl(.KList)) =/=K true

  syntax Type ::= replaceTopId(Type, DirectDecl) [function]
  syntax DirectDecl ::= replaceTopIdTrans(DirectDecl, DirectDecl) [function]
  rule replaceTopId(T:Type, D:DirectDecl) =>
    #leftVisit(T, 'replaceTopIdTrans, D, isSymId, '*)
  rule replaceTopIdTrans(_:DirectDecl, New:DirectDecl)
    => New

  // Searches the leftmost branch of the AST and returns the
  // first node for which the predicate holds, .K if nothing found.
  // AST to search, the predicate, the exception.
  syntax K ::= leftSearch(K, KLabel, KLabel) [function]
  rule leftSearch(K:K, Pred:KLabel, _:KLabel)
    => K
    when Pred(K) ==K true
  rule leftSearch(Lbl:KLabel(P:K,, K:K,, L:KList), Pred:KLabel, Except:KLabel)
    => leftSearch(K, Pred, Except)
    when Pred(Lbl(P,, K,, L)) =/=K true
      andBool (getKLabel(P) ==KLabel Except)
  rule leftSearch(Lbl:KLabel(K:K,, L:KList), Pred:KLabel, Except:KLabel)
    => leftSearch(K, Pred, Except)
    when Pred(Lbl(K,, L)) =/=K true
      andBool (getKLabel(K) =/=KLabel Except)
  rule leftSearch(Lbl:KLabel(.KList), Pred:KLabel, _)
    => .K
    when Pred(Lbl(.KList)) =/=K true

  syntax Bool ::= "$isPtrType" "(" K ")" [function, klabel('$isPtrType)]
  rule isPtrType(TS:TypeSpec) => false
  rule isPtrType(TS:TypeSpec D:Declarator) 
    => leftSearch(D, '$isPtrType, '*) =/=K .K
  rule $isPtrType(* #__id__) => true
  // TODO(chathhorn): not entirely sure how to treat this case.
  rule $isPtrType(#__id__[]) => true

  syntax Bool ::= "$isArrayType" "(" K ")" [function, klabel('$isArrayType)]
  rule isArrayType(TS:TypeSpec) => false
  rule isArrayType(TS:TypeSpec D:Declarator) 
    => leftSearch(D, '$isArrayType, '*) =/=K .K
  rule $isArrayType(#__id__[_]) => true

  syntax Bool ::= "$isFunType" "(" K ")" [function, klabel('$isFunType)]
  rule isFunType(TS:TypeSpec) => false
  rule isFunType(TS:TypeSpec D:Declarator) 
    => leftSearch(D, '$isFunType, '*) =/=K .K
  rule $isFunType(#__id__(_)) => true
  rule $isFunType(#__id__()) => true

  syntax DirectDecl ::= upPtrConv(DirectDecl) [function]
  rule upPtr(TS:TypeSpec) => normType(TS ('`(_`)(* #__id__))::Declarator)
  rule upPtr(TS:TypeSpec D:Declarator) 
    => normType(TS #leftVisit(D, 'upPtrConv, isSymId, '*)::Declarator)
  rule upPtrConv(X:SymId) => '`(_`)(*X)

  syntax Bool ::= "$needsDownPtrConv" "(" K ")" 
    [function, klabel('$needsDownPtrConv)]
  syntax Declarator ::= downPtrConv(Declarator) [function]
  rule downPtr(TS:TypeSpec D:Declarator) 
    => normType(TS #leftVisit(D, 'downPtrConv, '$needsDownPtrConv, '*)::Declarator)
  rule $needsDownPtrConv(*X:SymId) => true
  rule downPtrConv(*X:SymId) => X

  syntax Bool ::= "$needsDownArrayConv" "(" K ")" 
    [function, klabel('$needsDownArrayConv)]
  syntax Declarator ::= downArrayConv(Declarator) [function]
  rule downArray(TS:TypeSpec D:Declarator) 
    => normType(TS #leftVisit(D, 'downArrayConv, '$needsDownArrayConv, '*)::Declarator)
  rule $needsDownArrayConv(X:SymId[]) => true
  rule $needsDownArrayConv(X:SymId[_]) => true
  rule downArrayConv(X:SymId[]) => X
  rule downArrayConv(X:SymId[_]) => X

  syntax Bool ::= "$needsDownFunConv" "(" K ")" 
    [function, klabel('$needsDownFunConv)]
  syntax Declarator ::= downFunConv(Declarator) [function]
  rule downFun(TS:TypeSpec D:Declarator) 
    => normType(TS #leftVisit(D, 'downFunConv, '$needsDownFunConv, '*)::Declarator)
  rule $needsDownFunConv(X:SymId()) => true
  rule $needsDownFunConv(X:SymId(_)) => true
  rule downFunConv(X:SymId()) => X
  rule downFunConv(X:SymId(_)) => X

  rule getId(X:CId) => X
  rule getId(P:Pointer D:DirectDecl) => getId(D)
  rule getId('`(_`)(D:Declarator)) => getId(D)
  rule getId(D:DirectDecl()) => getId(D)
  rule getId(D:DirectDecl[]) => getId(D)
  rule getId(D:DirectDecl(_)) => getId(D)
  rule getId(D:DirectDecl[_]) => getId(D)

  syntax Int ::= "getArraySize'" "(" K ")" [function]
  rule getArraySize(TS:TypeSpec D:Declarator) 
    => getArraySize'(leftSearch(D, '$isArrayType, '*))
  rule getArraySize'(#__id__[C:Constant]) => C

  syntax Params ::= "getParams'" "(" Declarator ")" [function]
  // Must normalize parens before this works.
  rule getParams(D:Declarator) => getParams'(normParens(D))

  rule getParams'(P:Pointer D:DirectDecl) => getParams'(D)
  rule getParams'('`(_`)(D:Declarator)) => getParams'(D)
  rule getParams'(X:CId()) => .Params
  rule getParams'(D:DirectDecl()) => getParams'(D)
    when isCId(D) =/=K true
  rule getParams'(D:DirectDecl[]) => getParams'(D)
  rule getParams'(X:CId(Ps:Params)) => Ps
  rule getParams'(D:DirectDecl(_)) => getParams'(D)
    when isCId(D) =/=K true
  rule getParams'(D:DirectDecl[_]) => getParams'(D)

  // One might expect that one could just do a simple search-and-replace to
  // remove typedef'd identifiers, but one would unfortunately be wrong.
  // Consider:
  //
  // typedef int arr[5];
  // arr x;
  // 
  // If we just replace arr with its normalized type we get something like:
  // 
  // int #__id__[5] x;
  // 
  // which isn't valid declaration or type syntax. What we actually have to do
  // is substitute the designator to the right with the top-level identifier in
  // the typedef to get:
  // 
  // int x[5];
  // 
  syntax ParamDecl ::= expandParamDecl(ParamDecl, Map) [function]
  syntax Declarator ::= expandDecl(Declarator, Map) [function]
  syntax DirectDecl ::= expandDirectDecl(DirectDecl, Map) [function]
  syntax Params ::= expandParams(Params, Map) [function]

  // TODO(chathhorn): It'd be nice to generalize this process of walking the
  // declaration syntax tree.
  rule expandTypedefs(T:ParamDecl, E:Map) => expandParamDecl(T, E)

  // TODO(chathhorn): probably should go back to a special typedef cell to
  // reduce the amount of stuff that must be passed around.
  rule expandParamDecl(X:CId, E:Map X |-> T:Type)
    => expandTypedefs(T, E X |-> T)
  rule expandParamDecl(X:CId D:Declarator, E:Map X |-> T:Type)
    => expandTypedefs(normParens(replaceTopId(T, '`(_`)(D))), E X |-> T)
  rule expandParamDecl(TS:TypeSpec, _) => TS
    when isCId(TS) =/=K true orBool isKeyword(TS) ==K true
  rule expandParamDecl(TS:TypeSpec D:Declarator, E:Map) 
    => TS expandDecl(D, E)
    when isCId(TS) =/=K true orBool isKeyword(TS) ==K true

  rule expandDecl(D:DirectDecl, E:Map) => expandDirectDecl(D, E)
  rule expandDecl(P:Pointer D:DirectDecl, E:Map) => P expandDirectDecl(D, E)

  rule expandDirectDecl(X:SymId, E:Map) => X
  rule expandDirectDecl('`(_`)(D:Declarator), E:Map) 
    => '`(_`)(expandDecl(D, E))
  rule expandDirectDecl(D:DirectDecl(), E:Map) => expandDirectDecl(D, E)()
  rule expandDirectDecl(D:DirectDecl[], E:Map) => expandDirectDecl(D, E)[]
  rule expandDirectDecl(D:DirectDecl(Ps:Params), E:Map) 
    => expandDirectDecl(D, E)(expandParams(Ps, E))
  rule expandDirectDecl(D:DirectDecl[C:Constant], E:Map) 
    => expandDirectDecl(D, E)[C]

  rule expandParams(P:ParamDecl, Ps:Params, E:Map) 
    => expandParamDecl(P, E), expandParams(Ps, E)
  rule expandParams(.Params, _) => .Params

  // The basic idea here is that a "type" will be nothing more than a
  // normalized declaration. We normalize declarations by:
  // 1. stripping storage class specifiers,
  // 2. turning abstract declarators into non-abstract declarators (noting 3)
  //    (an abstract declarator is one without an identifier)
  //    (except that we leave out the identifier if it would be undecorated),
  // 3. replacing all identifiers with a special symbolic identifier,
  // 4. and normalizing parens.
  // 
  // The resulting types are basically inside-out and a pain to work with, but
  // they at least maintain the conciseness of basic types (i.e., "unsigned
  // int" is in normal form -- but "int*" is not).
  rule normType(T:Type) 
    => normParens(convDecls(T))

  // This is kinda subtle. Both abstract and non-abstract declarators might
  // also have children of both sorts and it's not very easy to distinguish the
  // two.
  syntax Type ::= convDecls(Type) [function]
  syntax ParamDecl ::= convParamDecl(ParamDecl) [function]
  syntax Declarator ::= convDecl(Declarator) [function]
  syntax DirectDecl ::= convDirectDecl(DirectDecl) [function]
  syntax Declarator ::= convAbsDecl(AbsDecl) [function]
  syntax DirectDecl ::= convDirectAbsDecl(DirectAbsDecl) [function]
  syntax Params ::= convParams(Params) [function]

  rule convDecls(T:ParamDecl) => convParamDecl(T)

  rule convParamDecl(TS:TypeSpec) => TS
  rule convParamDecl(TS:TypeSpec X:SymId) => TS
  rule convParamDecl(TS:TypeSpec X:CId) => TS
  rule convParamDecl(TS:TypeSpec D:Declarator) => TS convDecl(D)
    when (isCId(D) =/=K true) andBool (isSymId(D) =/=K true)
  rule convParamDecl(TS:TypeSpec D:AbsDecl) => TS convAbsDecl(D)

  rule convParamDecl(_:StorageClassSpec TS:TypeSpec) => TS
  rule convParamDecl(_:StorageClassSpec TS:TypeSpec X:SymId) => TS
  rule convParamDecl(_:StorageClassSpec TS:TypeSpec X:CId) => TS
  rule convParamDecl(_:StorageClassSpec TS:TypeSpec D:Declarator) => TS convDecl(D)
    when (isCId(D) =/=K true) andBool (isSymId(D) =/=K true)
  rule convParamDecl(_:StorageClassSpec TS:TypeSpec D:AbsDecl) => TS convAbsDecl(D)

  rule convDecl(D:DirectDecl) => convDirectDecl(D)
  rule convDecl(P:Pointer D:DirectDecl) => P convDirectDecl(D)

  rule convDirectDecl(X:SymId) => X
  rule convDirectDecl(X:CId) => #__id__
  rule convDirectDecl('`(_`)(D:Declarator)) => '`(_`)(convDecl(D))
  rule convDirectDecl(D:DirectDecl()) => convDirectDecl(D)()
  rule convDirectDecl(D:DirectDecl[]) => convDirectDecl(D)[]
  rule convDirectDecl(D:DirectDecl(Ps:Params)) 
    => convDirectDecl(D)(convParams(Ps))
  rule convDirectDecl(D:DirectDecl[C:Constant]) => convDirectDecl(D)[C]

  rule convParams(P:ParamDecl, Ps:Params) 
    => convParamDecl(P), convParams(Ps)
  rule convParams(.Params) => .Params

  rule convAbsDecl(P:Pointer) => P #__id__
  rule convAbsDecl(D:DirectAbsDecl) 
    => convDirectAbsDecl(D)
  rule convAbsDecl(P:Pointer D:DirectAbsDecl) 
    => P convDirectAbsDecl(D)

  rule convDirectAbsDecl( () ) => #__id__()
  rule convDirectAbsDecl( [] ) => #__id__[]
  rule convDirectAbsDecl( '`(_`)(D:AbsDecl) ) => '`(_`)(convAbsDecl(D))
  rule convDirectAbsDecl( '`(_`)(Ps:Params) ) => #__id__(convParams(Ps))
  rule convDirectAbsDecl( [C:Constant] ) => #__id__[C]
  rule convDirectAbsDecl( D:DirectAbsDecl() ) => convDirectAbsDecl(D)()
  rule convDirectAbsDecl( D:DirectAbsDecl[] ) => convDirectAbsDecl(D)[]
  rule convDirectAbsDecl( D:DirectAbsDecl(Ps:Params) ) 
    => convDirectAbsDecl(D)(convParams(Ps))
  rule convDirectAbsDecl( D:DirectAbsDecl[C:Constant] ) 
    => convDirectAbsDecl(D)[C]

  // TODO(chathhorn): probably more to do here. Also consider parens in cases
  // like (*(*#__id__))
  syntax Bool ::= "$needsParensNorm" "(" K ")" [function]
  syntax K ::= normParens(K) [function]
  syntax KList ::= "normParens'" "(" KList ")" [function]

  rule $needsParensNorm('`(_`)('`(_`)(K:K))) => true
  rule $needsParensNorm('`(_`)(X:SymId)) => true
  rule $needsParensNorm('`(_`)(X:SymId[_])) => true

  rule normParens(Lbl:KLabel(K:K)) => normParens(K)
    when $needsParensNorm(Lbl(K)) ==K true
  rule normParens(Lbl:KLabel(L:KList)) => Lbl(normParens'(L))
    when $needsParensNorm(Lbl(L)) =/=K true

  rule normParens'(K:K,, L:KList) => normParens(K),, normParens'(L)
  rule normParens'(.KList) => .KList
endmodule

