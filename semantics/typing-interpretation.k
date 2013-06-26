module C-TYPING-INTERPRETATION
     imports C-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS

     syntax K ::= "BitFieldType" "(" K "," K ")" [strict] 
     
     rule Specifier(klist(L:KList)) => canonicalizeType(toBag(L))
          [structural]
          
     rule BitFieldType(T:KResult, tv(N:Int, _))
          => t(.Set, bitfieldType(T:KResult, N:Int)) [structural, anywhere]
     
     syntax KLabel ::= "makeArrayType" "(" Int ")"
     syntax KLabel ::= "makeFunctionType" "(" KList ")"
     syntax Type ::= pushTypeDown(Type, KLabel) [function]
     syntax KLabel ::= "makePointerType"
     syntax KLabel ::= "makeIncompleteArrayType"
     
     // fixme, throwing away specifier
     rule ArrayType(T:KResult, tv(N:Int, _), _) 
          => pushTypeDown(T:KResult, makeArrayType(N:Int)) 
          when N:Int >Int 0
          [structural, anywhere]
     rule ArrayType(T:KResult, emptyValue, _)
          => pushTypeDown(T:KResult, makeIncompleteArrayType)
          [structural, anywhere]
     rule PointerType(T:KResult)
          => pushTypeDown(T:KResult, makePointerType)
          [structural, anywhere]
     // fixme I'm assuming functiontype is always below a prototype in the ast
     rule FunctionType(T:KResult) => T:KResult
          [structural, anywhere]
     rule Prototype(T:KResult, krlist(L:KList), false) 
          => pushTypeDown(T:KResult, makeFunctionType(L:KList)) 
          [structural, anywhere]
     rule Prototype(T:KResult, krlist(L:KList), true) 
          => pushTypeDown(T:KResult,
               makeFunctionType((L:KList,, t(.Set, variadic)))) 
          [structural, anywhere]
     
     rule [pushdown-array]: 
          pushTypeDown(t(S:Set, arrayType(T:KResult, N:Int)), K:KLabel) 
          => t(S:Set, arrayType(pushTypeDown(T:KResult, K:KLabel), N:Int))
     rule [pushdown-incomplete]: 
          pushTypeDown(t(S:Set, incompleteArrayType(T:KResult)), K:KLabel) 
          => t(S:Set, incompleteArrayType(pushTypeDown(T:KResult, K:KLabel)))
     rule [pushdown-pointer]: 
          pushTypeDown(t(S:Set, pointerType(T:KResult)), K:KLabel) 
          => t(S:Set, pointerType(pushTypeDown(T:KResult, K:KLabel)))
     rule [pushdown-qualified]: 
          pushTypeDown(t(S:Set, qualifiedType(T:KResult, K:K)), Kl:KLabel) 
          => t(S:Set, qualifiedType(pushTypeDown(T:KResult, Kl:KLabel), K:K))
     rule [pushdown-function]: 
          pushTypeDown(t(S:Set, functionType(T:KResult, L:KList)), K:KLabel) 
          => t(S:Set, functionType(pushTypeDown(T:KResult, K:KLabel), L:KList))
     rule [pushdown-struct]: 
          pushTypeDown(t(S:Set, structType(X:Id)), K:KLabel) 
          => K:KLabel(t(S:Set, structType(X:Id)))
     rule [pushdown-union]: 
          pushTypeDown(t(S:Set, unionType(X:Id)), K:KLabel) 
          => K:KLabel(t(S:Set, unionType(X:Id)))
     rule [pushdown-enum]: 
          pushTypeDown(t(S:Set, enumType(X:Id)), K:KLabel) 
          => K:KLabel(t(S:Set, enumType(X:Id)))
     
     rule [pushdown-typedef]: 
          pushTypeDown(t(S:Set, typedefType(_:Id, t(S':Set, T:K))), K:KLabel) 
          => K:KLabel(t(S:Set S':Set, T:K))
     
     rule [pushdown-basic]: 
          pushTypeDown(T:KResult, K:KLabel) => K:KLabel(T:KResult) 
          when isBasicType(T:KResult)
          [structural]
     
     rule makeArrayType(N:Int)(T:KResult)
          => t(.Set, arrayType(T:KResult, N:Int)) 
          [structural, anywhere]
     rule makeFunctionType(L:KList)(T:KResult)
          => t(.Set, functionType(T:KResult, giveNamesToArgs(L:KList))) 
          [structural, anywhere]
     rule makePointerType(T:KResult)
          => t(.Set, pointerType(T:KResult))
          [structural, anywhere]
     rule makeIncompleteArrayType(T:KResult)
          => t(.Set, incompleteArrayType(T:KResult))
          [structural, anywhere]
     
     syntax KList ::= giveNamesToArgs(KList) [function]
     syntax KList ::= "giveNamesToArgs-aux" "(" Int "," KList ")" [function]
     
     rule giveNamesToArgs(L:KList) => giveNamesToArgs-aux(0, L:KList)
     rule giveNamesToArgs-aux(N:Int, 
               (typedDeclaration(T:KResult, X:Id),, L:KList))
          => typedDeclaration(T:KResult, X:Id),,
               giveNamesToArgs-aux(N:Int, L:KList)
          when X:Id =/=K #NoName
          [structural]
     rule giveNamesToArgs-aux(N:Int, 
               (typedDeclaration(T:KResult, X:Id),, L:KList))
          => typedDeclaration(T:KResult, #NoName(N:Int)),,
               giveNamesToArgs-aux(N:Int +Int 1, L:KList)
          when X:Id ==K #NoName
          [structural]
     rule giveNamesToArgs-aux(_:Int, t(.Set, variadic))
          => t(.Set, variadic)
          [structural]
     rule giveNamesToArgs-aux(_:Int, .KList)
          => .KList
          [structural]
     
     rule <k> JustBase => T:KResult ...</k>
          <declarationTypeHolder> T:KResult => .K ...</declarationTypeHolder>
          [structural]

     syntax K ::= "extractActualTypeFreezer"
     rule <k>
               DeclType(T:KResult, K:K) => K:K ~> extractActualTypeFreezer
          ...</k>
          <declarationTypeHolder> (. => T:KResult) ...</declarationTypeHolder>
          [structural]
     
     rule T:KResult ~> extractActualTypeFreezer 
          => extractActualType(T)
          [structural]
          
     syntax KList ::= fillUnionBitHoles(KList) [function]
     syntax KList ::= "fillUnionBitHoles-aux" "(" Int "," KList ")" [function]
     rule fillUnionBitHoles(.KList) => .KList
     rule fillUnionBitHoles((K:K,, L:KList)) 
          => fillUnionBitHoles-aux(0, (K:K,, L:KList))
     rule fillUnionBitHoles-aux(N:Int, 
               (typedDeclaration(T:KResult, X:Id),, L:KList)) 
          => typedDeclaration(T:KResult, X:Id),, 
               fillUnionBitHoles-aux(N:Int, L:KList)
          when notBool isBitfieldType(T:KResult)
          [structural]
     rule fillUnionBitHoles-aux(N:Int, (typedDeclaration(t(S:Set, 
               bitfieldType(T:KResult, N':Int)), X:Id),, L:KList)) 
          => typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':Int)), X:Id),, 
               fillUnionBitHoles-aux(maxInt(N:Int, N':Int), L:KList)
          [structural]
     rule fillUnionBitHoles-aux(N:Int, .KList) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               N:Int +Int (absInt(numBitsPerByte -Int 
               (N:Int %Int numBitsPerByte)) %Int numBitsPerByte))), #NoName)
          [structural]
     
     syntax KList ::= fillBitHoles(KList) [function]
     syntax KList ::=  "fillBitHoles-aux" "(" Int "," KList ")" [function]
     rule [fillBitHoles-none]:
          fillBitHoles(.KList) => .KList 
          [structural]
     // if we haven't seen bitfields
     rule [fillBitHoles-not-bitfield]:
          fillBitHoles((typedDeclaration(T:KResult, X:Id),, L:KList)) 
          => typedDeclaration(T:KResult, X:Id) ,, fillBitHoles(L:KList)
          when notBool isBitfieldType(T:KResult) 
          [structural]
     
     rule [fillBitHoles-bitfield]:
          fillBitHoles((typedDeclaration(T:KResult, X:Id),, L:KList)) 
          => fillBitHoles-aux(0, (typedDeclaration(T:KResult, X:Id),, L:KList))
          when isBitfieldType(T:KResult) 
          [structural]
     
     // if we have seen bitfields
     rule [fillBitHoles-aux-not-bitfield]:
          fillBitHoles-aux(N:Int, (typedDeclaration(T:KResult, X:Id),, L:KList)) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(numBitsPerByte -Int (N:Int %Int numBitsPerByte)) 
               %Int numBitsPerByte)), #NoName),,
               fillBitHoles((typedDeclaration(T:KResult, X:Id),, L:KList))
          when notBool isBitfieldType(T:KResult) 
          [structural]
     
     rule [fillBitHoles-aux-bitfield-normal]:
          fillBitHoles-aux(N:Int, (typedDeclaration(t(S:Set, 
               bitfieldType(T:KResult, N':Int)), X:Id),, L:KList)) 
          => typedDeclaration(t(S:Set, bitfieldType(T:KResult, N':Int)), X:Id),, 
               fillBitHoles-aux(N:Int +Int N':Int, L:KList)
          when N':Int =/=Int 0 
          [structural]
          
     rule [fillBitHoles-bitfield-zero]:
          fillBitHoles-aux(N:Int, (typedDeclaration(t(_, 
               bitfieldType(_:KResult, N':Int)), _:Id),, L:KList)) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(numBitsPerByte -Int (N:Int %Int numBitsPerByte)) 
               %Int numBitsPerByte)), #NoName),, 
               fillBitHoles(L:KList)
          when N':Int ==Int 0
          [structural]
     
     rule [fillBitHoles-done]:
          fillBitHoles-aux(N:Int, .KList) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int), 
               absInt(numBitsPerByte -Int (N:Int %Int numBitsPerByte))
               %Int numBitsPerByte)), #NoName) 
          [structural]
     
     rule typedDeclaration(t(_, bitfieldType(_, N:Int)), #NoName),,
               typedDeclaration(t(_, bitfieldType(_, N':Int)), #NoName) 
          => typedDeclaration(t(.Set, bitfieldType(t(.Set, unsigned-int),
               N:Int +Int N':Int)), #NoName) 
          [structural, anywhere]
     
     // fixme chould check for some struct contraints here
     syntax KList ::= incompleteToFlexibleArrayMember(KList) [function]

     rule incompleteToFlexibleArrayMember((typedDeclaration(T:KResult, X:Id),, 
               L:KList))
          => typedDeclaration(T:KResult, X:Id),, 
               incompleteToFlexibleArrayMember(L:KList)
          when notBool isIncompleteType(T:KResult) 
          [structural]
     rule incompleteToFlexibleArrayMember(typedDeclaration(t(S:Set,
               incompleteArrayType(T:KResult)), X:Id)) 
          => typedDeclaration(t(S:Set, flexibleArrayType(T:KResult)), X:Id) 
          [structural]
     rule incompleteToFlexibleArrayMember(.KList) => .KList
     
     rule StructDef(X:Id, krlist(L:KList))
          => addStruct(X:Id, fillBitHoles(incompleteToFlexibleArrayMember(L)))
               ~> giveType(X:Id, t(.Set, structType(X:Id)))
          [structural]
     rule UnionDef(X:Id, krlist(L:KList))
          => addUnion(X:Id, fillUnionBitHoles(L))
               ~> giveType(X:Id, t(.Set, unionType(X:Id)))
          [structural]

     // the K will resolve to a type, so throw it away
     rule OnlyTypedef(K:K) => K ~> discard
          [structural]
          
     rule NameAndType(X:Id, T:KResult) => typedDeclaration(T, X)
          [structural, anywhere] 
     
     rule [extract-basic]: 
          extractActualType(T:KResult) => T
          when isBasicType(T)
     rule [extract-enum]: 
          extractActualType(t(S:Set, enumType(X:Id))) 
          => t(S, enumType(X))
     rule [extract-struct]:
          extractActualType(t(S:Set, structType(X:Id))) 
          => t(S, structType(X))
     rule [extract-union]:
          extractActualType(t(S:Set, unionType(X:Id))) 
          => t(S, unionType(X))
     rule [extract-array]:
          extractActualType(t(S:Set, arrayType(T:KResult, N:Int))) 
          => t(S, arrayType(extractActualType(T), N))
     rule [extract-incompleteArray]:
          extractActualType(t(S:Set, incompleteArrayType(T:KResult))) 
          => t(S, incompleteArrayType(extractActualType(T)))
     rule [extract-bitfield]:
          extractActualType(t(S:Set, bitfieldType(T:KResult, N:Int))) 
          => t(S, bitfieldType(extractActualType(T), N))
     rule [extract-function]:
          extractActualType(t(S:Set, functionType(T:KResult, List:KList))) 
          => t(S, functionType(extractActualType(T), List))
     rule [extract-pointer]:
          extractActualType(t(S:Set, pointerType(T:KResult))) 
          => t(S, pointerType(extractActualType(T)))
     rule [extract-qualified]:
          extractActualType(t(S:Set, qualifiedType(T:KResult, K:K))) 
          => t(S, qualifiedType(extractActualType(T), K))
     rule [extract-typedef]:
          extractActualType(t(S:Set, typedefType(_:Id, t(S':Set, T:K)))) 
          => extractActualType(t(S S', T))
          
     syntax K ::= "NameAndType" "(" K "," K ")" [strict(2)] 
          
     rule SingleName(T:KResult, Name(X:Id, K:K)) 
          => NameAndType(X:Id, DeclType(T:KResult, K:K))
          [structural, anywhere] 
     rule [Separate-FieldGroups]:
          FieldGroup(K:K, klist((C:K,, C':K,, L:KList))) 
          => FieldGroup(K:K, klist(C:K)),, 
               FieldGroup(K:K, klist((C':K,, L:KList)))
          [structural, anywhere]

     rule FieldGroup(T:KResult, klist(Name(X:Id, K:K))) 
          => NameAndType(X:Id, DeclType(T:KResult, K:K))
          [structural, anywhere]
          
     rule FieldGroup(T:KResult, klist(BitFieldName(Name(X:Id, K:K), Size:K)))
          => NameAndType(X:Id, DeclType(T:KResult, BitFieldType(K:K, Size:K)))
          [structural, anywhere] 
     rule FieldName(K:K) => K [structural, anywhere]
endmodule

