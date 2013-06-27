module C-EXPRESSION-EQUALITY
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
     
     rule tv(I1:Int, T:KResult) == tv(I2:Int, T:KResult)
          => makeTruth(I1 ==K I2)
          when isPromoted(T:KResult) 
               orBool isPointerType(T:KResult)
          [structural]
     rule tv(I1:Int, T:KResult) != tv(I2:Int, T:KResult)
          => makeTruth(I1 =/=K I2)
          when isPromoted(T:KResult) 
               orBool isPointerType(T:KResult)
          [structural]
          
     rule tv(F1:Float, T:KResult) == tv(F2:Float, T:KResult) 
          => makeTruth(F1 ==Float F2)
          [structural]
     rule tv(F1:Float, T:KResult) != tv(F2:Float, T:KResult) 
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
     rule tv(N:SymLoc, T:KResult) == tv(N:SymLoc, T':KResult)
          => tv(1, t(.Set, int))
          when isPointerType(T:KResult) 
               andBool isPointerType(T':KResult)
          [structural]
     rule tv(N:SymLoc, T:KResult) != tv(N:SymLoc, T':KResult)
          => tv(0, t(.Set, int))
          when isPointerType(T:KResult) 
               andBool isPointerType(T':KResult)
          [structural]
     
     // if one of the pointers is null, it's also straightforward
     rule tv(NullPointer, T:KResult) == tv(N:SymLoc, T':KResult)
          => makeTruth(NullPointer ==K N)
          when isPointerType(T:KResult) 
               andBool isPointerType(T':KResult)
          [structural]
     rule tv(NullPointer, T:KResult) != tv(N:SymLoc, T':KResult)
          => makeTruth(NullPointer =/=K N)
          when isPointerType(T:KResult) 
               andBool isPointerType(T':KResult)
          [structural]
     rule tv(N:SymLoc, T:KResult) == tv(NullPointer, T':KResult)
          => makeTruth(NullPointer ==K N)
          when isPointerType(T:KResult) 
               andBool isPointerType(T':KResult)
          [structural]
     rule tv(N:SymLoc, T:KResult) != tv(NullPointer, T':KResult)
          => makeTruth(NullPointer =/=K N)
          when isPointerType(T:KResult) 
               andBool isPointerType(T':KResult)
          [structural]
          
     // otherwise, there are a number of cases.  
     // First, they are part of the same object        
     rule tv(loc(Base:SymBase, Offset:Int, 0), T:KResult)
               == tv(loc(Base:SymBase, Offset':Int, 0), T':KResult) 
          => makeTruth(Offset:Int ==Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
     rule tv(loc(Base:SymBase, Offset:Int, 0), T:KResult)
               != tv(loc(Base:SymBase, Offset':Int, 0), T':KResult) 
          => makeTruth(Offset:Int =/=Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
          
     // next, they are part of different objects.  
     // here, if the two objects are alive, and our pointers are in bounds, we
     // can conclude something.  if one of the objects is dead, we can't
     // conclude anything (the address could have been reused)
     rule [compare-eq-different-objects]: 
          <k> 
               tv(loc(Base:SymBase, Offset:Int, 0), T:KResult)
                    == tv(loc(Base':SymBase, Offset':Int, 0), T':KResult) 
               => tv(0, t(.Set, int))
          ...</k>
          <mem> ...
               Base |-> memblock(Len:Int, _, _)
               Base' |-> memblock(Len':Int, _, _)
          ...</mem>
          when (isPointerType(T:KResult) andBool isPointerType(T':KResult))
               andBool (Base =/=K Base')
               andBool (Offset:Int <Int Len:Int)
               andBool (Offset':Int <Int Len':Int)
          [structural]
     rule [compare-neq-different-objects]: 
          <k> 
               tv(loc(Base:SymBase, Offset:Int, 0), T:KResult)
                    != tv(loc(Base':SymBase, Offset':Int, 0), T':KResult) 
               => tv(1, t(.Set, int))
          ...</k>
          <mem> ...
               Base |-> memblock(Len:Int, _, _)
               Base' |-> memblock(Len':Int, _, _)
          ...</mem>
          when (isPointerType(T:KResult) andBool isPointerType(T':KResult))
               andBool (Base =/=K Base')
               andBool (Offset:Int <Int Len:Int)
               andBool (Offset':Int <Int Len':Int)
          [structural]
     
     // otherwise we can't conclude anything
          
     //- comparison of ints with pointers
     // fixme there are further restrictions on pointers
     rule [equal-null-left]:
          (tv(N:Int, T:KResult)
          => tv(NullPointer, T':KResult)) == tv(_, T':KResult)
          when isPromoted(T:KResult)
               andBool isPointerType(T':KResult)
               andBool (N ==K NullPointerConstant)
          [structural]
     rule [equal-null-right]:
          tv(_, T:KResult) == (tv(N:Int, T':KResult)
          => tv(NullPointer, T:KResult))
          when isPointerType(T:KResult) 
               andBool isPromoted(T':KResult)
               andBool N ==K NullPointerConstant
          [structural]
     
     rule [nequal-null-left]: 
          (tv(N:Int, T:KResult)
          => tv(NullPointer, T':KResult)) != tv(_, T':KResult)
          when isPromoted(T:KResult) 
               andBool isPointerType(T':KResult)
               andBool N ==K NullPointerConstant
          [structural]
     rule [nequal-null-right]: 
          tv(_, T:KResult) != (tv(N:Int, T':KResult)
          => tv(NullPointer, T:KResult))
          when isPointerType(T:KResult) 
               andBool isPromoted(T':KResult)
               andBool N ==K NullPointerConstant
          [structural]
endmodule

