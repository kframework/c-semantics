module C-MEMORY-ALLOC-SYNTAX
     syntax K ::= object(Type, Int, Map)

     syntax K ::= writeString(SymLoc, String)
     syntax K ::= writeWString(SymLoc, List)

     syntax K ::= allocString(SymBase, String)
     syntax K ::= allocWString(SymBase, List)

     syntax K ::= alloc(SymBase, Type, Int)

     syntax K ::= zeroObject(SymBase)

     syntax K ::= sizeofObject(SymBase)

     syntax K ::= allocObject(SymBase, Type)
     syntax K ::= allocObjectIfAbsent(SymBase, Type)

     syntax K ::= getEffectiveType(SymLoc)
     syntax K ::= setEffectiveType(SymLoc, Type)
     syntax K ::= checkEffectiveType(Type, K) [strict(2)]

     syntax Set ::= getQualsAtOffset(Type, Int) [function]
endmodule

module C-MEMORY-ALLOC
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ERROR-SYNTAX

     imports COMPAT-SYNTAX
     
     rule writeString(Loc:SymLoc, S:String)
          => Computation(
               allowWrite(* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(ordChar(firstChar(S:String)), t(.Set, char)))
               ~> writeString(Loc +bytes 1, butFirstChar(S:String))
          when S:String =/=String ""
          [structural]
     // fixme this bare 4 needs to be updated to handle different size wchar_ts
     rule writeWString(Loc:SymLoc, ListItem(N:Int) S:List)
          => Computation(
               allowWrite(* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
               := tv(N, cfg:wcharut))
               ~> writeWString(Loc +bytes 4, S)
          [structural] 
     rule writeString(Loc:SymLoc, "")
          => Computation(
               allowWrite(* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(0, t(.Set, char)))
          [structural]
     rule writeWString(Loc:SymLoc, .List)
          => Computation(
               allowWrite(* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
               := tv(0, cfg:wcharut))
          [structural] 

     rule allocObject(Base:SymBase, T:Type)
          => alloc(Base, T, byteSizeofType(T))
          [structural]
     rule <k> allocObjectIfAbsent(Base:SymBase, T:Type) 
               => alloc(Base, T, byteSizeofType(T))
          ...</k>
          <mem> M:Map </mem>
          when notBool (SetItem(Base) in (keys M))
          [structural] 
     rule <k> allocObjectIfAbsent(Base:SymBase, _) => . 
          ...</k>
          <mem>... Base |-> object(_, _, _) ...</mem>
          [structural]

     rule <k> alloc(Base:SymBase, T:Type, Len:Int) => . ...</k>
          <mem>...
               .Map => Base |-> object(T, Len, .Map)
          ...</mem>
          when notBool isLinkerLoc(Base)
          [structural]
     
     // used by calloc
     rule <k> zeroObject(Base:SymBase) => . ...</k>
          <mem>...
               Base |-> object(_, Len:Int, 
                    _ => Map((0 to Len) |-> piece(0, cfg:bitsPerByte)))
          ...</mem>
          [structural]
          
     rule <k> sizeofObject(Base:SymBase)
               => tv(Len, cfg:sizeut)
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          [structural]
          
     // c99 6.5:2 If a side effect on a scalar object is unsequenced relative
     // to either a different side effect on the same scalar object or a value
     // computation using the value of the same scalar object, the behavior is
     // undefined. If there are multiple allowable orderings of the
     // subexpressions of an expression, the behavior is undefined if such an
     // unsequenced side effect occurs in any of the orderings
     //
     // i take this to mean that if i write to a location twice or read from a
     // location after being written to, then it is a problem
          
     rule allocString(Base:SymBase, S:String)
          => allocObject(Base, addQualifier(Const,
               t(.Set, arrayType(t(.Set, char), lengthString(S) +Int 1))))
          ~> writeString(lnew(Base), S)
          [structural]
     rule allocWString(Base:SymBase, S:List)
          => allocObject(Base, addQualifier(Const,
               t(.Set, arrayType(cfg:wcharut, 4 *Int (lengthList(S) +Int 1)))))
          ~> writeWString(lnew(Base), S)
          [structural] 
     
     rule <k> getEffectiveType(loc(Base:SymBase, Offset:Int))
               => getTypeAtOffset(T, Offset)
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          when notBool isNoType(T)
          [structural]
     rule <k> getEffectiveType(loc(Base:SymBase, Offset:Int)) => T' ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          <effective-types>...
               loc(Base, Offset) |-> T':Type
          ...</effective-types>
          when isNoType(T)
          [structural]
     rule <k> getEffectiveType(loc(Base:SymBase, Offset:Int)) => T ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          <effective-types> EffTypes:Map </effective-types>
          when isNoType(T)
               andBool notBool (loc(Base, Offset) in keys(EffTypes))
          [structural]

     rule <k> setEffectiveType(loc(Base:SymBase, _), _) => .
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          when notBool isNoType(T)
          [structural]
     rule <k> setEffectiveType(loc(Base:SymBase, Offset:Int), T':Type) => .
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          <effective-types>...
               .Map => loc(Base, Offset) |-> T'
          ...</effective-types>
          when isNoType(T)
          [structural]

     rule checkEffectiveType(L:Type, Eff:Type) => .
          when #effectivelyCompat(L, Eff) ==K true
          [structural]
     rule (. => UNDEF("CMA1", "Type of lvalue not compatible with the effective type of the object being accessed.", "6.5:7"))
          ~> checkEffectiveType(L:Type, Eff:Type)
          when #effectivelyCompat(L, Eff) =/=K true
          [structural]

     // An  object shall have its stored value accessed only by an lvalue
     // expression that has one of
     syntax Bool ::= "#effectivelyCompat" "(" Type "," Type ")" [function]
     // - a type compatible with the effective type of the object,
     // - a qualified version of a type compatible with the effective type of
     // the object,
     rule #effectivelyCompat(L:Type, Eff:Type) => true
          when areCompatible(stripQualifiers(L), stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     // - a type that is the signed or unsigned type corresponding to the
     // effective type of the object,
     // - a type that is the signed or unsigned type corresponding to a
     // qualified version of the effective type of the object,
     rule #effectivelyCompat(L:Type, Eff:Type) => true
          when areCompatible(correspondingUnsignedType(stripQualifiers(L)),
                    stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
          // TODO(chathhorn): some sort of ==Type? Can't really compare types
          // straight up because of special modifiers.
     rule #effectivelyCompat(L:Type, Eff:Type) => true
          when areCompatible(correspondingSignedType(stripQualifiers(L)),
                    stripQualifiers(Eff))
               andBool getQualifiers(Eff) <=Set getQualifiers(L)
     // - an aggregate or union type that includes one of the aforementioned
     // types among its members (including, recursively, a member of a
     // subaggregate or contained union), or
     //
     // TODO(chathhorn): this is where things get sketchy. I think I understand
     // the intent, and if so, we should have this covered because the lval
     // type will have the type of the field, not the struct/union at this
     // point. Things are more uncertain (in my mind) w/r/t union members --
     // shouldn't the effective type be the last thing stored?
     //
     rule #effectivelyCompat(L:Type, Eff:Type)
          => #effectivelyCompat(L, effInnerType(Eff))
          when isAggregateType(Eff)
               andBool notBool (areCompatible(stripQualifiers(L), stripQualifiers(Eff))
                    andBool getQualifiers(Eff) <=Set getQualifiers(L))
               andBool notBool hasCharType(L)
               //andThenBool (#effectivelyCompat(L, effInnerType(Eff)) ==K true)
     // - a character type.
     rule #effectivelyCompat(L:Type, _) => true
          when hasCharType(L)

     // Returns the "biggest" type at that offset -- i.e., for a struct, union,
     // or array, it'll return the struct/union/array type and not the type of
     // its first member. Returns no-type when nothing seems to be aligned at
     // that offset.
     syntax Type ::= getTypeAtOffset(Type, Int) [function]
     rule getTypeAtOffset(T:Type, 0) => T
     // Preserve the qualifiers.
     rule getTypeAtOffset(T:Type, Offset:Int) => t(getModifiers(T), no-type)
          when (Offset =/=Int 0)
               andBool notBool isAggregateType(T)
     // Arrays.
     rule getTypeAtOffset(t(Mods:Set, arrayType(T:Type, _)), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T),
               Offset %Int byteSizeofType(T))
          when Offset =/=Int 0 // We assume the offset must be in range.
     // Structs.
     rule getTypeAtOffset(t(Mods:Set, structType(_, _, fieldInfo(
               _ ListItem(typedDeclaration(_, F1:CId))
                 ListItem(typedDeclaration(_, F2:CId)) _,
               _ F1 |-> T:Type,
               _ F1 |-> Offset1:Int F2 |-> Offset2:Int
          ))), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T), Offset -Int Offset1)
          when (Offset =/=Int 0)
               andBool (Offset1 <=Int Offset)
               andBool (Offset2 >Int Offset)
     rule getTypeAtOffset(t(Mods:Set, structType(_, _, fieldInfo(
               _ ListItem(typedDeclaration(_, F1:CId)),
               _ F1 |-> T:Type,
               _ F1 |-> Offset1:Int
          ))), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T), Offset -Int Offset1)
          when (Offset =/=Int 0)
               andBool (Offset1 <=Int Offset)

     syntax Set ::= getQualsAtOffset(Type) [function]
     rule getQualsAtOffset(T:Type, Offset:Int)
          => getQualsAtOffset(getTypeAtOffset(T, Offset))

     rule getQualsAtOffset(T:Type) => getQualifiers(T)
          when notBool isAggregateType(T)
     rule getQualsAtOffset(T:Type)
          => getQualifiers(T) getQualsAtOffset(effInnerType(T))
          when isAggregateType(T)
     // TODO(chathhorn): absolutely no idea what to do about qualifiers on
     // union members -- do we need to get the effective type of the object?

     syntax Type ::= effInnerType(K) [function]
     rule effInnerType(T:Type) => innerType(T)
          when isArrayType(T)
     rule effInnerType(t(_, structType(_, _, fieldInfo(
               ListItem(typedDeclaration(T:Type, _)) _, _, _))))
          => T
     // TODO(chathhorn): probably remove.
     //  rule effInnerType(T:Type) => t(.Set, no-type)
     //       when notBool isAggregateType(T)
     //  rule effInnerType(T:K) => t(.Set, no-type)
     //       when isType(T) =/=K true
endmodule
