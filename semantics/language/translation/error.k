module C-TRANSLATION-ERROR
     imports C-ERROR-SYNTAX
     imports C-ERROR-MAP-SYNTAX
     imports C-CONSTRAINT-MAP-SYNTAX

     imports C-BITS-SYNTAX
     imports C-COMMON-EXPR-ADDITIVE-SYNTAX
     imports C-COMMON-EXPR-BITWISE-SYNTAX
     imports C-COMMON-EXPR-CONDITIONAL-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

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
     rule [err00001]: 
          (. => ERROR("00001", "Casting empty value to type other than void.", 89)) ~>
          cast(t(_, T:K), emptyValue)
          when T:K =/=K void
          [structural, large]
         
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
          
     rule [err00022]:
          (. => ERROR("00022", "Trying to left-shift a negative signed value.", 52) ) ~>
          leftShiftInterpret(T:Type, _:Int, tv(E1:Int, T:Type))
          when hasSignedIntegerType(T)
               andBool E1 <Int 0
          [structural, large]
          
     rule [err00023]:
          (. => ERROR("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.", 52) ) ~>
          leftShiftInterpret(T:Type, I:Int, tv(_:Int, T:Type))
          when hasSignedIntegerType(T)
               andBool notBool (I <=Int (2 ^Int absInt(numBits(T))))
          [structural, large]
          
     rule [err00034]:
          (. => ERROR("00034", "Casting void type to non-void type.", 308) ) ~>
          cast(t(_, T:K), skipval)
          when (T:K =/=K void)
          [structural, large]
          
     rule [err00041]:
          (. => ERROR("00041", "If one of a conditional expression's branches has void type, the other must also have void type.", cv("6.5.15:3")) ) ~>
          types(ListItem(t(_, void)) ListItem(t(_, T:K)))
          when T:K =/=K void
          [structural, large]
     rule [err00042]:
          (. => ERROR("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
          types(ListItem(t(_, T:K)) ListItem(t(_, void)))
          when T:K =/=K void
          [structural, large]
     rule [err00043]:
          (. => ERROR("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", cv("6.5.15:3")) ) ~>
          types(ListItem(T:Type) ListItem(T':Type))
          when (T =/=K T')
               andBool (isStructType(T) orBool isUnionType(T))
               andBool (isStructType(T') orBool isUnionType(T'))
          [structural, large]
          
     rule [err00044]:
          (. => ERROR("00044", "An array subscript is out of range.", (46,, 49)) ) ~>
          addToPointer(_:SymLoc, T:Type, I:Int, tv(_:Int, _))
          when notBool ifFromArrayInBounds(T, I)
          [structural, large]
          
     // rule [err00046]:
     //      (. => ERROR("00046", "Trying to reinterpret integer bytes as floating bytes.", 37) ) ~>
     //      concretize(T:Type, dataList((piece(N:Int, _:Int),, _)))
     //      when hasFloatType(T) andBool (N >=Int 0)
     //      [structural, large]
          
//     // TODO(chathhorn): figure out what to do with these error numbers.
//     rule <k> (. => ERROR("90692a",
//               "Global declaration of " +String S +String " appears with the auto storage class specifier.", cv("6.9:2"))) ~>
//               verifySpecifiers(Identifier(S:String))
//          ...</k>
//          <curr-tu> Tu:String </curr-tu>
//          <curr-function> file-scope </curr-function>
//          <type-specifiers>... 
//               kpair(Tu, Identifier(S)) |-> qs(_ SetItem(Auto))
//          ...</type-specifiers>
//     rule <k> (. => ERROR("90692b",
//               "Global declaration of " +String S +String " appears with the register storage class specifier.", cv("6.9:2"))) ~>
//               verifySpecifiers(Identifier(S:String))
//          ...</k>
//          <curr-tu> Tu:String </curr-tu>
//          <curr-function> file-scope </curr-function>
//          <type-specifiers>... 
//               kpair(Tu, Identifier(S)) |-> qs(_ SetItem(Register))
//          ...</type-specifiers>
//
//     rule <k> (. => ERROR("90058",
//          "Initializer element is not a compile-time constant.", 58))
//          ~> instantiateIdVal(symVal, _) ...</k>
//          <initializing> true </initializing>

// TODO(chathhorn): add this back.
//      rule <k> (. => ERROR("00215",
//                "Found multiple declarations of " +String S 
//                +String " with incompatible types.", 15)) ~>
//                verifyCompat(T:Type, Identifier(S:String)) 
//           ...</k>
//           <curr-tu> Tu:String </curr-tu>
//           <raw-types>... kpair(Tu, Identifier(S)) |-> PrevT:Type </raw-types>
//           when notBool areCompatibleTypes(PrevT, T)

endmodule
