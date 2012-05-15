module DYNAMIC-SEMANTICS-TYPE-INCLUDE is
	// FIXME need to automatically pad structs
	including DYNAMIC-INCLUDE 
	including COMMON-SEMANTICS-TYPE-INCLUDE
end module

module DYNAMIC-SEMANTICS-TYPE-STRICTNESS is
	including DYNAMIC-SEMANTICS-TYPE-INCLUDE

	syntax K ::= "waitingOnDeclType" [klabel(waitingOnDeclType)] 
	rule [type-Cast-heat]:
		<k> (. => DeclType(Specifier:K, DeclType:K)) ~> evalToType ...</k>
		<type> Cast(Specifier:K, DeclType:K, _) => waitingOnDeclType ...</type>
		[structural]
		
	rule [type-Cast-cool]:
		<k> (T:KResult => .) ~> evalToType ...</k>
		<type> waitingOnDeclType => T:KResult ...</type>
		[structural]
end module

module DYNAMIC-SEMANTICS-TYPE-EXPRESSIONS is
	including DYNAMIC-SEMANTICS-TYPE-INCLUDE
	
	rule
		<k> typeof(K:K) => evalToType ~> typeof(MYHOLE) ...</k>
		(.Bag => <type> K:K </type>)
		[structural]
	rule
		<k> evalToType ~> typeof(MYHOLE) => T:TypeResult ...</k>
		(<type> T:TypeResult </type> => .Bag)
		[structural]

	// these are sort of artifacts of other things
	rule
		<type> emptyValue => t(.Set, void) ...</type> 
		[structural]
	rule
		<type> tv(_, T:KResult) => T:KResult ...</type>
		[structural]
	rule 
		<type> E1:K[E2:K] => *(E1:K + E2:K) ...</type> 
		[structural]
	// rule 
		// <type> arithInterpret(T:KResult, _) => T:KResult ...</type> 
		// [structural]
	
	// mb latexComment("String") : KSentence [metadata "foo"] 
	//! \begin{rulesGroup}
	/*@	\fromStandard{\source[n1570]{\para{6.5.7}{3}}}{
	The integer promotions are performed on each of the operands. The type of the result is that of the promoted left operand. \ldots
	}*/	
	rule
		<type> T:KResult << _ => promote(T:KResult) ...</type>
		[structural]
	rule
		<type> T:KResult >> _ => promote(T:KResult) ...</type>
		[structural]
	//! \end{rulesGroup}
	
	/*@ %\begin{rulesGroup}
	\fromStandard{\source[n1570]{\para{6.5.3.4}{5}}}{
	The value of the result of both operators is implementation-defined, and its type (an unsigned integer type) is \cinline{size_t}, defined in \header{<stddef.h>} (and other headers).
	}*/	
	rule
		<type> SizeofExpression(_) => cfg:sizeut ...</type>
		[structural]
	//@ %\end{rulesGroup}

	rule
		<type> t(S:Set, pointerType(T:KResult)) + T':KResult => t(S:Set, pointerType(T:KResult)) ...</type>
		when hasIntegerType(T':KResult)
		[structural]
	rule
		<type> T':KResult + t(S:Set, pointerType(T:KResult)) => t(S:Set, pointerType(T:KResult)) ...</type>
		when hasIntegerType(T':KResult)
		[structural]
	rule
		<type> t(S:Set, pointerType(T:KResult)) - T':KResult => t(S:Set, pointerType(T:KResult)) ...</type>
		when hasIntegerType(T':KResult)
		[structural]
	rule
		<type> t(_, pointerType(T:KResult)) - t(_, pointerType(T':KResult)) => cfg:ptrdiffut ...</type>
		[structural]
	rule
		<type> t(S:Set, arrayType(T:KResult, _:Nat)) + T':KResult => t(S:Set, pointerType(T:KResult)) ...</type>
		when hasIntegerType(T':KResult)
		[structural]
	rule
		<type> T':KResult + t(S:Set, arrayType(T:KResult, _:Nat)) => t(S:Set, pointerType(T:KResult)) ...</type>
		when hasIntegerType(T':KResult)
		[structural]
	rule
		<type> t(S:Set, arrayType(T:KResult, _:Nat)) - T':KResult => t(S:Set, pointerType(T:KResult)) ...</type>
		when hasIntegerType(T':KResult)
		[structural]

	// c99 6.4.5
	rule
		<type> Constant(StringLiteral(S:String)) 
			=> t(.Set, arrayType(t(.Set, char), lengthString(S:String) +Int 1)) 
		...</type>
		[structural]
	rule
		<type> Constant(WStringLiteral(L:List{K})) 
			=> t(.Set, arrayType(cfg:wcharut, lengthList{K}(L:List{K}) +Int 1)) 
		...</type>
		[structural]
		
	rule
		<type> K:K => T:KResult ...</type>
		<types>... K:K |-> T:KResult ...</types>
		[structural]
	
	/*@ \fromStandard{\source[n1570]{\para{6.5.17}{2}}}{
	The left operand of a comma operator is evaluated as a void expression; there is a sequence point between its evaluation and that of the right operand. Then the right operand is evaluated; the result has its type and value.
	}*/
	rule
		<type> Comma(List((_,, K:K))) => K:K ...</type>
		[structural]

	/*@ \fromStandard{\source[n1570]{\para{6.5.2.2}{5}}}{
	If the expression that denotes the called function has type pointer to function returning an object type, the function call expression has the same type as that object type, and has the value determined as specified in 6.8.6.4. Otherwise, the function call has type \cinline{void}.
	}*/
	rule [type-call-func]:
		<type> Call(T:KResult, _) => innerType(T:KResult) ...</type>
		[structural]
		
	/*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{3}}}{
	A postfix expression followed by the \cinline{.} operator and an identifier designates a member of a structure or union object. The value is that of the named member, and is an lvalue if the first expression is an lvalue. If the first expression has qualified type, the result has the so-qualified version of the type of the designated member.
	}*/
	rule [type-struct-dot]:
		<type> t(_, structType(S:Id)) . F:Id => T:KResult ...</type>
		<structs>...
			S:Id |-> aggregateInfo(_, (_ F:Id |-> T:KResult), _)
		...</structs>
		[structural]
	rule [type-union-dot]:
		<type> t(_, unionType(S:Id)) . F:Id => T:KResult ...</type>
		<structs>...
			S:Id |-> aggregateInfo(_, (_ F:Id |-> T:KResult), _)
		...</structs>
		[structural]

	/*@ \fromStandard{\source[n1570]{\para{6.5.3.2}{4}}}{
	The unary \cinline{*} operator denotes indirection. If the operand points to a function, the result is a function designator; if it points to an object, the result is an lvalue designating the object. If the operand has type ``pointer to type'', the result has type ``type''. \ldots
	}*/
	rule [type-deref-type]:
		<type> * T:KResult => innerType(T:KResult) ...</type>
		[structural]

	rule [type-compound-literal]:
		<type> CompoundLiteral(_, Specifier:K, DeclType:K, _)
			=> Cast(Specifier:K, DeclType:K, emptyValue)  // sort of hackish, assumes cast will evaluate to type
		...</type>
		[structural]
	
	rule [type-assignment]:
		<type> L:KLabel(K:K,, _)
			=> K:K
		...</type>
		when assignmentLabels contains l(L:KLabel)
		[structural]

	rule 
		<type> L:KLabel(T:KResult,, T':KResult) => usualArithmeticConversion(T:KResult, T':KResult) ...</type>
		when isArithBinConversionOp(L:KLabel)
		andBool (hasIntegerType(T:KResult) orBool isFloatType(T:KResult))
		andBool (hasIntegerType(T':KResult) orBool isFloatType(T':KResult))
		[structural]
		
	rule [type-ternary-arithmetic]:
		<type> _:K ? T:KResult : T':KResult => usualArithmeticConversion(T:KResult, T':KResult) ...</type>
		when (hasIntegerType(T:KResult) orBool isFloatType(T:KResult))
		andBool (hasIntegerType(T':KResult) orBool isFloatType(T':KResult))
		[structural]
	rule [type-ternary-identical]:
		<type> _:K ? T:TypeResult : T:TypeResult => T:TypeResult ...</type>
		when notBool isArrayType(T:TypeResult)
		[structural]
		
	rule [type-ternary-array-left]: 
		<type> _:K ? (t(S:Set, arrayType(T:KResult, _:Nat)) => t(S:Set, pointerType(T:KResult))) : _ ...</type> 
		[structural]
	rule [type-ternary-array-right]: 
		<type> _:K ? _:K : (t(S:Set, arrayType(T:KResult, _:Nat)) => t(S:Set, pointerType(T:KResult))) ...</type>
		[structural]
		
	rule [type-ternary-pointer]: // not safe, could be incompatible types
		<type> _:K ? t(S:Set, pointerType(T:KResult)) : t(S':Set, pointerType(T':KResult)) => t(S:Set, pointerType(T:KResult)) ...</type>
		[structural]

	rule
		<type> L:KLabel(T:KResult) => T:KResult ...</type> 
		when isArithUnaryOp(L:KLabel)
		andBool isFloatType(T:KResult)
		[structural]
	rule
		<type> L:KLabel(T:KResult) => promote(T:KResult) ...</type> 
		when isArithUnaryOp(L:KLabel)
		andBool hasIntegerType(T:KResult)
		[structural]
	
	rule 
		<type> L:KLabel(T:KResult,, _:List{K}) => T:KResult ...</type>
		when isFloatType(T:KResult)
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural]
	rule 
		<type> L:KLabel(T:KResult,, _:List{K}) => promote(T:KResult) ...</type>
		when hasIntegerType(T:KResult)
		andBool typeStrictLeftBinaryOperators contains l(L:KLabel)
		[structural]
		
	rule [type-inc-dec]:
		<type> L:KLabel(T:KResult) => T:KResult ...</type>
		when isPointerType(T:KResult)
		andBool (
			L:KLabel ==KLabel ('_++)
			orBool L:KLabel ==KLabel ('_--)
			orBool L:KLabel ==KLabel ('--_)
			orBool L:KLabel ==KLabel ('++_)
		)
		[structural]
	
	rule
		<type> !(_:K) => t(.Set, int) ...</type>
		[structural]
		
	rule
		<type> L:KLabel(_:K,, _:K) => t(.Set, int) ...</type>
		when L:KLabel ==KLabel '_==_
		orBool L:KLabel ==KLabel '_!=_
		orBool L:KLabel ==KLabel '_&&_
		orBool L:KLabel ==KLabel '_||_
		[structural]
		
	rule [type-address]:
		<type> & T:TypeResult => t(.Set, pointerType(T:TypeResult)) ...</type>
		[structural]
		
end module

module DYNAMIC-SEMANTICS-TYPE-MISC is
	including  DYNAMIC-SEMANTICS-TYPE-INCLUDE
	
	rule [ExpressionLoc-type]:
		<type> ExpressionLoc(K:K, L:CabsLoc) => K:K ...</type>
		<currentProgramLoc> _ => L:CabsLoc </currentProgramLoc>
		[structural]
end module

module DYNAMIC-C-TYPING is
	including DYNAMIC-SEMANTICS-TYPE-INCLUDE
	
	including DYNAMIC-SEMANTICS-TYPE-STRICTNESS
	including DYNAMIC-SEMANTICS-TYPE-EXPRESSIONS
	including DYNAMIC-SEMANTICS-TYPE-MISC
end module
