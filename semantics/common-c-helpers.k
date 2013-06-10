require "common-c-semantics.k"

module COMPAT
     imports COMMON-SEMANTICS-HELPERS-INCLUDE

     rule X:Bag ==Bag Y:Bag => Bag2KLabel X(.KList) ==K Bag2KLabel Y(.KList)
     rule X:Bag =/=Bag Y:Bag => notBool (X ==Bag Y)

     rule toBag(ListItem(K:K) L:List) => BagItem(K) toBag(L)
     rule toBag(.List) => .Bag

     rule toBag(K:K,, L:KList) => BagItem(K) toBag(L)
     rule toBag(.KList) => .Bag

     rule lengthKList (K:K,, Kl:KList) => 1 +Int lengthKList Kl
     rule lengthKList .KList => 0

     rule BagItem(K) in B:Bag => K #inBag B ==K true 
     rule K #inBag BagItem(K) _:Bag => true

     rule eraseKLabel(L, L(Ks)) => eraseKLabel(L, Ks)
     rule eraseKLabel(L, L'(Ks)) => L'(eraseKLabel(L, Ks))
          when L =/=KLabel L'
     rule eraseKLabel(L, (K:K,,Kl:KList)) => eraseKLabel(L, K),,eraseKLabel(L, Kl)
     rule eraseKLabel(L, .KList) => .KList
     rule eraseKLabel(L, .) => .

     // TODO(chathhorn): ugly
     syntax K ::= "toKRList" "(" KList ")"
     syntax K ::= "toKRList'" "(" KList ")"

     syntax K ::= "toRVList" "(" KList ")"
     syntax K ::= "toRVList'" "(" KList ")"

     syntax KResult ::= "krlist" "(" KList ")"
     syntax KResult ::= "rvlist" "(" KList ")"

     rule <k> klist(L:KList) => toKRList(L) ...</k>

     context toKRList'(_,, HOLE,, _)
     context toRVList'(_,, (HOLE => reval(HOLE)),, _)

     rule <k> toKRList(L:KList) => toKRList'(L) ~> krlist(.KList) ...</k>
     rule <k> toRVList(L:KList) => toRVList'(L) ~> rvlist(.KList) ...</k>

     rule <k> toKRList'(_,, (V:KResult => .KList),, _) 
          ~> krlist(_,, (.KList => V),, _) 
          ...</k>

     rule <k> toRVList'(_,, (V:KResult => .KList),, _) 
          ~> rvlist(_,, (.KList => V),, _) 
          ...</k>

     rule <k> toKRList'(.KList) => .K ...</k>
     rule <k> toRVList'(.KList) => .K ...</k>

     rule all(ListItem(K) L:List, Lbl:KLabel) => Lbl(K) andBool all(L, Lbl) 
     rule all(., _) => true 

     rule allk((K:K,, L:KList), Lbl:KLabel) => Lbl(K) andBool allk(L, Lbl) 
     rule allk(.KList, _) => true 

endmodule

module COMMON-SEMANTICS-HELPERS-INCLUDE
     imports COMMON-NOHELPER-INCLUDE

     syntax Bits ::= Bits "bit::" Bits
endmodule

module COMMON-SEMANTICS-HELPERS-MISC
     imports COMMON-SEMANTICS-HELPERS-INCLUDE

     syntax K ::= firstLoc(K) [function]
     rule firstLoc(ThreadId:Int) => loc(sb(0 , ThreadId:Int), 0, 0)
     
     syntax SymBase ::= base(SymLoc) [function]
     rule base(loc(Base:SymBase, _, _)) => Base
     
     syntax Set ::= "gatherInnerCells" "(" Bag "," CellLabel ")" [function]
     syntax Set ::= "gatherInnerCells-aux" "(" Bag "," CellLabel "," Set ")" [function]
     // TODO(chathhorn): celllabel, elided
     // rule gatherInnerCells(B:Bag, L:CellLabel) => gatherInnerCells-aux(B:Bag, L:CellLabel, .Set)
     // rule gatherInnerCells-aux(((<L':CellLabel> <L:CellLabel> K:K </L:CellLabel> _ </L':CellLabel> => .Bag) _), L:CellLabel, _ (.Set => SetItem(K:K)))
     // rule gatherInnerCells-aux(.Bag, _, S:Set) => S
     
     syntax List ::= "stringToList" "(" String ")" [function]
     syntax String ::= listToString(List) [function]
     
     rule stringToList("") => .List
     rule stringToList(S:String)
               => ListItem(firstChar(S:String)) stringToList(butFirstChar(S:String))
          when S:String =/=String ""
          
     rule listToString(.List) => ""
     rule listToString((ListItem(S:String) L:List))
               => S:String +String listToString(L:List)
     
     syntax Bool ::= isUnknown(K) [function] // Ints, Bits, SymLocs
     rule [isUnknown-piece]: isUnknown(piece(_, _)) => true
     rule [isUnknown-ptr]: isUnknown(loc(_:SymBase, _:Int, _:Int)) => false
     rule [isUnknown-int]: isUnknown(I:Int) => false
          // TODO(chathhorn): silly sort check
          when (I <=Int 0) orBool (I >Int 0)

     syntax K ::= simplifyTruth(K) [function]
     rule simplifyTruth(K:K) => K:K != tv(0, t(.Set, int))
     
     syntax Bool ::= isNotTruthValue(Value) [function]
     rule isNotTruthValue(tv(V:K, t(_, T:K))) 
          => T:K =/=K int
          orBool ( V:K =/=K 0 andBool V:K =/=K 1 )
          [structural]
     
     syntax K ::= getIdOfDeclaration(K) [function]
     syntax K ::= getIdOfName(K) [function]
     rule getIdOfDeclaration(DeclarationDefinition(InitNameGroup(_, klist(K:K))))
          => getIdOfName(K:K)
     rule getIdOfName(InitName(K:K, _)) => getIdOfName(K:K)
     rule getIdOfName(SingleName(_, K:K)) => getIdOfName(K:K)
     rule getIdOfName(Name(X:Id, _)) => X:Id
     
     // this maintains byte order
     syntax K ::= "fillToBytes-aux" "(" K "," KList ")"
     rule [fillToBytes-start]:
          fillToBytes(dataList(L:KList)) 
               => fillToBytes-aux(dataList(L:KList), .KList) 
          [structural]
     rule [fillToBytes-foundByte]:
          fillToBytes-aux(dataList((L:KList,, piece(N:Bits, Len:Int))), L':KList)
               => fillToBytes-aux(dataList(L:KList), (piece(N, Len),, L'))
          when Len ==Int numBitsPerByte
          [structural]
     
     rule [fillToBytes-addBit]:
          fillToBytes-aux(dataList(piece(N:Bits, Len:Int)), L':KList)
               => fillToBytes-aux(dataList((piece(0, 1),, piece(N, Len))), L')
          when Len:Int <Int numBitsPerByte
          [structural]
          
     rule [fillToBytes-combineBits]:
          fillToBytes-aux(dataList((L:KList,, piece(N:Bits, Len:Int),, piece(N':Bits, Len':Int))), L':KList)
               => fillToBytes-aux(dataList((L,, piece(piece(N, Len) bit:: piece(N', Len'), Len +Int Len'))), L')
          when Len +Int Len' <=Int numBitsPerByte
          [structural]
                    
     rule [fillToBytes-done]:
          fillToBytes-aux(dataList(.KList), L:KList)
               => dataList(L:KList)
          [structural]
          
     // coallesce bitranges that are adjacent
     rule piece(bitRange(N:Bits, SuccTo:Int, To':Int), Len:Int) bit:: piece(bitRange(N, From:Int, To:Int), Len':Int)
          => piece(bitRange(N, From, To'), Len +Int Len')
          when (Len +Int Len' <=Int numBitsPerByte)
               andBool (SuccTo ==Int To +Int 1)
          [structural]
     
     rule piece(N:Bits bit:: N':Bits, Len:Int) bit:: piece(N'':Bits, Len':Int)
          => piece((N bit:: N') bit:: piece(N'', Len'), Len +Int Len')
          [structural]

     rule piece(N'':Bits, Len':Int) bit:: piece(N:Bits bit:: N':Bits, Len:Int)
          => piece((piece(N'', Len') bit:: N) bit:: N', Len +Int Len')
          [structural]

     rule bitRange(N:Bits bit:: piece(_, Len:Int), Pos:Int, Pos:Int)
          => bitRange(N, absInt(Pos -Int Len), absInt(Pos -Int Len))
          when (Pos >Int 0)
               andBool (Pos -Int Len >=Int 0)
          [structural]
          
     rule bitRange(_ bit:: piece(N:Bits, 1), 0, 0) => piece(N:Bits, 1)
     rule bitRange(piece(N, 1), 0, 0) => piece(N, 1)
          
     rule bitRange(piece(bitRange(N:Bits, Start:Int, End:Int), Len:Int), 0, 0)
          => bitRange(piece(bitRange(N, Start, Start), 1), 0, 0)
          when Start +Int Len ==Int End +Int 1
          [structural]
     
     rule bitRange(N:Int, Pos:Int, Pos:Int) => 1 &Int (N >>Int Pos)
          [structural]
     rule bitRange(piece(N:Int, 1), Pos:Int, Pos:Int) => 1 &Int (N >>Int Pos)
          [structural]
          
     rule bitRange(N:Bits, 0, To:Int) => N
          when To +Int 1 ==Int numBitsPerByte
          [structural]
     
     rule bitRange(_ bit:: piece(N:Bits, Len:Int), Start:Int, End:Int)
          => bitRange(piece(N, Len), Start, End)
          when End +Int 1 <=Int Len
          [structural]
     
     rule bitRange(piece(N:Bits, SuccEnd:Int), 0, End:Int)
          => piece(N, End +Int 1)
          when SuccEnd ==Int End +Int 1
          [structural]
     rule bitRange(_ bit:: piece(N:Bits, SuccEnd:Int), 0, End:Int)
          => piece(N, End +Int 1)
          when SuccEnd ==Int End +Int 1
          [structural]
          
     rule bitRange(piece(N:Int, Len:Int), Pos:Int, Pos:Int) => (N >>Int Pos) &Int 1
          [structural]
     
     syntax K ::= "extractField-pre" "(" KList "," Type "," Int "," K ")" [strict(4)]
     syntax K ::= "extractField-aux" "(" KList "," Type "," Int "," Int "," KList ")"
     
     // fixme could speed things up by caching bitsizeoftype as well
     rule [extractField-start]:
          <k> extractField(L:KList, 't(_,, Lb:KLabel(S:Id)), F:Id)
               => extractField-pre(L:KList, T:KResult, Offset:Int, bitSizeofType(T:KResult)) 
          ...</k>
          <structs>... 
               S:Id |-> aggregateInfo(_, (_ F:Id |-> T:KResult), (_ F:Id |-> Offset:Int)) 
          ...</structs>
          when Lb:KLabel ==KLabel 'unionType
          orBool Lb:KLabel ==KLabel 'structType
          [structural]

     rule <k> extractField-pre(L:KList, T:KResult, Offset:Int, tv(Len:Int, _))
               => concretize(T:KResult, fillToBytes(extractBitsFromList(dataList(L:KList), Offset:Int, Len:Int)))
          ...</k>
          [structural]
     
     rule isConcreteNumber(loc(_, _, _)) => false
     rule isConcreteNumber(I:Int) => true
          when  I:Int <=Int 0 orBool I:Int >Int 0
          [structural]
     
     // this should probably go in the k prelude
     rule K:K in (ListItem(K:K) _:List) => true
     rule K:K in .List => false
     rule K:K in (ListItem(K':K) L:List) => K:K in L:List
          when K:K =/=K K':K
          [structural]
     
     rule [discard]:
          <k> V:KResult ~> discard => .K ...</k>
          [structural]
     
     //- derived
     rule bitsToBytes(N:Int) => absInt(N:Int /Int numBitsPerByte)
          when numBitsPerByte dividesInt N:Int
          [structural]
     rule bitsToBytes(N:Int) => absInt((N:Int /Int numBitsPerByte) +Int 1) 
          when notBool numBitsPerByte dividesInt N:Int
          [structural]
          
     rule numBytes(t(_, unsigned-char)) => numBytes(t(.Set, signed-char))
     rule numBytes(t(_, unsigned-short-int)) => numBytes(t(.Set, short-int))
     rule numBytes(t(_, unsigned-int)) => numBytes(t(.Set, int))
     rule numBytes(t(_, unsigned-long-int)) => numBytes(t(.Set, long-int))
     rule numBytes(t(_, unsigned-long-long-int)) => numBytes(t(.Set, long-long-int))
     
     rule numBits(t(S:Set, T:K)) => numBytes(t(S:Set, T:K)) *Int numBitsPerByte
          when getKLabel(T:K) =/=KLabel 'bitfieldType
          [structural]
     rule numBits(t(_, bitfieldType(_, N:Int))) => N:Int

     rule min(t(_, bool)) => 0
     rule max(t(_, bool)) => 1
     
     rule min(t(_, signed-char)) => 0 -Int (2 ^Int absInt(numBits(t(.Set, signed-char)) -Int 1))
     // rule min(t(_, signed-char)) => kccSettingInt("_KCC_SCHAR_MIN") [structural]
     rule max(t(_, signed-char)) => (2 ^Int absInt(numBits(t(.Set, signed-char)) -Int 1)) -Int 1
     rule min(t(_, short-int)) => 0 -Int (2 ^Int absInt(numBits(t(.Set, short-int)) -Int 1))
     rule max(t(_, short-int)) => (2 ^Int absInt(numBits(t(.Set, short-int)) -Int 1)) -Int 1
     rule min(t(_, int)) => 0 -Int (2 ^Int absInt(numBits(t(.Set, int)) -Int 1))
     rule max(t(_, int)) => (2 ^Int absInt(numBits(t(.Set, int)) -Int 1)) -Int 1
     rule min(t(_, long-int)) => 0 -Int (2 ^Int absInt(numBits(t(.Set, long-int)) -Int 1))
     rule max(t(_, long-int)) => (2 ^Int absInt(numBits(t(.Set, long-int)) -Int 1)) -Int 1
     rule min(t(_, long-long-int)) => 0 -Int (2 ^Int absInt(numBits(t(.Set, long-long-int)) -Int 1))
     rule max(t(_, long-long-int)) => (2 ^Int absInt(numBits(t(.Set, long-long-int)) -Int 1)) -Int 1
     
     rule min(t(_, unsigned-char)) => 0
     rule max(t(_, unsigned-char)) => 2 ^Int absInt(numBits(t(.Set, unsigned-char))) -Int 1
     rule min(t(_, unsigned-short-int)) => 0
     rule max(t(_, unsigned-short-int)) => (2 ^Int absInt(numBits(t(.Set, unsigned-short-int)))) -Int 1
     rule min(t(_, unsigned-int)) => 0
     rule max(t(_, unsigned-int)) => (2 ^Int absInt(numBits(t(.Set, unsigned-int)))) -Int 1
     rule min(t(_, unsigned-long-int)) => 0
     rule max(t(_, unsigned-long-int)) => (2 ^Int absInt(numBits(t(.Set, unsigned-long-int)))) -Int 1
     rule min(t(_, unsigned-long-long-int)) => 0
     rule max(t(_, unsigned-long-long-int)) => (2 ^Int absInt(numBits(t(.Set, unsigned-long-long-int)))) -Int 1
     
     
      // TODO(chathhorn): I mucked with stuff here.
     //rule asciiCharString(S:String) => asciiString(S:String)
     rule [firstChar]:
          firstChar(S:String) => substrString(S:String, 0, 1)
          [structural]
     rule [nthChar]:
          nthChar(S:String, N:Int) => substrString(S:String, N:Int, 1)
          [structural]
     // rule [charToAscii]:
     //   charToAscii(C:Char) => asciiString(C:Char)
     //   [structural]
     rule [butFirstChar]:
          butFirstChar(S:String) => substrString(S:String, 1, lengthString(S:String))
          [structural]
          
     syntax String ::= toUpperCase(String) [function]
     //syntax Char ::= toUpperCase(Char) [function]
     rule toUpperCase(S:String)
          => toUpperCase(firstChar(S:String)) +String toUpperCase(butFirstChar(S:String))
          when S:String =/=String ""
          [structural]
     rule toUpperCase("") => ""
          
     // getString returns the string without the null terminator
     syntax K ::= "getString" "(" K ")"
     syntax K ::= "getString-aux" "(" SymLoc "," String ")"
     rule getString(Loc:SymLoc) => getString-aux(Loc, "") [structural, anywhere]
     rule getString(tv(Loc:SymLoc, _)) => getString-aux(Loc, "") [structural, anywhere]
     syntax Value ::= "str" "(" String ")"
     
     rule [getString-pre]:
          <k> (.K => read(Loc, t(.Set, char)))
               ~> getString-aux((Loc:SymLoc => Loc +bytes 1), _)
          ...</k>
          [structural]
          
     rule [getString]:
          <k> tv(N:Int, _) ~> getString-aux(Loc:SymLoc, S:String)
               => getString-aux(Loc, S +String #charString(N))
          ...</k>
          when N =/=Int 0
          [structural]
     rule [getString-done]:
          <k> tv(0, _) ~> getString-aux(Loc:SymLoc, S:String)
               => str(S:String)
          ...</k>
          [structural]
          
     // writeString and writeWString expect the user to add the '\0' to the end
     // of the strings passed
     // chathhorn: made these non-strict (w/SymLoc), I forget why.
     syntax K ::= "writeString" "(" SymLoc "," String ")" // [strict(1)]
     syntax K ::= "writeWString" "(" SymLoc "," KList ")" // [strict(1)]

     rule [write-string]:
          <k> writeString(Loc:SymLoc, S:String)
               => Computation((* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
                    := tv(asciiString(firstChar(S:String)), t(.Set, char)))
               ~> writeString(Loc +bytes 1, butFirstChar(S:String))
          ...</k>
          when S:String =/=String ""
          [structural]
     // fixme this bare 4 needs to be updated to handle different size wchar_ts
     rule [write-wstring]:
          <k> writeWString(Loc:SymLoc, (N:Int,, S:KList))
               => Computation((* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
                    := tv(N, cfg:wcharut))
               ~> writeWString(Loc +bytes 4, S)
          ...</k>
          [structural] 
     rule [write-empty-string]:
          <k> writeString(_, "") => .K ...</k>
          [structural]
     rule [write-empty-wstring]:
          <k> writeWString(_, .KList) => .K ...</k>
          [structural]
          
     
     // fixme might be messing things up elsewhere
     syntax String ::= pointerToString(SymLoc) [function]
     syntax String ::= subPointerToString(SymBase) [function]

     rule [pointerToString]:
          pointerToString(loc(N:SymBase, M:Int, 0))
               => "[sym(" +String subPointerToString(N) +String ") + " 
               +String Int2String(M) +String "]"
          [structural]
          
     rule [subPointerToString-auto]:
          subPointerToString(sb(B:Int, Th:Int))
               => "sb(" +String Int2String(B) +String ", " +String Int2String(Th) +String ")"
          [structural]
     rule [sub-pointerToString-allocated]:
          subPointerToString(sb(B:Int, allocatedDuration))
               => "sb(" +String Int2String(B) +String ", " +String "allocatedDuration)" 
          [structural]
     
     rule [pointerToString-done]:
          pointerToString(NullPointer) => "NullPointer" 
          [structural]
          
     rule N:Int to N:Int => .KList
     rule N:Int to N':Int => (N:Int,,((N:Int +Int 1) to N':Int))
          when N:Int <Int N':Int
          [structural]

     rule hasIntegerType(T:Type) 
          => (hasUnsignedIntegerType(T) orBool hasSignedIntegerType(T))
          [structural]
     
     rule hasUnsignedIntegerType(t(_, T:K)) => true
          when (T in unsignedIntegerTypes)
          [structural]
     rule hasUnsignedIntegerType(t(_, T:K)) => false
          when (T in signedIntegerTypes)
          [structural]

     rule hasUnsignedIntegerType(t(S:Set, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'bitfieldType)
          andBool ((l(getKLabel(T:K)) in setOfTypes) orBool isFloatType(t(S:Set, T:K)))
          [structural]
     rule hasUnsignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => true
          when hasUnsignedIntegerType(T) ==Bool true
          [structural]
     rule hasUnsignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => false
          when hasUnsignedIntegerType(T) ==Bool false
          [structural]
     
     rule hasSignedIntegerType(t(_, T:K)) => true
          when (T in signedIntegerTypes)
          [structural]
     rule hasSignedIntegerType(t(_, T:K)) => false
          when (T in unsignedIntegerTypes)
          [structural]

     rule hasSignedIntegerType(t(_, enumType(_:Id))) => true // choice fixme
     rule hasSignedIntegerType(t(S:Set, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'bitfieldType)
          andBool ((l(getKLabel(T:K)) in setOfTypes) orBool isFloatType(t(S:Set, T:K)))
          [structural]
     rule hasSignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => true
          when hasSignedIntegerType(T) ==Bool true
          [structural]
     rule hasSignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => false
          when hasSignedIntegerType(T) ==Bool false
          [structural]

     rule min(t(_, bitfieldType(T:Type, N:Int))) => 0
          when hasUnsignedIntegerType(T)
          [structural]
     rule max(t(_, bitfieldType(T:Type, N:Int))) => (2 ^Int absInt(N:Int)) -Int 1
          when hasUnsignedIntegerType(T)
          [structural]
     
     rule min(t(_, bitfieldType(T:Type, N:Int))) => 0 -Int (2 ^Int absInt(N:Int -Int 1))
          when hasSignedIntegerType(T)
          [structural]
     rule max(t(_, bitfieldType(T:Type, N:Int))) => (2 ^Int absInt(N:Int -Int 1)) -Int 1
          when hasSignedIntegerType(T)
          [structural]
          
     rule NullPointerConstant => 0
     
     rule piece(N:Int, Len:Int) bit:: piece(N':Int, Len':Int)
          => piece((N <<Int Len') |Int N', Len +Int Len')
          [structural, anywhere]
     rule piece(0, 0) bit:: N:Bits => N
          [structural, anywhere]
     rule piece(piece(N:Bits, Len:Int), Len:Int) => piece(N, Len) 
          [structural, anywhere]
     rule value(tv(V:KList, _)) => V:KList
          [structural, anywhere]
     rule type(tv(_, T:KResult)) => T:KResult
          [structural, anywhere]
     rule isBasicType('t(_,, K:K)) => #if (
          (K:K ==K bool)
          orBool (K:K ==K void)
          orBool (K:K ==K char)
          orBool (K:K ==K short-int)
          orBool (K:K ==K int)
          orBool (K:K ==K long-int)
          orBool (K:K ==K long-long-int)
          orBool (K:K ==K float)
          orBool (K:K ==K double)
          orBool (K:K ==K long-double)
          orBool (K:K ==K signed-char)
          orBool (K:K ==K unsigned-char)
          orBool (K:K ==K unsigned-short-int)
          orBool (K:K ==K unsigned-int)
          orBool (K:K ==K unsigned-long-int)
          orBool (K:K ==K unsigned-long-long-int)
          orBool (K:K ==K no-type)
          orBool (getKLabel(K:K) ==KLabel 'enumType)
          ) #then true #else false #fi

     rule setOfTypes => 
          SetItem(l('arrayType))
          SetItem(l('bitfieldType))
          SetItem(l('functionType))
          SetItem(l('pointerType))
          SetItem(l('structType))
          SetItem(l('unionType))
          SetItem(l('qualifiedType))
     
     rule assert(true, _:Int) => .K [structural, anywhere]
endmodule

module COMMON-C-BITSIZE
     imports COMMON-SEMANTICS-HELPERS-INCLUDE

     syntax K ::= bitSizeofList(KList)
     syntax K ::= "bitSizeofList-aux" "(" K "," Int "," KList ")" [strict(1)]

     // TODO(chathhorn): BUG? Note doesn't heat when .K.
     rule bitSizeofList-aux(K:K, X:Int, L:KList) => K ~> bitSizeofList-aux(HOLE, X, L) 
          when notBool (K ==K .K) [heat]
     rule K:KResult ~> bitSizeofList-aux(HOLE, X:Int, L:KList) => bitSizeofList-aux(K, X, L) [cool]
     
      // TODO(chathhorn)
     rule bitSizeofList(L:KList) => bitSizeofList-aux(., 0, L:KList)
          [structural]
     rule bitSizeofList-aux((. => bitSizeofType(T:K)), _:Int, ((T:K => .KList),, _:KList))
          [structural]
     rule bitSizeofList-aux((tv(Len':Int, _) => .), (Len:Int => Len:Int +Int Len':Int), _)
          [structural]
     rule bitSizeofList-aux(., Len:Int, .KList) => tv(Len:Int, cfg:largestUnsigned)
          [structural]
          
     syntax K ::= "maxBitSizeofList" "(" KList ")"
     syntax K ::= "maxBitSizeofList-aux" "(" KList "," Int ")"
     rule maxBitSizeofList(L:KList) => maxBitSizeofList-aux(L:KList, 0) [structural, anywhere]
     rule <k> maxBitSizeofList-aux((T:KResult,, L:KList), N:Int)
               => bitSizeofType(T:KResult) 
               ~> maxBitSizeofList-aux(L:KList, N:Int) 
          ...</k>
          [structural] 
     rule <k> (tv(N':Int, _) => .) 
               ~> maxBitSizeofList-aux(L:KList, (N:Int => maxInt(N:Int, N':Int))) 
          ...</k>
          [structural] 
     rule <k> maxBitSizeofList-aux(.KList, N:Int) => tv(N:Int, cfg:largestUnsigned) ...</k>
          [structural] 
     
     rule bitSizeofType(t(_, arrayType(T:KResult, N:Int))) => bitSizeofType(T:KResult) * tv(N:Int, cfg:largestUnsigned) [structural, anywhere]
     rule bitSizeofType(t(_, flexibleArrayType(T:KResult))) => tv(0, cfg:largestUnsigned) [structural, anywhere]
     rule bitSizeofType(t(_, functionType(_, _))) => tv(numBitsPerByte, cfg:largestUnsigned) [structural, anywhere]
     rule bitSizeofType(t(_, pointerType(_))) => tv(cfg:ptrsize *Int numBitsPerByte, cfg:largestUnsigned) [structural, anywhere]
     rule bitSizeofType(t(_, bitfieldType(_, N:Int))) => tv(N:Int, cfg:largestUnsigned) [structural, anywhere]
     rule bitSizeofType(t(_, qualifiedType(T:KResult, _))) => bitSizeofType(T:KResult) [structural, anywhere]
     rule bitSizeofType(T:KResult) => tv(numBits(T:KResult), cfg:largestUnsigned) when isBasicType(T:KResult) [structural, anywhere]
     rule bitSizeofType(typedDeclaration(T:KResult, _:Id)) => bitSizeofType(T:KResult) [structural, anywhere]

     rule <k> bitSizeofType(t(_, structType(S:Id))) => bitSizeofList(L:KList) ...</k>
          <structs>... S:Id |-> aggregateInfo(L:KList, _, _) ...</structs>
          [structural] 
     rule <k> bitSizeofType(t(_, unionType(S:Id))) => maxBitSizeofList(L:KList) ...</k>
          <structs>... S:Id |-> aggregateInfo(L:KList, _, _) ...</structs>
          [structural]
          
     rule getFieldOffset(F:Id, aggregateInfo(_, _, (_ F:Id |-> N:Int))) => N:Int
     rule getFieldType(F:Id, aggregateInfo(_, _, (_ F:Id |-> T:KResult))) => T:KResult

     rule toString(Identifier(S:String)) => S:String
     rule toString(S:String) => S:String
     rule toString(Num:Int) => Int2String(Num:Int)
     
     rule klistToK((K:K,, L:KList)) => K:K ~> klistToK(L:KList)
     rule klistToK(.KList) => .K
endmodule


module COMMON-C-HELPERS
     imports COMMON-SEMANTICS-HELPERS-INCLUDE
     imports COMMON-C-BITSIZE
     imports COMMON-SEMANTICS-HELPERS-MISC
     imports COMPAT
endmodule
