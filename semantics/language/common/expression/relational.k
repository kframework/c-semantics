module C-COMMON-EXPRESSION-RELATIONAL
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

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
          
     rule tv(I1:Int, T:Type) < tv(I2:Int, T:Type)
          => makeTruth(I1 <Int I2)
          when isPromoted(T) orBool isPointerType(T)
          [structural]
     rule tv(I1:Int, T:Type) <= tv(I2:Int, T:Type)
          => makeTruth(I1 <=Int I2)
          when isPromoted(T:Type) orBool isPointerType(T:Type)
          [structural]
     rule tv(I1:Int, T:Type) > tv(I2:Int, T:Type)
          => makeTruth(I1 >Int I2)
          when isPromoted(T:Type) orBool isPointerType(T:Type)
          [structural]
     rule tv(I1:Int, T:Type) >= tv(I2:Int, T:Type)
          => makeTruth(I1 >=Int I2)
          when isPromoted(T:Type) orBool isPointerType(T:Type)
          [structural]
     rule tv(F1:Float, T:Type) < tv(F2:Float, T:Type)
          => makeTruth(F1 <Float F2)
          [structural]
     rule tv(F1:Float, T:Type) <= tv(F2:Float, T:Type)
          => makeTruth(F1 <=Float F2)
          [structural]
     rule tv(F1:Float, T:Type) > tv(F2:Float, T:Type)
          => makeTruth(F1 >Float F2)
          [structural]
     rule tv(F1:Float, T:Type) >= tv(F2:Float, T:Type)
          => makeTruth(F1 >=Float F2)
          [structural]
     
     //- comparison of pointers
     // fixme could check 6.5.8:2
     // fixme there are further restrictions on pointers
     rule [ptr-compare-lt]: 
          tv(loc(Base:SymBase, Offset:Int, 0), T:Type)
               < tv(loc(Base:SymBase, Offset':Int, 0), T':Type)
          => makeTruth(Offset <Int Offset')
          when isPointerType(T) andBool isPointerType(T')
          [structural]
     rule [ptr-compare-lte]: 
          tv(loc(Base:SymBase, Offset:Int, 0), T:Type)
               <= tv(loc(Base:SymBase, Offset':Int, 0), T':Type)
          => makeTruth(Offset <=Int Offset')
          when isPointerType(T) andBool isPointerType(T')
          [structural]
     rule [ptr-compare-gt]: 
          tv(loc(Base:SymBase, Offset:Int, 0), T:Type)
               > tv(loc(Base:SymBase, Offset':Int, 0), T':Type)
          => makeTruth(Offset >Int Offset')
          when isPointerType(T) andBool isPointerType(T')
          [structural]
     rule [ptr-compare-gte]: 
          tv(loc(Base:SymBase, Offset:Int, 0), T:Type)
               >= tv(loc(Base:SymBase, Offset':Int, 0), T':Type)
          => makeTruth(Offset >=Int Offset')
          when isPointerType(T) andBool isPointerType(T')
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
     
     rule tv(I1:Int, T:Type) == tv(I2:Int, T:Type)
          => makeTruth(I1 ==K I2)
          when isPromoted(T) 
               orBool isPointerType(T)
          [structural]
     rule tv(I1:Int, T:Type) != tv(I2:Int, T:Type)
          => makeTruth(I1 =/=K I2)
          when isPromoted(T) 
               orBool isPointerType(T)
          [structural]
          
     rule tv(F1:Float, T:Type) == tv(F2:Float, T:Type) 
          => makeTruth(F1 ==Float F2)
          [structural]
     rule tv(F1:Float, T:Type) != tv(F2:Float, T:Type) 
          => makeTruth(F1 =/=Float F2)
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
     rule tv(loc(Base:SymBase, Offset:Int, 0), T:Type)
               == tv(loc(Base:SymBase, Offset':Int, 0), T':Type) 
          => makeTruth(Offset ==Int Offset')
          when isPointerType(T) andBool isPointerType(T')
          [structural]
     rule tv(loc(Base:SymBase, Offset:Int, 0), T:Type)
               != tv(loc(Base:SymBase, Offset':Int, 0), T':Type) 
          => makeTruth(Offset =/=Int Offset')
          when isPointerType(T) andBool isPointerType(T')
          [structural]
          
     // next, they are part of different objects.  
     // here, if the two objects are alive, and our pointers are in bounds, we
     // can conclude something.  if one of the objects is dead, we can't
     // conclude anything (the address could have been reused)
     rule [compare-eq-different-objects]: 
          <k> 
               tv(loc(Base:SymBase, Offset:Int, 0), T:Type)
                    == tv(loc(Base':SymBase, Offset':Int, 0), T':Type) 
               => tv(0, t(.Set, int))
          ...</k>
          <mem> ...
               Base |-> memblock(Len:Int, _, _)
               Base' |-> memblock(Len':Int, _, _)
          ...</mem>
          when (isPointerType(T) andBool isPointerType(T'))
               andBool (Base =/=K Base')
               andBool (Offset <Int Len)
               andBool (Offset' <Int Len')
          [structural]
     rule [compare-neq-different-objects]: 
          <k> 
               tv(loc(Base:SymBase, Offset:Int, 0), T:Type)
                    != tv(loc(Base':SymBase, Offset':Int, 0), T':Type) 
               => tv(1, t(.Set, int))
          ...</k>
          <mem> ...
               Base |-> memblock(Len:Int, _, _)
               Base' |-> memblock(Len':Int, _, _)
          ...</mem>
          when isPointerType(T) andBool isPointerType(T')
               andBool (Base =/=K Base')
               andBool (Offset <Int Len)
               andBool (Offset' <Int Len')
          [structural]
     
     // otherwise we can't conclude anything
          
     //- comparison of ints with pointers
     // fixme there are further restrictions on pointers
     rule [equal-null-left]:
          (tv(N:Int, T:Type) => tv(NullPointer, T')) == tv(_, T':Type)
          when isPromoted(T)
               andBool isPointerType(T')
               andBool (N ==K NullPointerConstant)
          [structural]
     rule [equal-null-right]:
          tv(_, T:Type) == (tv(N:Int, T':Type) => tv(NullPointer, T))
          when isPointerType(T) 
               andBool isPromoted(T')
               andBool N ==K NullPointerConstant
          [structural]
     
     rule [nequal-null-left]: 
          (tv(N:Int, T:Type) => tv(NullPointer, T')) != tv(_, T':Type)
          when isPromoted(T) 
               andBool isPointerType(T')
               andBool N ==K NullPointerConstant
          [structural]
     rule [nequal-null-right]: 
          tv(_, T:Type) != (tv(N:Int, T':Type) => tv(NullPointer, T))
          when isPointerType(T) 
               andBool isPromoted(T')
               andBool N ==K NullPointerConstant
          [structural]
endmodule


