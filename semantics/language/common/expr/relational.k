module C-COMMON-EXPR-RELATIONAL
     imports C-BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     syntax K ::= makeTruth(Bool) [function]
     rule makeTruth(B:Bool)
          => #if B #then tv(1, t(.Set, int)) #else tv(0, t(.Set, int)) #fi

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
          => makeTruth(I1 <Int I2)
          when isPromoted(T) orBool isPointerType(T)
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T:Type) <= tv(I2:Int, T':Type)
          => makeTruth(I1 <=Int I2)
          when isPromoted(T) orBool isPointerType(T)
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T:Type) > tv(I2:Int, T':Type)
          => makeTruth(I1 >Int I2)
          when isPromoted(T) orBool isPointerType(T)
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T:Type) >= tv(I2:Int, T':Type)
          => makeTruth(I1 >=Int I2)
          when isPromoted(T) orBool isPointerType(T)
               andBool T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) < tv(F2:Float, T':Type)
          => makeTruth(F1 <Float F2)
          when T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) <= tv(F2:Float, T':Type)
          => makeTruth(F1 <=Float F2)
          when T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) > tv(F2:Float, T':Type)
          => makeTruth(F1 >Float F2)
          when T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) >= tv(F2:Float, T':Type)
          => makeTruth(F1 >=Float F2)
          when T ==Type T'
          [structural]

     //- comparison of pointers
     rule tv(Loc:SymLoc, T:Type) < tv(Loc':SymLoc, T':Type)
          => makeTruth(offset(Loc) <Int offset(Loc'))
          when isPointerType(T) andBool isPointerType(T')
               andBool base(Loc) ==K base(Loc')
          [structural]
     rule (. => UNDEF("CER1", "Cannot compare pointers with different base objects using '<'.", "6.5.8:5") )
          ~> tv(Loc:SymLoc, T:Type) < tv(Loc':SymLoc, T':Type)
          when base(Loc) =/=K base(Loc')
               andBool T ==Type T'
          [structural]
     rule tv(Loc:SymLoc, T:Type) <= tv(Loc':SymLoc, T':Type)
          => makeTruth(offset(Loc) <=Int offset(Loc'))
          when isPointerType(T) andBool isPointerType(T')
               andBool base(Loc) ==K base(Loc')
          [structural]
     rule (. => UNDEF("CER2", "Cannot compare pointers with different base objects using '<='.", "6.5.8:5") )
          ~> tv(Loc:SymLoc, T:Type) <= tv(Loc':SymLoc, T':Type)
          when base(Loc) =/=K base(Loc')
               andBool T ==Type T'
          [structural]
     rule tv(Loc:SymLoc, T:Type) > tv(Loc':SymLoc, T':Type)
          => makeTruth(offset(Loc) >Int offset(Loc'))
          when isPointerType(T) andBool isPointerType(T')
               andBool (base(Loc) ==K base(Loc'))
          [structural]
     rule (. => UNDEF("CER3", "Cannot compare pointers with different base objects using '>'.", "6.5.8:5") )
          ~> tv(Loc:SymLoc, T:Type) > tv(Loc':SymLoc, T':Type)
          when (base(Loc) =/=K base(Loc'))
               andBool (T ==Type T')
          [structural]
     rule tv(Loc:SymLoc, T:Type) >= tv(Loc':SymLoc, T':Type)
          => makeTruth(offset(Loc) >=Int offset(Loc'))
          when isPointerType(T) andBool isPointerType(T')
               andBool (base(Loc) ==K base(Loc'))
          [structural]
     rule (. => UNDEF("CER4", "Cannot compare pointers with different base objects using '>='.", "6.5.8:5") )
          ~> tv(Loc:SymLoc, T:Type) >= tv(Loc':SymLoc, T':Type)
          when (base(Loc) =/=K base(Loc'))
               andBool (T ==Type T')
          [structural]

     rule (. => CV("CER5", "Directly comparing an integer type with a pointer type.", "6.5.8:2") )
          ~> tv(_, T:Type) < tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural]
     rule (. => CV("CER6", "Directly comparing an integer type with a pointer type.", "6.5.8:2") )
          ~> tv(_, T:Type) <= tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural] 
     rule (. => CV("CER7", "Directly comparing an integer type with a pointer type.", "6.5.8:2") )
          ~> tv(_, T:Type) > tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural] 
     rule (. => CV("CER8", "Directly comparing an integer type with a pointer type.", "6.5.8:2") )
          ~> tv(_, T:Type) >= tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
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
          => makeTruth(I1 ==K I2)
          when (isPromoted(T) orBool isPointerType(T))
               andBool T ==Type T'
          [structural]
     rule tv(I1:Int, T:Type) != tv(I2:Int, T':Type)
          => makeTruth(I1 =/=K I2)
          when (isPromoted(T) orBool isPointerType(T))
               andBool T ==Type T'
          [structural]

     rule tv(F1:Float, T:Type) == tv(F2:Float, T':Type) 
          => makeTruth(F1 ==Float F2)
          when T ==Type T'
          [structural]
     rule tv(F1:Float, T:Type) != tv(F2:Float, T':Type) 
          => makeTruth(F1 =/=Float F2)
          when T ==Type T'
          [structural]

     rule tv(V:CValue, T:Type) == tv(V':CValue, T':Type) 
          => makeTruth(false)
          when T ==Type T'
               andBool (V ==K unknown orBool V' ==K unknown)
          [structural]
     rule tv(V:CValue, T:Type) != tv(V':CValue, T':Type) 
          => makeTruth(true)
          when T ==Type T'
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
     // if they're identical, we know for sure they are the same
     rule tv(N:SymLoc, T:Type) == tv(N:SymLoc, T':Type)
          => tv(1, t(.Set, int))
          when isPointerType(T) 
               andBool isPointerType(T')
          [structural]
     rule tv(N:SymLoc, T:Type) != tv(N:SymLoc, T':Type)
          => tv(0, t(.Set, int))
          when isPointerType(T) 
               andBool isPointerType(T')
          [structural]

     // if one of the pointers is null, it's also straightforward
     rule tv(NullPointer, T:Type) == tv(N:SymLoc, T':Type)
          => makeTruth(NullPointer ==K N)
          when isPointerType(T) 
               andBool isPointerType(T')
          [structural]
     rule tv(NullPointer, T:Type) != tv(N:SymLoc, T':Type)
          => makeTruth(NullPointer =/=K N)
          when isPointerType(T) 
               andBool isPointerType(T')
          [structural]
     rule tv(N:SymLoc, T:Type) == tv(NullPointer, T':Type)
          => makeTruth(NullPointer ==K N)
          when isPointerType(T) 
               andBool isPointerType(T')
          [structural]
     rule tv(N:SymLoc, T:Type) != tv(NullPointer, T':Type)
          => makeTruth(NullPointer =/=K N)
          when isPointerType(T) 
               andBool isPointerType(T')
          [structural]

     // otherwise, there are a number of cases.
     // First, they are part of the same object
     rule tv(Loc:SymLoc, T:Type) == tv(Loc':SymLoc, T':Type) 
          => makeTruth(offset(Loc) ==Int offset(Loc'))
          when isPointerType(T) andBool isPointerType(T')
               andBool (base(Loc) ==K base(Loc'))
          [structural]
     rule tv(Loc:SymLoc, T:Type) != tv(Loc':SymLoc, T':Type) 
          => makeTruth(offset(Loc) =/=Int offset(Loc'))
          when isPointerType(T) andBool isPointerType(T')
               andBool (base(Loc) ==K base(Loc'))
          [structural]

     // next, they are part of different objects.
     rule tv(Loc:SymLoc, T:Type) == tv(Loc':SymLoc, T':Type) 
          => tv(0, t(.Set, int))
          when (isPointerType(T) andBool isPointerType(T'))
               andBool (base(Loc) =/=K base(Loc'))
          [structural]
     rule tv(Loc:SymLoc, T:Type) != tv(Loc':SymLoc, T':Type) 
          => tv(1, t(.Set, int))
          when isPointerType(T) andBool isPointerType(T')
               andBool (base(Loc) =/=K base(Loc'))
          [structural]

     //- comparison of ints with pointers
     // fixme there are further restrictions on pointers
     rule (tv(N:Int, T:Type) => tv(NullPointer, T')) == tv(_, T':Type)
          when isPromoted(T)
               andBool isPointerType(T')
               andBool isNullPointerConstant(tv(N, T))
          [structural]
     rule tv(_, T:Type) == (tv(N:Int, T':Type) => tv(NullPointer, T))
          when isPointerType(T) 
               andBool isPromoted(T')
               andBool isNullPointerConstant(tv(N, T'))
          [structural]

     rule (tv(N:Int, T:Type) => tv(NullPointer, T')) != tv(_, T':Type)
          when isPromoted(T) 
               andBool isPointerType(T')
               andBool isNullPointerConstant(tv(N, T))
          [structural]
     rule tv(_, T:Type) != (tv(N:Int, T':Type) => tv(NullPointer, T))
          when isPointerType(T) 
               andBool isPromoted(T')
               andBool isNullPointerConstant(tv(N, T'))
          [structural]
endmodule
