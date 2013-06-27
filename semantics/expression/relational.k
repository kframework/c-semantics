module C-EXPRESSION-RELATIONAL
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
          
     rule tv(I1:Int, T:KResult) < tv(I2:Int, T:KResult)
          => makeTruth(I1:Int <Int I2:Int)
          when isPromoted(T:KResult) orBool isPointerType(T:KResult)
          [structural]
     rule tv(I1:Int, T:KResult) <= tv(I2:Int, T:KResult)
          => makeTruth(I1:Int <=Int I2:Int)
          when isPromoted(T:KResult) orBool isPointerType(T:KResult)
          [structural]
     rule tv(I1:Int, T:KResult) > tv(I2:Int, T:KResult)
          => makeTruth(I1:Int >Int I2:Int)
          when isPromoted(T:KResult) orBool isPointerType(T:KResult)
          [structural]
     rule tv(I1:Int, T:KResult) >= tv(I2:Int, T:KResult)
          => makeTruth(I1:Int >=Int I2:Int)
          when isPromoted(T:KResult) orBool isPointerType(T:KResult)
          [structural]
     rule tv(F1:Float, T:KResult) < tv(F2:Float, T:KResult)
          => makeTruth(F1:Float <Float F2:Float)
          [structural]
     rule tv(F1:Float, T:KResult) <= tv(F2:Float, T:KResult)
          => makeTruth(F1:Float <=Float F2:Float)
          [structural]
     rule tv(F1:Float, T:KResult) > tv(F2:Float, T:KResult)
          => makeTruth(F1:Float >Float F2:Float)
          [structural]
     rule tv(F1:Float, T:KResult) >= tv(F2:Float, T:KResult)
          => makeTruth(F1:Float >=Float F2:Float)
          [structural]
     
     //- comparison of pointers
     // fixme could check 6.5.8:2
     // fixme there are further restrictions on pointers
     rule [ptr-compare-lt]: 
          tv(loc(Base:SymBase, Offset:Int, 0), T:KResult)
               < tv(loc(Base:SymBase, Offset':Int, 0), T':KResult)
          => makeTruth(Offset:Int <Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
     rule [ptr-compare-lte]: 
          tv(loc(Base:SymBase, Offset:Int, 0), T:KResult)
               <= tv(loc(Base:SymBase, Offset':Int, 0), T':KResult)
          => makeTruth(Offset:Int <=Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
     rule [ptr-compare-gt]: 
          tv(loc(Base:SymBase, Offset:Int, 0), T:KResult)
               > tv(loc(Base:SymBase, Offset':Int, 0), T':KResult)
          => makeTruth(Offset:Int >Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
     rule [ptr-compare-gte]: 
          tv(loc(Base:SymBase, Offset:Int, 0), T:KResult)
               >= tv(loc(Base:SymBase, Offset':Int, 0), T':KResult)
          => makeTruth(Offset:Int >=Int Offset':Int)
          when isPointerType(T:KResult) andBool isPointerType(T':KResult)
          [structural]
endmodule


