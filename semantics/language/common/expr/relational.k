module C-COMMON-EXPR-RELATIONAL
     imports C-BITS-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     syntax KItem ::= makeTruth(Bool, Type, Type) [function]
     rule makeTruth(B:Bool, T:Type, T':Type)
          => #if B #then tv(1, t(.Set, int)) #else tv(0, t(.Set, int)) #fi
          requires notBool fromConstantExpr(T) orBool notBool fromConstantExpr(T')
     rule makeTruth(B:Bool, T:Type, T':Type)
          => #if B #then tv(1, t(SetItem(IntegerConstant), int)) #else tv(0, t(SetItem(IntegerConstant), int)) #fi
          requires fromConstantExpr(T) andBool fromConstantExpr(T')

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

     rule tv(I1:Int, T:Type) < tv(I2:Int, T':Type)
          => makeTruth(I1 <Int I2, T, T')
          requires isPromoted(T) orBool isPointerType(T)
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T:Type) <= tv(I2:Int, T':Type)
          => makeTruth(I1 <=Int I2, T, T')
          requires isPromoted(T) orBool isPointerType(T)
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T:Type) > tv(I2:Int, T':Type)
          => makeTruth(I1 >Int I2, T, T')
          requires isPromoted(T) orBool isPointerType(T)
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T:Type) >= tv(I2:Int, T':Type)
          => makeTruth(I1 >=Int I2, T, T')
          requires isPromoted(T) orBool isPointerType(T)
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) < tv(F2:Float, T':Type)
          => makeTruth(F1 <Float F2, T, T')
          requires T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) <= tv(F2:Float, T':Type)
          => makeTruth(F1 <=Float F2, T, T')
          requires T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) > tv(F2:Float, T':Type)
          => makeTruth(F1 >Float F2, T, T')
          requires T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) >= tv(F2:Float, T':Type)
          => makeTruth(F1 >=Float F2, T, T')
          requires T ==Type T'
          [structural]

     //- comparison of pointers
     rule tv(Loc:SymLoc, T:PointerType) < tv(Loc':SymLoc, T':PointerType)
          => makeTruth(offset(Loc) <Int offset(Loc'), T, T')
          requires sameBase(Loc, Loc')
          [structural]
     rule (.K => UNDEF("CERL1", "Cannot compare pointers with different base objects using '<'.", "6.5.8:5, J.2:1 item 53") )
          ~> tv(Loc:SymLoc, T:Type) < tv(Loc':SymLoc, T':Type)
          requires notBool sameBase(Loc, Loc')
               andBool T ==Type T'
          [structural]
     rule _:ErrorExit ~> tv(Loc:SymLoc, T:Type) < tv(Loc':SymLoc, T':Type)
          => tv(unknown, t(.Set, int))
          requires notBool sameBase(Loc, Loc')
               andBool T ==Type T'
               andBool isErrorRecovery
     rule tv(Loc:SymLoc, T:PointerType) <= tv(Loc':SymLoc, T':PointerType)
          => makeTruth(offset(Loc) <=Int offset(Loc'), T, T')
          requires sameBase(Loc, Loc')
          [structural]
     rule (.K => UNDEF("CERL2", "Cannot compare pointers with different base objects using '<='.", "6.5.8:5, J.2:1 item 53") )
          ~> tv(Loc:SymLoc, T:Type) <= tv(Loc':SymLoc, T':Type)
          requires notBool sameBase(Loc, Loc')
               andBool T ==Type T'
          [structural]
     rule _:ErrorExit ~> tv(Loc:SymLoc, T:Type) <= tv(Loc':SymLoc, T':Type)
          => tv(unknown, t(.Set, int))
          requires notBool sameBase(Loc, Loc')
               andBool T ==Type T'
               andBool isErrorRecovery
     rule tv(Loc:SymLoc, T:PointerType) > tv(Loc':SymLoc, T':PointerType)
          => makeTruth(offset(Loc) >Int offset(Loc'), T, T')
          requires sameBase(Loc, Loc')
          [structural]
     rule (.K => UNDEF("CERL3", "Cannot compare pointers with different base objects using '>'.", "6.5.8:5, J.2:1 item 53") )
          ~> tv(Loc:SymLoc, T:Type) > tv(Loc':SymLoc, T':Type)
          requires notBool sameBase(Loc, Loc')
               andBool (T ==Type T')
          [structural]
     rule _:ErrorExit ~> tv(Loc:SymLoc, T:Type) > tv(Loc':SymLoc, T':Type)
          => tv(unknown, t(.Set, int))
          requires notBool sameBase(Loc, Loc')
               andBool T ==Type T'
               andBool isErrorRecovery
     rule tv(Loc:SymLoc, T:PointerType) >= tv(Loc':SymLoc, T':PointerType)
          => makeTruth(offset(Loc) >=Int offset(Loc'), T, T')
          requires sameBase(Loc, Loc')
          [structural]
     rule (.K => UNDEF("CERL4", "Cannot compare pointers with different base objects using '>='.", "6.5.8:5, J.2:1 item 53") )
          ~> tv(Loc:SymLoc, T:Type) >= tv(Loc':SymLoc, T':Type)
          requires notBool sameBase(Loc, Loc')
               andBool (T ==Type T')
          [structural]
     rule _:ErrorExit ~> tv(Loc:SymLoc, T:Type) >= tv(Loc':SymLoc, T':Type)
          => tv(unknown, t(.Set, int))
          requires notBool sameBase(Loc, Loc')
               andBool T ==Type T'
               andBool isErrorRecovery

     rule (.K => CV("CERL5", "Directly comparing an integer type with a pointer type.", "6.5.8:2") )
          ~> tv(_, T:Type) < tv(_, T':Type)
          requires (isIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool isIntegerType(T'))
          [structural]
     rule (.K => CV("CERL5", "Directly comparing an integer type with a pointer type.", "6.5.8:2") )
          ~> tv(_, T:Type) <= tv(_, T':Type)
          requires (isIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool isIntegerType(T'))
          [structural]
     rule (.K => CV("CERL5", "Directly comparing an integer type with a pointer type.", "6.5.8:2") )
          ~> tv(_, T:Type) > tv(_, T':Type)
          requires (isIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool isIntegerType(T'))
          [structural]
     rule (.K => CV("CERL5", "Directly comparing an integer type with a pointer type.", "6.5.8:2") )
          ~> tv(_, T:Type) >= tv(_, T':Type)
          requires (isIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool isIntegerType(T'))
          [structural]

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

     rule tv(I1:Int, T:Type) == tv(I2:Int, T':Type)
          => makeTruth(I1 ==K I2, T, T')
          requires (isPromoted(T) orBool isPointerType(T))
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T:Type) != tv(I2:Int, T':Type)
          => makeTruth(I1 =/=K I2, T, T')
          requires (isPromoted(T) orBool isPointerType(T))
               andBool T ==Type T'
          [structural]

     rule tv(F1:Float, T:Type) == tv(F2:Float, T':Type)
          => makeTruth(F1 ==Float F2, T, T')
          requires T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) != tv(F2:Float, T':Type)
          => makeTruth(F1 =/=Float F2, T, T')
          requires T ==Type T'
          [structural]

     rule tv(V:CValue, T:Type) == tv(V':CValue, T':Type)
          => makeTruth(false, T, T')
          requires T ==Type T'
               andBool (V ==K unknown orBool V' ==K unknown)
          [structural]
     rule tv(V:CValue, T:Type) != tv(V':CValue, T':Type)
          => makeTruth(true, T, T')
          requires T ==Type T'
               andBool (V ==K unknown orBool V' ==K unknown)
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
     rule tv(NullPointer, T:PointerType) == tv(N:SymLoc, T':PointerType)
          => makeTruth(NullPointer ==K N, T, T')
          [structural]
     rule tv(NullPointer, T:PointerType) != tv(N:SymLoc, T':PointerType)
          => makeTruth(NullPointer =/=K N, T, T')
          [structural]
     rule tv(N:SymLoc, T:PointerType) == tv(NullPointer, T':PointerType)
          => makeTruth(NullPointer ==K N, T, T')
          [structural]
     rule tv(N:SymLoc, T:PointerType) != tv(NullPointer, T':PointerType)
          => makeTruth(NullPointer =/=K N, T, T')
          [structural]

     // otherwise, there are a number of cases.
     // First, they are part of the same object
     rule tv(Loc:SymLoc, T:PointerType) == tv(Loc':SymLoc, T':PointerType)
          => makeTruth(offset(Loc) ==K offset(Loc'), T, T')
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool sameBase(Loc, Loc')
          [structural]
     rule tv(Loc:SymLoc, T:PointerType) != tv(Loc':SymLoc, T':PointerType)
          => makeTruth(offset(Loc) =/=K offset(Loc'), T, T')
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool sameBase(Loc, Loc')
          [structural]

     // next, they are part of different objects.
     rule tv(Loc:SymLoc, T:PointerType) == tv(Loc':SymLoc, T':PointerType)
          => makeTruth(false, T, T')
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool notBool sameBase(Loc, Loc')
          [structural]
     rule tv(Loc:SymLoc, T:PointerType) != tv(Loc':SymLoc, T':PointerType)
          => makeTruth(true, T, T')
          requires Loc  =/=K NullPointer
           andBool Loc' =/=K NullPointer
           andBool notBool sameBase(Loc, Loc')
          [structural]

endmodule
