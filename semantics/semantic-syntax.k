module C-SEMANTIC-SYNTAX
     imports C-SYNTAX //TODO(chathhorn) remove this

     syntax BaseValue ::= Float | Bits // Int is a subsort of Bits
     syntax C ::= BaseValue | Type | Value
     syntax KResult ::= Value | Type

     syntax K      ::= "fromUnion" "(" Id ")" [klabel('fromUnion)]
          
     // Types
     // would rather this be KResult, but can't get the subsorting to work
     syntax Type ::= "typedDeclaration" "(" Type "," Id ")" 
          [latex(\terminal{typedDecl}\!({#1},{#2}\!))] 
     
     // represents a type before canonicalization.  as in "int *x", first arg
     // is "Int", second arg is "PointerType(JustBase)"
     syntax K ::= "DeclType" "(" K "," K ")" [avoid, strict(1)] 
     //syntax "DeclType" -/- [\:]
     syntax Set ::= "setOfTypes" [function]
     
     syntax K ::= "usualArithmeticConversion" "(" Type "," Type ")" [function]
     // having to put this out here so errors can see it
     syntax K ::= "callMain-aux" "(" K "," Int "," Id "," K ")" [strict(1)]
     syntax K ::= "initFunction" "(" K "," K ")" [strict]
     syntax K ::= "populateFromGlobal"
     
     syntax K ::= "checkValidLoc" "(" SymLoc ")"
     syntax K ::= "checkDerefLoc" "(" SymLoc ")"
     syntax ListItem ::= "ListItem" "(" Bag ")"
     syntax K ::= ListToK(List)
     syntax K ::= "map" "(" Map ")"
     syntax Bits ::= "piece" "(" Bits "," Int ")"
     
     syntax Bits ::= "unknown" "(" Int ")"
     syntax Bits ::= Int

     syntax KResult ::= "skipval"
     syntax K ::= "debug"
     syntax K ::= "debug-m" "(" K ")"
     syntax K ::= "discard"
     syntax Id ::= "file-scope"
     syntax Id ::= "unnamedBitField"

     syntax ThreadId ::= Int
     syntax ThreadId ::= "allocatedDuration"
     syntax SymBase ::= Int "@" ThreadId

     // Base, byte offset, bit offset
     syntax SymLoc ::= "loc" "(" SymBase "," Int "," Int ")" [klabel('loc)]
     syntax SymLoc ::= "NullPointer"
     // TODO(chathhorn): move this elsewhere, rather big change.
     syntax KResult ::= SymLoc

     syntax SymLoc ::= linc(SymLoc) [function]

     // fixme maybe if we keep it reduced here, things can go faster
     syntax K ::= SymLoc "+bits" Int [function]
     rule loc(Base:SymBase, Offset:Int, BitOffset:Int) +bits N:Int
          => loc(Base, Offset, BitOffset +Int N)
     syntax K ::= SymLoc "+bytes" Int [function]
     rule loc(Base:SymBase, Offset:Int, BitOffset:Int) +bytes N:Int
          => loc(Base, Offset +Int N, BitOffset)

     syntax Value ::= "enumItem" "(" Id "," Value ")"
     
     syntax String ::= "toString" "(" K ")" [function]
     
     syntax Type ::= "type" "(" K ")"

     syntax Type ::= "maxType" "(" Type "," Type ")" [function]

     // original number, from, to inclusive
     syntax Bits ::= "bitRange" "(" Bits "," Int "," Int ")"
     
     syntax K ::= "fillToBytes" "(" K ")" [strict] 

     // loc with possible bit offset returning base byte     
     syntax SymLoc ::= "floorLoc" "(" SymLoc ")" [function] 
     // loc with possible bit offset returning upperbounded byte     
     syntax SymLoc ::= "ceilingLoc" "(" SymLoc ")" [function]
     syntax K ::= "readFunction" "(" SymLoc ")"
     
     syntax Type ::= innerType(Type) [function]
     
     // data, offset, size in bits
     syntax K ::= "extractBitsFromList" "(" K "," Int "," Int ")" [strict(1)]
     syntax Id ::= "typedef" "(" Id ")"
     syntax Id ::= "unnamed" "(" Int ")"
     
     syntax Int ::= "NullPointerConstant" [function]
     
     syntax Value ::= "emptyValue"
     syntax K ::= "allocate" "(" Type "," K ")"
     
     syntax K ::= "zero" "(" K ")"
     syntax K ::= "zeroBlock" "(" SymLoc ")"
          
     syntax K ::= "value" "(" K ")"
          
     syntax K ::= "sizeofLocation" "(" SymLoc ")"
     
     syntax K ::= "flush" "(" Int ")"
     
     syntax K ::= "allocateType" "(" SymLoc "," Type ")"
     syntax K ::= "allocateTypeIfAbsent" "(" SymLoc "," Type ")"
     syntax K ::= "giveType" "(" Id "," Type ")"
     syntax K ::= "addToEnv" "(" Id "," SymLoc ")"
     
     // location, type
     syntax K ::= "read" "(" SymLoc "," K ")" [strict(2)]
     // location, value
     syntax K ::= "write" "(" K "," K ")" [strict(2)]
     syntax K ::= "writeByte" "(" SymLoc "," K ")" 

     syntax Bool ::= isTypeCompatible(K, K) [function]
     
     syntax Bool ::= isPromoted(Type) [function]
     
     syntax K ::= "initialize" "(" Id "," Type "," K ")"

     syntax K ::= "mconst"

     syntax K ::= "makeUnwritable" "(" SymLoc ")" 
     syntax K ::= "makeUnwritableSubObject" "(" K ")" 
     syntax K ::= "makeUnwritableVar" "(" K ")"
     context makeUnwritableSubObject((HOLE => peval(HOLE)))
     
     syntax K ::= "klistToK" "(" KList ")" [function]
     syntax K ::= "UnknownCabsLoc"
     
     
     syntax K ::= "assert" "(" Bool "," Int ")" // check, error#
     
     // Basic types
     syntax SimpleType ::= "void" | "bool" | "char" | "short-int" | "int" 
                         | "long-int" | "long-long-int"
     syntax SimpleType ::= "float" | "double" | "long-double"
     syntax SimpleType ::= "signed-char" | "unsigned-char"
     syntax SimpleType ::= "unsigned-short-int" | "unsigned-int" 
                         | "unsigned-long-int" | "unsigned-long-long-int"
     syntax SimpleType ::= "no-type"
     
     syntax Bool ::= "isBasicType" "(" K ")" [function]
     
     // Composite types
     syntax SimpleType ::= "enumType" "(" Id ")" 
          [klabel('enumType)]
     syntax SimpleType ::= "arrayType" "(" Type "," Int ")" 
          [klabel('arrayType)]
     syntax SimpleType ::= "incompleteArrayType" "(" Type ")" 
          [klabel('incompleteArrayType)]
     syntax SimpleType ::= "flexibleArrayType" "(" Type ")" 
          [klabel('flexibleArrayType)]
     syntax SimpleType ::= "bitfieldType" "(" Type "," Int ")" 
          [klabel('bitfieldType)]
     syntax SimpleType ::= "functionType" "(" Type "," KList ")" 
          [klabel('functionType)]
     syntax SimpleType ::= "pointerType" "(" Type ")" 
          [klabel('pointerType)]
     syntax SimpleType ::= "structType" "(" Id ")" 
          [klabel('structType)]
     syntax SimpleType ::= "unionType" "(" Id ")" 
          [klabel('unionType)]
     syntax SimpleType ::= "qualifiedType" "(" Type "," K ")" 
          [klabel('qualifiedType)]

     // takes a type, but sometimes things like maps give K
     syntax KResult ::= unqualifyType(K) [function]
     syntax Type ::= removeStorageSpecifiers(K) [function]
     
     // these aren't real types, but are values that can appear in type contexts
     syntax SimpleType ::= "prototype" "(" Type ")" [klabel('prototype)]
     syntax SimpleType ::= "typedefType" "(" Id "," Type ")"
     syntax SimpleType ::= "variadic"

     syntax KResult ::= "dataList" "(" KList ")"

     // generates a tv(size, cfg:sizeut)
     syntax K ::= "sizeofType" "(" K ")" [strict]
     // needs to be heated to top of K for struct and union types
     syntax K ::= "bitSizeofType" "(" K ")" [strict]
     syntax K ::= "byteSizeofType" "(" K ")" [strict] 
     syntax Int ::= "bitsToBytes" "(" Int ")" [function]

     syntax Bool ::= K "in" List [function]
     syntax "in" -/- [a-zA-Z]
     
     syntax Set ::= "assignmentLabels" [function]
     rule assignmentLabels => 
               SetItem(l('_:=_))
               SetItem(l('_*=_))
               SetItem(l('_/=_))
               SetItem(l('_%=_))
               SetItem(l('_+=_))
               SetItem(l('_-=_))
               SetItem(l('_<<=_))
               SetItem(l('_>>=_))
               SetItem(l('_&=_))
               SetItem(l('_^=_))
               SetItem(l('_|=_))
          [macro]
     
     syntax Set ::= "getModifiers" "(" K ")" [function]
     
     syntax K ::= "AllowWrite" "(" K ")" [strict]
     
     rule AllowWrite(lval(N:SymLoc, T:Type)) => lv(N, stripConst(T))
          [structural, anywhere]

     syntax Type ::= stripConst(Type) [function]
     rule stripConst(t((SetItem(Const) => .Set) _, _))
     rule stripConst(t(S:Set, T:K)) => t(S:Set, T:K)
          when notBool Const in S:Set
     
     syntax K ::= "bind" "(" KList "," KList ")"
     syntax Value ::= "tv" "(" KList "," Type ")" 
          [klabel('tv), latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]

     syntax LValue ::= "lv" "(" SymLoc "," Type ")" [klabel('lv)]
     syntax Value ::= "lval" "(" SymLoc "," Type ")" [klabel('lval)]

     syntax K ::= "concretize" "(" Type "," K ")" [strict(2)] 
     syntax Value ::= "functionObject" "(" Id "," Type "," K ")"
     syntax Value ::= "functionPrototype" "(" Id "," Type ")"
     
     syntax String ::= firstChar(String) [function]
     syntax String ::= "nthChar" "(" String "," Int ")" [function]
     syntax String ::= "butFirstChar" "(" String ")" [function]
     
     syntax KList ::=  Int "to" Int [function]
     // as described in 6.3 // totype, fromvalue
     syntax K ::= cast(K, K) [strict(1)]
     context cast(_, (HOLE => reval(HOLE)))
     // interpret the result of arithmetic as in 6.5.4
     syntax K ::= arithInterpret(Type, BaseValue) [function]
     // interpret the values of reading from mem
     syntax K ::= interpret(Type, K) [function]
     
     // syntax Set ::= "integerTypes"
     syntax Set ::= "unsignedIntegerTypes" [function]
     syntax Set ::= "signedIntegerTypes" [function]
     syntax Bool ::= hasIntegerType(Type) [function]
     syntax Bool ::= isFloatType(Type) [function]
     syntax Bool ::= hasUnsignedIntegerType(Type) [function]
     syntax Bool ::= hasSignedIntegerType(Type) [function]
     
     syntax K ::= "typeof" "(" K ")"
     syntax K ::= "writeToFD" "(" Int "," Int ")"
     syntax K ::= "writeToFD" "(" Int "," String ")"
     syntax K ::= "readFromFD" "(" Int ")"
     syntax K ::= "readFromFD" "(" Int "," Int ")"

     syntax K ::= "calculateGotoMap" "(" Id "," K ")"
     
     syntax Bool ::= isCharType(Type) [function]
     syntax Bool ::= isWCharType(Type) [function]
     syntax Bool ::= isPointerType(Type) [function]
     syntax Bool ::= isArrayType(Type) [function]
     syntax Bool ::= isBoolType(Type) [function]
     syntax Bool ::= isStructType(Type) [function]
     syntax Bool ::= isUnionType(Type) [function]
     syntax Bool ::= isAggregateType(Type) [function]
     syntax Bool ::= isFunctionType(Type) [function]
     syntax Bool ::= isFunctionPointerType(Type) [function]
     syntax Bool ::= isBitfieldType(Type) [function]
     syntax Bool ::= isExternType(Type) [function]
     syntax Bool ::= isStaticType(Type) [function]
     syntax Bool ::= isConstType(Type) [function]
     syntax Bool ::= isIncompleteType(Type) [function]
     syntax Bool ::= isArithmeticType(Type) [function]

     // first map is for type, second map is for offset
     syntax K ::= "aggregateInfo" "(" KList "," Map "," Map ")"
     // these expect an aggregateInfo term as second argument
     syntax Int ::= getFieldOffset(Id, K) [function]
     syntax Type ::= getFieldType(Id, K) [function]
     
     syntax Bool ::= isArithBinConversionOp(KLabel) [function]
     syntax Bool ::= isArithUnaryOp(KLabel) [function]
     syntax K ::= "kpair" "(" K "," K ")"
     // should be K, but is Type for efficiency reasons
     syntax Type ::= promote(K) [function]
     syntax K ::= argPromote(K) [function]
     // bytes of struct, type, field id
     syntax K ::= "extractField" "(" KList "," K "," Id ")" 
     syntax K ::= "allocString" "(" SymLoc "," String ")"
     syntax K ::= "allocWString" "(" SymLoc "," KList ")"
     syntax K ::= "sequencePoint"
     
     syntax K ::= "handleBuiltin" "(" Id "," Type ")"
     
     syntax Int ::= min(Type) [function]
     syntax Int ::= max(Type) [function]
     syntax K ::= "alloc" "(" K "," K ")" // should be K K 
     syntax K ::= "realloc" "(" K "," K "," K "," K ")" // should be K K 
     
     // these are also used by compound literals
     syntax KResult ::= "initValue" "(" Id "," Type "," K ")"
     // id, type, initializer
     syntax K ::= "figureInit" "(" Id "," K "," K ")" [strict(2)] 
     
     // appends a new subobject to a current object.  this is unsafe and should
     // only be used for variadic functions
     syntax K ::= "append" "(" Int "," Int "," Value ")"
     // deletes the base object from memory, given a location
     syntax K ::= "deleteBlock" "(" SymLoc ")"
     // deletes the base object from memory, given a location and it size (as a
     // check)
     syntax K ::= "deleteSizedBlock" "(" SymLoc "," Int ")"

     syntax K ::= memblock(Int, Bag, Map)
     syntax K ::= "pgmArgs" "(" KList ")" [function]
     syntax K ::= "resolveReferences"
     syntax K ::= "incomingArguments" "(" KList ")" [klabel('incomingArguments)]
     syntax K ::= "callMain" "(" Int "," K ")" [klabel('callMain)]
endmodule
