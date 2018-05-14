module C-COMMON-EXPR-RELATIONAL-SYNTAX
     imports BASIC-K
     imports C-TYPING-SORTS
     syntax Bool ::= isCompatibleEqualityTypes(UType, UType, K, K) [function]
endmodule

module C-COMMON-EXPR-RELATIONAL
     imports C-COMMON-EXPR-RELATIONAL-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports FLOAT
     imports INT
     imports K-EQUAL
     imports K-REFLECTION
     imports SETTINGS-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-BITS-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     syntax KItem ::= makeTruth(Bool, UType, UType) [function]
     syntax UType ::= makeTruthType(UType, UType) [function]
     rule makeTruth(B:Bool, T::UType, T'::UType)
          => #if B #then tv(1, makeTruthType(T, T')) #else tv(0, makeTruthType(T, T')) #fi
     rule makeTruthType(T::UType, T'::UType)
          => ut(SetItem(IntegerConstant), int)
          requires fromConstantExpr(T) andBool fromConstantExpr(T')
     rule makeTruthType(T::UType, T'::UType)
          => utype(int)
          requires notBool fromConstantExpr(T) orBool notBool fromConstantExpr(T')

     /*@ \fromStandard{\source[n1570]{\para{6.5.8}{3}}}{
     If both of the operands have arithmetic type, the usual arithmetic
     conversions are performed.
     }

     \fromStandard{\source[n1570]{\para{6.5.8}{4}}}{
     For the purposes of these operators, a pointer to an object that is not an
     element of an array behaves the same as a pointer to the first element of
     an array of length one with the type of the object as its element type.
     }

     \fromStandard{\source[n1570]{\para{6.5.8}{5}}}{
     When two pointers are compared, the result depends on the relative
     locations in the address space of the objects pointed to. If two pointers
     to object types both point to the same object, or both point one past the
     last element of the same array object, they compare equal. If the objects
     pointed to are members of the same aggregate object, pointers to structure
     members declared later compare greater than pointers to members declared
     earlier in the structure, and pointers to array elements with larger
     subscript values compare greater than pointers to elements of the same
     array with lower subscript values. All pointers to members of the same
     union object compare equal. If the expression \cinline{P} points to an
     element of an array object and the expression \cinline{Q} points to the
     last element of the same array object, the pointer expression
     \cinline{Q+1} compares greater than \cinline{P}. In all other cases, the
     behavior is undefined.
     }

     \fromStandard{\source[n1570]{\para{6.5.8}{6}}}{
     Each of the operators \cinline{<} (less than), \cinline{>} (greater than),
     \cinline{<=} (less than or equal to), and \cinline{>=} (greater than or
     equal to) shall yield 1 if the specified relation is true and 0 if it is
     false. The result has type \cinline{int}.
     }*/

     rule tv(I1:Int, T::UType) < tv(I2:Int, T'::UType)
          => makeTruth(I1 <Int I2, T, T')
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T::UType) <= tv(I2:Int, T'::UType)
          => makeTruth(I1 <=Int I2, T, T')
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T::UType) > tv(I2:Int, T'::UType)
          => makeTruth(I1 >Int I2, T, T')
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T::UType) >= tv(I2:Int, T'::UType)
          => makeTruth(I1 >=Int I2, T, T')
          requires isPromoted(T)
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) < tv(F2:Float, T'::UType)
          => makeTruth(F1 <Float F2, T, T')
          requires T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) <= tv(F2:Float, T'::UType)
          => makeTruth(F1 <=Float F2, T, T')
          requires T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) > tv(F2:Float, T'::UType)
          => makeTruth(F1 >Float F2, T, T')
          requires T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) >= tv(F2:Float, T'::UType)
          => makeTruth(F1 >=Float F2, T, T')
          requires T ==Type T'
          [structural]

     rule (.K => UNDEF("CERL6", "Ordered comparison of a null pointer."))
          ~> tv(L:SymLoc, _) < tv(R:SymLoc, _)
          requires L ==K NullPointer orBool R ==K NullPointer
     rule (.K => UNDEF("CERL6", "Ordered comparison of a null pointer."))
          ~> tv(L:SymLoc, _) <= tv(R:SymLoc, _)
          requires L ==K NullPointer orBool R ==K NullPointer
     rule (.K => UNDEF("CERL6", "Ordered comparison of a null pointer."))
          ~> tv(L:SymLoc, _) > tv(R:SymLoc, _)
          requires L ==K NullPointer orBool R ==K NullPointer
     rule (.K => UNDEF("CERL6", "Ordered comparison of a null pointer."))
          ~> tv(L:SymLoc, _) >= tv(R:SymLoc, _)
          requires L ==K NullPointer orBool R ==K NullPointer

     //- comparison of pointers
     rule tv(Loc:SymLoc, T::UType) < tv(Loc':SymLoc, T'::UType)
          => makeTruth(offset(Loc) <Int offset(Loc'), T, T')
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool sameBase(Loc, Loc')
           andBool isCompatibleRelationalTypes(T, T')
          [structural]
     rule (.K => UNDEF("CERL1", "Cannot compare pointers with different base objects using '<'."))
          ~> tv(Loc:SymLoc, T::UType) < tv(Loc':SymLoc, T'::UType)
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool notBool sameBase(Loc, Loc')
               andBool T ==Type T'
          [structural]
     rule tv(Loc:SymLoc, T::UType) <= tv(Loc':SymLoc, T'::UType)
          => makeTruth(offset(Loc) <=Int offset(Loc'), T, T')
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool sameBase(Loc, Loc')
           andBool isCompatibleRelationalTypes(T, T')
          [structural]
     rule (.K => UNDEF("CERL2", "Cannot compare pointers with different base objects using '<='."))
          ~> tv(Loc:SymLoc, T::UType) <= tv(Loc':SymLoc, T'::UType)
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool notBool sameBase(Loc, Loc')
               andBool T ==Type T'
          [structural]
     rule tv(Loc:SymLoc, T::UType) > tv(Loc':SymLoc, T'::UType)
          => makeTruth(offset(Loc) >Int offset(Loc'), T, T')
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool sameBase(Loc, Loc')
           andBool isCompatibleRelationalTypes(T, T')
          [structural]
     rule (.K => UNDEF("CERL3", "Cannot compare pointers with different base objects using '>'."))
          ~> tv(Loc:SymLoc, T::UType) > tv(Loc':SymLoc, T'::UType)
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool notBool sameBase(Loc, Loc')
               andBool T ==Type T'
          [structural]
     rule tv(Loc:SymLoc, T::UType) >= tv(Loc':SymLoc, T'::UType)
          => makeTruth(offset(Loc) >=Int offset(Loc'), T, T')
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool sameBase(Loc, Loc')
           andBool isCompatibleRelationalTypes(T, T')
          [structural]
     rule (.K => UNDEF("CERL4", "Cannot compare pointers with different base objects using '>='."))
          ~> tv(Loc:SymLoc, T::UType) >= tv(Loc':SymLoc, T'::UType)
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool notBool sameBase(Loc, Loc')
               andBool T ==Type T'
          [structural]

     rule (.K => CV("CERL5", "Incompatible types in relational expression."))
          ~> L:RValue < R:RValue
          requires notBool isCompatibleRelationalTypes(utype(L), utype(R))
           andBool notBool (isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
          [structural]
     rule (.K => CV("CERL5", "Incompatible types in relational expression."))
          ~> L:RValue <= R:RValue
          requires notBool isCompatibleRelationalTypes(utype(L), utype(R))
           andBool notBool (isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
          [structural]
     rule (.K => CV("CERL5", "Incompatible types in relational expression."))
          ~> L:RValue > R:RValue
          requires notBool isCompatibleRelationalTypes(utype(L), utype(R))
           andBool notBool (isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
          [structural]
     rule (.K => CV("CERL5", "Incompatible types in relational expression."))
          ~> L:RValue >= R:RValue
          requires notBool isCompatibleRelationalTypes(utype(L), utype(R))
           andBool notBool (isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
          [structural]

     syntax Bool ::= isCompatibleRelationalTypes(UType, UType) [function]
     // real types
     // TODO(dwightguth): distinguish between real and complex types
     rule isCompatibleRelationalTypes(T1::UType, T2::UType) => true
          requires (isPromoted(T1) orBool isFloatUType(T1))
               andBool T1 ==Type T2
     // pointers to qualified or unqualified versions of compatible object types
     rule isCompatibleRelationalTypes(T1:PointerUType, T2:PointerUType) => true
          requires utype(innerType(T1)) ==Type utype(innerType(T2))
               andBool notBool isFunctionType(innerType(T1))
     rule isCompatibleRelationalTypes(_, _) => false [owise]

     /*@ \fromStandard{\source[n1570]{\para{6.5.9}{3--4}}}{
     The \cinline{==} (equal to) and \cinline{!=} (not equal to) operators are
     analogous to the relational operators except for their lower precedence.
     Each of the operators yields 1 if the specified relation is true and 0 if
     it is false. The result has type \cinline{int}. For any pair of operands,
     exactly one of the relations is true.

     If both of the operands have arithmetic type, the usual arithmetic
     conversions are performed. Values of complex types are equal if and only
     if both their real parts are equal and also their imaginary parts are
     equal. Any two values of arithmetic types from different type domains are
     equal if and only if the results of their conversions to the (complex)
     result type determined by the usual arithmetic conversions are equal.
     }*/

     rule tv(I1:Int, T::UType) == tv(I2:Int, T'::UType)
          => makeTruth(I1 ==K I2, T, T')
          requires (isPromoted(T) orBool isPointerType(T))
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T::UType) != tv(I2:Int, T'::UType)
          => makeTruth(I1 =/=K I2, T, T')
          requires (isPromoted(T) orBool isPointerType(T))
               andBool T ==Type T'
          [structural]

     rule tv(F1:Float, T::UType) == tv(F2:Float, T'::UType)
          => makeTruth(F1 ==Float F2, T, T')
          requires T ==Type T'
          [structural]
     rule tv(F1:Float, T::UType) != tv(F2:Float, T'::UType)
          => makeTruth(F1 =/=Float F2, T, T')
          requires T ==Type T'
          [structural]

     rule (.K => UNSPEC("CERL7", "Comparison of unspecified value."))
          ~> tv(V:CValue, T::UType) == tv(V':CValue, T'::UType)
          requires T ==Type T'
               andBool (isUnknown(V) orBool isUnknown(V'))
          [structural]
     rule (.K => UNSPEC("CERL7", "Comparison of unspecified value."))
          ~> tv(V:CValue, T::UType) != tv(V':CValue, T'::UType)
          requires T ==Type T'
               andBool (isUnknown(V) orBool isUnknown(V'))
          [structural]
     rule (.K => UNSPEC("CERL7", "Comparison of unspecified value."))
          ~> tv(V:CValue, T::UType) < tv(V':CValue, T'::UType)
          requires T ==Type T'
               andBool (isUnknown(V) orBool isUnknown(V'))
          [structural]
     rule (.K => UNSPEC("CERL7", "Comparison of unspecified value."))
          ~> tv(V:CValue, T::UType) <= tv(V':CValue, T'::UType)
          requires T ==Type T'
               andBool (isUnknown(V) orBool isUnknown(V'))
          [structural]
     rule (.K => UNSPEC("CERL7", "Comparison of unspecified value."))
          ~> tv(V:CValue, T::UType) > tv(V':CValue, T'::UType)
          requires T ==Type T'
               andBool (isUnknown(V) orBool isUnknown(V'))
          [structural]
     rule (.K => UNSPEC("CERL7", "Comparison of unspecified value."))
          ~> tv(V:CValue, T::UType) >= tv(V':CValue, T'::UType)
          requires T ==Type T'
               andBool (isUnknown(V) orBool isUnknown(V'))
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.9}{5--7}}}{
     Otherwise, at least one operand is a pointer. If one operand is a pointer
     and the other is a null pointer constant, the null pointer constant is
     converted to the type of the pointer. If one operand is a pointer to an
     object type and the other is a pointer to a qualified or unqualified
     version of \cinline{void}, the former is converted to the type of the
     latter.

     Two pointers compare equal if and only if both are null pointers, both are
     pointers to the same object (imports a pointer to an object and a
     subobject at its beginning) or function, both are pointers to one past the
     last element of the same array object, or one is a pointer to one past the
     end of one array object and the other is a pointer to the start of a
     different array object that happens to immediately follow the first array
     object in the address space.

     For the purposes of these operators, a pointer to an object that is not an
     element of an array behaves the same as a pointer to the first element of
     an array of length one with the type of the object as its element type.
     }*/
     // if one of the pointers is null, it's straightforward
     rule tv(V::CValue, T::UType) == tv(N:SymLoc, T'::UType)
          => makeTruth(NullPointer ==K N, T, T')
          requires notBool (isFunctionPointerType(type(T')) andBool isNullPointerConstant(tv(V, T)))
               andBool (isNullPointerConstant(tv(V, T)) orBool V ==K NullPointer)
          [structural]
     rule tv(V::CValue, T::UType) != tv(N:SymLoc, T'::UType)
          => makeTruth(NullPointer =/=K N, T, T')
          requires notBool (isFunctionPointerType(type(T')) andBool isNullPointerConstant(tv(V, T)))
               andBool (isNullPointerConstant(tv(V, T)) orBool V ==K NullPointer)
          [structural]
     rule tv(N:SymLoc, T::UType) == tv(V::CValue, T'::UType)
          => makeTruth(NullPointer ==K N, T, T')
          requires notBool (isFunctionPointerType(type(T)) andBool isNullPointerConstant(tv(V, T')))
               andBool (isNullPointerConstant(tv(V, T')) orBool V ==K NullPointer)
          [structural]
     rule tv(N:SymLoc, T::UType) != tv(V::CValue, T'::UType)
          => makeTruth(NullPointer =/=K N, T, T')
          requires notBool (isFunctionPointerType(type(T)) andBool isNullPointerConstant(tv(V, T')))
               andBool (isNullPointerConstant(tv(V, T')) orBool V ==K NullPointer)
          [structural]

     rule tv(V::CValue, T::UType) == tv(N:SymLoc, T'::UType)
          => lintNullFunPtrCompare ~> makeTruth(NullPointer ==K N, T, T')
          requires isFunctionPointerType(type(T'))
               andBool isNullPointerConstant(tv(V, T))
          [structural]
     rule tv(V::CValue, T::UType) != tv(N:SymLoc, T'::UType)
          => lintNullFunPtrCompare ~> makeTruth(NullPointer =/=K N, T, T')
          requires isFunctionPointerType(type(T'))
               andBool isNullPointerConstant(tv(V, T))
          [structural]
     rule tv(N:SymLoc, T::UType) == tv(V::CValue, T'::UType)
          => lintNullFunPtrCompare ~> makeTruth(NullPointer ==K N, T, T')
          requires isFunctionPointerType(type(T))
               andBool isNullPointerConstant(tv(V, T'))
          [structural]
     rule tv(N:SymLoc, T::UType) != tv(V::CValue, T'::UType)
          => lintNullFunPtrCompare ~> makeTruth(NullPointer =/=K N, T, T')
          requires isFunctionPointerType(type(T))
               andBool isNullPointerConstant(tv(V, T'))
          [structural]
     syntax KItem ::= "lintNullFunPtrCompare"
     rule lintNullFunPtrCompare => .K
          requires notBool hasLint
          [structural]

     rule tv(encodedPtr(Loc:SymLoc, N:Int, M:Int), T::UType) == tv(encodedPtr(Loc':SymLoc, N:Int, M:Int), T'::UType)
          => tv(Loc, T) == tv(Loc', T')
     rule tv(encodedPtr(Loc:SymLoc, N:Int, M:Int), T::UType) != tv(encodedPtr(Loc':SymLoc, N:Int, M:Int), T'::UType)
          => tv(Loc, T) != tv(Loc', T')
     rule tv(encodedPtr(Loc:SymLoc, N:Int, M:Int), T::UType) < tv(encodedPtr(Loc':SymLoc, N:Int, M:Int), T'::UType)
          => tv(Loc, T) < tv(Loc', T')
     rule tv(encodedPtr(Loc:SymLoc, N:Int, M:Int), T::UType) <= tv(encodedPtr(Loc':SymLoc, N:Int, M:Int), T'::UType)
          => tv(Loc, T) <= tv(Loc', T')
     rule tv(encodedPtr(Loc:SymLoc, N:Int, M:Int), T::UType) > tv(encodedPtr(Loc':SymLoc, N:Int, M:Int), T'::UType)
          => tv(Loc, T) > tv(Loc', T')
     rule tv(encodedPtr(Loc:SymLoc, N:Int, M:Int), T::UType) >= tv(encodedPtr(Loc':SymLoc, N:Int, M:Int), T'::UType)
          => tv(Loc, T) >= tv(Loc', T')

     rule tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T::UType) == tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv((L:SymLoc => unknown(maxIntPtrValue(L))), T::UType) == tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv(I:Int, T::UType) == tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))
     rule tv(I:Int, T::UType) == tv((L:SymLoc => unknown(maxIntPtrValue(L))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))

     rule tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T::UType) != tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv((L:SymLoc => unknown(maxIntPtrValue(L))), T::UType) != tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv(I:Int, T::UType) != tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))
     rule tv(I:Int, T::UType) != tv((L:SymLoc => unknown(maxIntPtrValue(L))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))

     rule tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T::UType) < tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv((L:SymLoc => unknown(maxIntPtrValue(L))), T::UType) < tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv(I:Int, T::UType) < tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))
     rule tv(I:Int, T::UType) < tv((L:SymLoc => unknown(maxIntPtrValue(L))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))

     rule tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T::UType) <= tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv((L:SymLoc => unknown(maxIntPtrValue(L))), T::UType) <= tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv(I:Int, T::UType) <= tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))
     rule tv(I:Int, T::UType) <= tv((L:SymLoc => unknown(maxIntPtrValue(L))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))

     rule tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T::UType) > tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv((L:SymLoc => unknown(maxIntPtrValue(L))), T::UType) > tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv(I:Int, T::UType) > tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))
     rule tv(I:Int, T::UType) > tv((L:SymLoc => unknown(maxIntPtrValue(L))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))

     rule tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T::UType) >= tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv((L:SymLoc => unknown(maxIntPtrValue(L))), T::UType) >= tv(I:Int, T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T'))
     rule tv(I:Int, T::UType) >= tv((encodedPtr(L:SymLoc, N::Int, M::Int) => unknown(maxIntPtrValue(encodedPtr(L, N, M)))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))
     rule tv(I:Int, T::UType) >= tv((L:SymLoc => unknown(maxIntPtrValue(L))), T'::UType)
          requires L =/=K NullPointer andBool notBool isNullPointerConstant(tv(I, T))

     rule tv((encodedPtr(NullPointer, _, _) => unknown(0)), _) == tv(_:Int, _)
     rule tv((encodedPtr(NullPointer, _, _) => unknown(0)), _) != tv(_:Int, _)
     rule tv((encodedPtr(NullPointer, _, _) => unknown(0)), _) < tv(_:Int, _)
     rule tv((encodedPtr(NullPointer, _, _) => unknown(0)), _) <= tv(_:Int, _)
     rule tv((encodedPtr(NullPointer, _, _) => unknown(0)), _) > tv(_:Int, _)
     rule tv((encodedPtr(NullPointer, _, _) => unknown(0)), _) >= tv(_:Int, _)
     rule tv(_:Int, _) == tv((encodedPtr(NullPointer, _, _) => unknown(0)), _)
     rule tv(_:Int, _) != tv((encodedPtr(NullPointer, _, _) => unknown(0)), _)
     rule tv(_:Int, _) < tv((encodedPtr(NullPointer, _, _) => unknown(0)), _)
     rule tv(_:Int, _) <= tv((encodedPtr(NullPointer, _, _) => unknown(0)), _)
     rule tv(_:Int, _) > tv((encodedPtr(NullPointer, _, _) => unknown(0)), _)
     rule tv(_:Int, _) >= tv((encodedPtr(NullPointer, _, _) => unknown(0)), _)

     // otherwise, there are a number of cases.
     // First, they are part of the same object
     rule tv(Loc:SymLoc, T::UType) == tv(Loc':SymLoc, T'::UType)
          => makeTruth(offset(Loc) ==K offset(Loc'), T, T')
          requires Loc  =/=K NullPointer
               andBool Loc' =/=K NullPointer
               andBool sameBase(Loc, Loc')
               andBool isCompatibleEqualityTypes(T, T', Loc, Loc')
          [structural]
     rule tv(Loc:SymLoc, T::UType) != tv(Loc':SymLoc, T'::UType)
          => makeTruth(offset(Loc) =/=K offset(Loc'), T, T')
          requires Loc  =/=K NullPointer
               andBool Loc' =/=K NullPointer
               andBool sameBase(Loc, Loc')
               andBool isCompatibleEqualityTypes(T, T', Loc, Loc')
          [structural]

     // next, they are part of different objects.
     rule tv(Loc:SymLoc, T::UType) == tv(Loc':SymLoc, T'::UType)
          => makeTruth(false, T, T')
          requires Loc  =/=K NullPointer
               andBool Loc' =/=K NullPointer
               andBool notBool sameBase(Loc, Loc')
               andBool notBool isAdjacent(stripProv(Loc), stripProv(Loc'), #configuration)
               andBool isCompatibleEqualityTypes(T, T', Loc, Loc')
          [structural]
     rule tv(Loc:SymLoc, T::UType) != tv(Loc':SymLoc, T'::UType)
          => makeTruth(true, T, T')
          requires Loc  =/=K NullPointer
               andBool Loc' =/=K NullPointer
               andBool notBool sameBase(Loc, Loc')
               andBool notBool isAdjacent(stripProv(Loc), stripProv(Loc'), #configuration)
               andBool isCompatibleEqualityTypes(T, T', Loc, Loc')
          [structural]

     rule tv(Loc:SymLoc, T::UType) == tv(Loc':SymLoc, T'::UType)
          => tv(unknown(1), makeTruthType(T, T'))
          requires isAdjacent(stripProv(Loc), stripProv(Loc'), #configuration)
               andBool isCompatibleEqualityTypes(T, T', Loc, Loc')
     rule tv(Loc:SymLoc, T::UType) != tv(Loc':SymLoc, T'::UType)
          => tv(unknown(0), makeTruthType(T, T'))
          requires isAdjacent(stripProv(Loc), stripProv(Loc'), #configuration)
               andBool isCompatibleEqualityTypes(T, T', Loc, Loc')

     // arithmetic types
     rule isCompatibleEqualityTypes(T1::UType, T2::UType, _, _) => true
          requires (isPromoted(T1) orBool isFloatUType(T1))
               andBool T1 ==Type T2
     // pointers to qualified or unqualified versions of compatible types
     rule isCompatibleEqualityTypes(T1:PointerUType, T2:PointerUType, _, _) => true
          requires utype(innerType(T1)) ==Type utype(innerType(T2))
     // pointer to object and pointer to void
     rule isCompatibleEqualityTypes(T1:PointerUType, T2:PointerUType, _, _) => true
          requires (notBool isFunctionType(innerType(T1)) andBool isVoidType(innerType(T2)))
               orBool (notBool isFunctionType(innerType(T2)) andBool isVoidType(innerType(T1)))
     // null pointer
     rule isCompatibleEqualityTypes(_:PointerUType, _, _, NullPointer) => true
     rule isCompatibleEqualityTypes(_, _:PointerUType, NullPointer, _) => true
     rule isCompatibleEqualityTypes(_, _, _, _) => false [owise]

     // we check also that they aren't both arithmetic types because arithmetic types must be promoted
     // so it's not technically a constraint violation if the types don't match.
     rule (.K => CV("CERL8", "Invalid operand types to ==."))
          ~> L:RValue == R:RValue
          requires notBool isCompatibleEqualityTypes(utype(L), utype(R), value(L), value(R))
               andBool notBool (isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
               andBool notBool (isPointerType(type(L)) andBool isNullPointerConstant(R))
               andBool notBool (isPointerType(type(R)) andBool isNullPointerConstant(L))
     rule (.K => CV("CERL9", "Invalid operand types to !=."))
          ~> L:RValue != R:RValue
          requires notBool isCompatibleEqualityTypes(utype(L), utype(R), value(L), value(R))
               andBool notBool (isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
               andBool notBool (isPointerType(type(L)) andBool isNullPointerConstant(R))
               andBool notBool (isPointerType(type(R)) andBool isNullPointerConstant(L))

     syntax Bool ::= isAdjacent(SymLoc, SymLoc, K) [function]
     rule isAdjacent(loc(S::SymBase, Size:Int), loc(_, 0), <generatedTop>... <mem>... S |-> object(_, Size, _) ...</mem> ...</generatedTop>)
          => true
     rule isAdjacent(loc(_, 0), loc(S::SymBase, Size:Int), <generatedTop>... <mem>... S |-> object(_, Size, _) ...</mem> ...</generatedTop>)
          => true
     rule isAdjacent(_, _, _) => false [owise]
endmodule
