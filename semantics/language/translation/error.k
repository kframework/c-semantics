module C-TRANSLATION-ERROR
     imports C-ERROR-SYNTAX
     imports C-ERROR-MAP-SYNTAX
     imports C-CONSTRAINT-MAP-SYNTAX

     imports C-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX

     imports C-COMMON-EXPR-EVAL-SYNTAX

     imports C-TYPING-MISC-SYNTAX

     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX

     imports COMPAT-SYNTAX

     imports DEBUG-SYNTAX

     rule <k> ERROR(Num:String, Msg:String, _) 
          => #write(#stderr, "Error " +String Num +String ": " +String Msg +String "\n")
          ~> #write(#stderr, "Location: " 
               +String File +String ":" 
               +String Int2String(Line)
               // +String ":"
               // +String Int2String(ColStart) +String "-"
               // +String Int2String(ColEnd)
               +String "\n")
          ~> HALT ... </k>
          <curr-program-loc> 
               CabsLoc(File:String, Line:Int, _, _)
          </curr-program-loc>
     rule <k> ERROR(Num:String, Msg:String, _) 
          => #write(#stderr, "Error " +String Num +String ": " +String Msg +String "\n")
          ~> HALT ... </k>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>

     // TODO(chathhorn): clean up.
     // dynamic exp
     // rule [err00001]: 
     //      (. => ERROR("00001", "Casting empty value to type other than void.", 89)) ~>
     //      cast(t(_, T:K), emptyValue)
     //      when T:K =/=K void
     //      [structural, large]
         
     // rule [err00003]:
     //      (. => ERROR("00003", "Unsequenced side effect on scalar object with value computation of same object.", 315) ) ~>
     //      assert(false, 3)
     //      [structural, large]
     
     // rule [err00010]:
     //      <k> 
     //           (. => ERROR("00010", "Found pointer that refers outside the bounds of an object + 1.", 62) ) ~>
     //           checkValidLoc-aux(loc(Base:SymBase, Offset:Int, _:Int)) 
     //      ...</k>
     //      <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
     //      when Offset:Int >Int Len:Int
     //      [structural, large]
          
     // dynamic exp
     // rule [err00015]:
     //      (. => ERROR("00015", "Signed overflow.", 36) ) ~>
     //      arithInterpret(T:Type, I:Int)
     //      when hasSignedIntegerType(T)
     //           andBool notBool ((min(T) <=Int I:Int) andBool (max(T) >=Int I:Int))
     //      [structural, large]      
          
          
     // rule [err00016]:
     //      <k> 
     //           (. => ERROR("00016", "Unsequenced side effect on scalar object with side effect of same object.") ) ~>
     //           writeByte(Loc:SymLoc, _) 
     //      ...</k>
     //      <locs-written> Locs:Bag </locs-written>
     //      when BagItem(Loc) in Locs:Bag
     //      [structural, large] 
     //      
     // rule [err00017]:
     //      (. => ERROR("00017", "Division by 0.", 319) ) ~>
     //      tv(_:Int, T:Type) / tv(0, T:Type)
     //      when hasIntegerType(T) andBool isPromoted(T)
     //      [structural, large]
     
     // rule [err00018]:
     //      (. => ERROR("00018", "Modulus by 0.", 320) ) ~>
     //      tv(_:Int, T:Type) % tv(0, T:Type)
     //      when hasIntegerType(T) andBool isPromoted(T)
     //      [structural, large]
     //      
     // rule [err00019]:
     //      (. => ERROR("00019", "Signed overflow.", 36) ) ~>
     //      tv(I1:Int, T:Type) % tv(I2:Int, T:Type)
     //      when hasIntegerType(T)
     //           andBool notBool (min(T) <=Int I1 /Int I2
     //                andBool max(T) >=Int I1 /Int I2)
     //           andBool isPromoted(T)
     //           andBool I2 =/=Int 0
     //      [structural, large]
          
     // dynamic exp     
     // rule [err00022]:
     //      (. => ERROR("00022", "Trying to left-shift a negative signed value.", 52) ) ~>
     //      leftShiftInterpret(T:Type, _:Int, tv(E1:Int, T:Type))
     //      when hasSignedIntegerType(T)
     //           andBool E1 <Int 0
     //      [structural, large]
     //      
     // rule [err00023]:
     //      (. => ERROR("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.", 52) ) ~>
     //      leftShiftInterpret(T:Type, I:Int, tv(_:Int, T:Type))
     //      when hasSignedIntegerType(T)
     //           andBool notBool (I <=Int (2 ^Int absInt(numBits(T))))
     //      [structural, large]
          
   //   TODO(chathhorn): catch these in translation, but maybe hold off on e.g.
   //   "main must exist" in case we add a link phase.
   //   rule [err00025a]:
   //        (. => ERROR("00025a", "Main must return an int.", 4) ) ~>
   //        callMain-aux(t(_, functionType(t(_, T:SimpleType), _:KList)), _:Int, _:Id, _)
   //        when T =/=K int
   //        [structural, large]
   //   rule [err00025b]:
   //        <k> 
   //             (. => ERROR("00025b", "Main must exist.", 4) ) ~>
   //             callMain(_, _)
   //        ...</k>
   //        <main-tu> .K </main-tu>
   //        [structural, large]
   //   rule [err00026]:
   //        (. => ERROR("00026", "If main has arguments, the type of the first argument must be equivalent to \"int\".", 4) ) ~>
   //        callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:SimpleType), _:Id),, _:KList))), _:Int, _:Id, _) 
   //        when T =/=K int andBool T =/=K void
   //        [structural, large]
   //        
   //   syntax Bool ::= #isArgvType(Type) [function]
   //   
   //   rule #isArgvType(t(_, T:SimpleType)) => false
   //        when notBool (
   //             getKLabel(T) ==KLabel 'incompleteArrayType 
   //             orBool getKLabel(T) ==KLabel 'pointerType
   //        )
   //   rule #isArgvType(t(_, incompleteArrayType(t(_, T:SimpleType)))) 
   //        => false
   //        when notBool getKLabel(T) ==KLabel 'pointerType
   //   rule #isArgvType(t(_, incompleteArrayType(t(_, pointerType(t(_, T:SimpleType)))))) 
   //        => false
   //        when T =/=K char
   //   rule #isArgvType(t(_, pointerType(t(_, T:SimpleType)))) 
   //        => false
   //        when notBool getKLabel(T) ==KLabel 'pointerType
   //   rule #isArgvType(t(_, pointerType(t(_, pointerType(t(_, T:SimpleType)))))) 
   //        => false
   //        when T =/=K char
   //
   //   rule [err00027]:
   //        (. => ERROR("00027", "If main has arguments, the type of the second argument must be equivalent to  char** .") ) ~>
   //        callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_,
   //        int), _:Id),, typedDeclaration(T:Type, _:Id)))), _:Int, _:Id, _) 
   //        when #isArgvType(T) ==K false
   //        [structural, large]
   //   rule [err00028]:
   //        (. => ERROR("00028", "Main can only have zero or two arguments.") ) ~>
   //        callMain-aux(t(_, functionType(t(_, int), (_:Type,, _:Type,, _:Type,, _:KList))), _:Int, _:Id, _) 
   //        [structural, large]
   //   rule [err00029]:
   //        (. => ERROR("00029", "Main can only have zero or two arguments.") ) ~>
   //        callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:SimpleType), _:Id)))), _:Int, _:Id, _)
   //        when T =/=K void
   //        [structural, large]
          
     // dynamic exp
     // rule [err00034]:
     //      (. => ERROR("00034", "Casting void type to non-void type.", 308) ) ~>
     //      cast(t(_, T:K), skipval)
     //      when (T:K =/=K void)
     //      [structural, large]
          
     // dynamic exp
     // rule [err00041]:
     //      (. => ERROR("00041", "If one of a conditional expression's branches has void type, the other must also have void type.", cv("6.5.15:3")) ) ~>
     //      types((t(_, void),, t(_, T:K)))
     //      when T:K =/=K void
     //      [structural, large]
     // rule [err00042]:
     //      (. => ERROR("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
     //      types((t(_, T:K),, t(_, void)))
     //      when T:K =/=K void
     //      [structural, large]
     // rule [err00043]:
     //      (. => ERROR("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", cv("6.5.15:3")) ) ~>
     //      types((T:Type,, T':Type))
     //      when (T =/=K T')
     //           andBool (isStructType(T) orBool isUnionType(T))
     //           andBool (isStructType(T') orBool isUnionType(T'))
     //      [structural, large]
          
     // rule [err00044]:
     //      (. => ERROR("00044", "An array subscript is out of range.", (46,, 49)) ) ~>
     //      addToPointer(_:SymLoc, T:Type, I:Int, tv(_:Int, _))
     //      when notBool ifFromArrayInBounds(T, I)
     //      [structural, large]
          
     // rule [err00045]:
     //      <k> 
     //           (. => ERROR("00045", "Trying to modify a string literal or an object declared with const type.", (33,, 64,, cv("6.5.16.1:1"))) ) ~>
     //           writeByte(loc(Base:SymBase, _, _), _)
     //      ...</k>
     //      <mem>... Base |-> memblock(_, (_ BagItem(mconst)), _) ...</mem>
     //      [structural, large]
          
     // rule [err00046]:
     //      (. => ERROR("00046", "Trying to reinterpret integer bytes as floating bytes.", 37) ) ~>
     //      concretize(T:Type, dataList((piece(N:Int, _:Int),, _)))
     //      when isFloatType(T) andBool (N >=Int 0)
     //      [structural, large]
          
     // rule [err00047]:
     //      <k> 
     //           (. => ERROR("00047", "Trying to modify an object declared with const type.", 64) ) ~>
     //           writeByte(Loc:SymLoc, _)
     //      ...</k>
     //      <not-writable>... SetItem(Loc) ...</not-writable>
     //      [structural, large]

     syntax K ::= verifySpecifiers(Id)
     syntax K ::= qs(Set)

     // TODO(chathhorn):move this stuff.
     // TODO(chathhorn): a lot of this is likely redundant (e.g., with "preTypes").
     rule <k> verifyDecl(typedDeclaration(T:Type, X:Id))
          => saveSpecifiers(T, X)  ~> verifySpecifiers(X) ...</k>
          when notBool (isStaticType(T) andBool isExternType(T))

     rule <k> verifySpecifiers(X:Id) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <curr-function> file-scope </curr-function>
          <type-specifiers>... kpair(Tu, X) |-> qs(Qs:Set) </type-specifiers>
          when notBool (Static in Qs andBool Extern in Qs)
               andBool notBool (Auto in Qs)
               andBool notBool (Register in Qs)

     rule <k> verifySpecifiers(X:Id) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <curr-function> F:Id </curr-function>
          <type-specifiers>... kpair(Tu, X) |-> qs(Qs:Set) </type-specifiers>
          when notBool (Static in Qs andBool Extern in Qs)
               andBool (F =/=K file-scope)

     syntax K ::= saveSpecifiers(Type, Id)
     rule <k> saveSpecifiers(T:Type, X:Id) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <type-specifiers>
               Decls:Map (. => kpair(Tu, X) |-> qs(getQualities(T)))
          </type-specifiers>
          when notBool (kpair(Tu, X) in keys Decls)
          [structural] 
     rule <k> saveSpecifiers(T:Type, X:Id) => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <type-specifiers>... 
               kpair(Tu, X) |-> qs(_ (. => getQualities(T)))
          </type-specifiers>
          [structural] 

     rule (. => ERROR("00208a",
               "The declaration of " +String S +String " appears with both"
               +String " static and extern specifiers.", 8)) ~>
          verifyDecl(typedDeclaration(T:Type, Identifier(S:String)))
          when isStaticType(T) andBool isExternType(T)

     rule <k> (. => ERROR("00208b",
               "The declaration of " +String S +String " appears with both"
               +String " static and extern specifiers (at different locations in the same translation unit).", 8)) ~>
          verifySpecifiers(Identifier(S:String))
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <type-specifiers>... 
               kpair(Tu, Identifier(S)) |-> qs(_ SetItem(Static) SetItem(Extern))
          ...</type-specifiers>

     // TODO(chathhorn): figure out what to do with these error numbers.
     rule <k> (. => ERROR("90692a",
               "Global declaration of " +String S +String " appears with the auto storage class specifier.", cv("6.9:2"))) ~>
               verifySpecifiers(Identifier(S:String))
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <curr-function> file-scope </curr-function>
          <type-specifiers>... 
               kpair(Tu, Identifier(S)) |-> qs(_ SetItem(Auto))
          ...</type-specifiers>
     rule <k> (. => ERROR("90692b",
               "Global declaration of " +String S +String " appears with the register storage class specifier.", cv("6.9:2"))) ~>
               verifySpecifiers(Identifier(S:String))
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <curr-function> file-scope </curr-function>
          <type-specifiers>... 
               kpair(Tu, Identifier(S)) |-> qs(_ SetItem(Register))
          ...</type-specifiers>

     rule <k> (. => ERROR("90058",
          "Initializer element is not a compile-time constant.", 58))
          ~> instantiateIdVal(symVal, _) ...</k>
          <initializing> true </initializing>

// TODO(chathhorn): add this back.
//      rule <k> (. => ERROR("00215",
//                "Found multiple declarations of " +String S 
//                +String " with incompatible types.", 15)) ~>
//                verifyCompat(T:Type, Identifier(S:String)) 
//           ...</k>
//           <curr-tu> Tu:String </curr-tu>
//           <raw-types>... kpair(Tu, Identifier(S)) |-> PrevT:Type </raw-types>
//           when notBool isTypeCompatible(unqualifyType(PrevT), unqualifyType(T))

// TODO(chathhorn): our type normalizer incorrectly puts the qualifiers on
// the function instead of its return value.
//      rule (. => ERROR("00267",
//                "Function " +String S +String " declared with type qualifiers.", 67)) 
//           ~> doDeclare'(typedDeclaration(T:Type, Identifier(S:String)), _)
//           when isFunctionType(T)
//                andBool getQualifiers(T) =/=Set .Set

endmodule
