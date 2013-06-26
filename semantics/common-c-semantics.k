require "c-syntax.k"
require "common-c-helpers.k"
require "c-configuration.k"

require "common-c-statements.k"
require "common-c-declarations.k"
require "common-c-typing.k"

module COMPAT-SYNTAX
     imports K
     imports C-SYNTAX 
     imports C-CONFIGURATION 

     syntax Bool ::= Bag "==Bag" Bag [function]
     syntax Bool ::= Bag "=/=Bag" Bag [function]

     syntax Bag ::= toBag(List) [function]
                | toBag(KList) [function]

     syntax Int ::= "lengthKList" KList [function]

     syntax Bool ::= BagItem "in" Bag [function]
               | K "#inBag" Bag [function]

     syntax KList ::= eraseKLabel(KLabel, KList) [function]

     // TODO(chathhorn): hackish, rename at least
     syntax K ::= rkludge(K) [function, klabel('rkludge)]
     syntax K ::= pkludge(K) [function, klabel('pkludge)]

     syntax Bits ::= right:
                    "~Bits" Bits
                    [function, right, latex(\mathop{\sim_{\scriptstyle\it Bits}}{#1})]
                    > left:
                    Bits "/Bits" Bits
                    [function, left, latex({#1}\mathrel{\div_{\scriptstyle\it Bits}}{#2})]
                    > left:
                    Bits "&Bits" Bits
                    [function, left, latex({#1}\mathrel{\&_{\scriptstyle\it Bits}}{#2})]
                    > left:
                    Bits "xorBits" Bits
                    [function, left, latex({#1}\mathrel{\oplus_{\scriptstyle\it Bits}}{#2})]
                    > left:
                    Bits "|Bits" Bits
                    [function, left, latex({#1}\mathrel{|_{\scriptstyle\it Bits}}{#2})]

     syntax Ptr ::= Int | SymLoc

     syntax Int ::= "String2Rat" "(" String "," Int ")"
          [function, klabel('String2Rat), hook(#CONVERSION:string2Base)]
     syntax String ::= "Rat2String" "(" Int "," Int ")"
          [function, klabel('Rat2String), hook(#CONVERSION:base2String)]

     syntax Float ::= "sqrtFloat" "(" Float ")" 
          [function, hook(#FLOAT:sqrtFloat)]
     syntax Float ::= "logFloat" "(" Float ")" 
          [function, hook(#FLOAT:logFloat)]
     syntax Float ::= "expFloat" "(" Float ")" 
          [function, hook(#FLOAT:expFloat)]
     syntax Float ::= "atanFloat" "(" Float ")" 
          [function, hook(#FLOAT:atanFloat)]
     syntax Float ::= "acosFloat" "(" Float ")" 
          [function, hook(#FLOAT:acosFloat)]
     syntax Float ::= "asinFloat" "(" Float ")" 
          [function, hook(#FLOAT:asinFloat)]
     syntax Float ::= "tanFloat" "(" Float ")" 
          [function, hook(#FLOAT:tanFloat)]
     syntax Float ::= "cosFloat" "(" Float ")" 
          [function, hook(#FLOAT:cosFloat)]
     syntax Float ::= "sinFloat" "(" Float ")" 
          [function, hook(#FLOAT:sinFloat)]
     syntax Float ::= "atan2Float" "(" Float "," Float ")" 
          [function, hook(#FLOAT:atan2Float)]
     syntax Float ::= "floorFloat" "(" Float ")" 
          [function, hook(#FLOAT:floorFloat)]

endmodule

module COMMON-SEMANTIC-SYNTAX
     imports K
     imports C-SYNTAX 
     imports C-CONFIGURATION 
     
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
endmodule

module COMMON-C-SETTINGS
     imports COMMON-SEMANTIC-SYNTAX 
     
     // S 6.2.5 p.35 i.15.  "The implementation shall define char to have the
     // same range, representation, and behavior as either signed char or
     // unsigned char.  37)... Irrespective of the choice made, char is a
     // separate type from the other two and is not compatible with either"
     //
     // fixme I'm not sure what consequence being a separate type entails, so
     // for now it will just be rewritten to the chosen type
     rule char => signed-char [structural, anywhere]

     syntax Int ::= "numBitsPerByte" [function]
     syntax Int ::= numBytes(Type) [function]
     syntax Int ::= numBits(Type) [function]

     rule [numBitsPerByte]: numBitsPerByte => 8
     
     rule [numBytes-bool]: numBytes(t(_, bool)) => 1
     rule [numBytes-signed-char]: numBytes(t(_, signed-char)) => 1
     rule [numBytes-short-int]: numBytes(t(_, short-int)) => 2
     rule [numBytes-int]: numBytes(t(_, int)) => 4
     rule [numBytes-long-int]: numBytes(t(_, long-int)) => 4
     rule [numBytes-long-long-int]: numBytes(t(_, long-long-int)) => 8
     
     rule [numBytes-float]: numBytes(t(_, float)) => 4
     rule [numBytes-double]: numBytes(t(_, double)) => 8
     rule [numBytes-long-double]: numBytes(t(_, long-double)) => 16
     
     rule [numBytes-enum]: 
          numBytes(t(S:Set, enumType(_:Id))) => numBytes(t(S:Set, int))
     
     syntax Int ::= "cfg:mtxPlain" [function]
     rule [cfg-mtxPlain]: cfg:mtxPlain => 0
     
     syntax Type ::= "cfg:sizeut" [function]
     rule [cfg-size-t]: cfg:sizeut => t(.Set, unsigned-int)
     
     syntax Type ::= "cfg:wcharut" [function]
     rule [cfg-wchar-t]: cfg:wcharut => t(.Set, int)
     
     syntax SimpleType ::= simpleType(Type) [function]
     rule simpleType(t(_, T:K)) => T:K
     
     syntax Type ::= "cfg:largestUnsigned" [function]
     rule [cfg-largestUnsigned]:
          cfg:largestUnsigned => t(.Set, unsigned-long-long-int)

     syntax Int ::= "cfg:ptrsize" [function]
     rule [cfg-ptrsize]: cfg:ptrsize => 4
     
     syntax Type ::= "cfg:ptrdiffut" [function]
     rule [cfg-ptrdiff-t]: cfg:ptrdiffut => t(.Set, int)
     
     rule [min]: min(t(S:Set, enumType(_:Id))) => min(t(S:Set, int))
     rule [max]: max(t(S:Set, enumType(_:Id))) => max(t(S:Set, int))
     
     syntax Int ::= rank(Type) [function]
     
endmodule

module COMMON-INCLUDE
     imports COMMON-SEMANTIC-SYNTAX
     imports COMMON-C-SETTINGS
     imports COMPAT-SYNTAX
     imports COMMON-C-HELPERS
     imports COMPAT-SYNTAX
endmodule

module COMMON-C-SEMANTICS-MISC
     imports COMMON-INCLUDE 
     
     rule linc(loc(X:Int @ Th:ThreadId, ByOff:Int, BiOff:Int))
          => loc(X +Int 1 @ Th, ByOff, BiOff)

     rule [unknown-loc]: 
          CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc 
          [structural, anywhere]

     rule [expression-loc]: ExpressionLoc(K:K, _) => K
          [structural, anywhere]

     rule [CodeLoc-k]:
          <k> CodeLoc(K:K, L:CabsLoc) => K ...</k>
          <currentProgramLoc> _ => L:CabsLoc </currentProgramLoc>
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{6.10.6}{1}}}{
     A preprocessing directive of the form
     \cdisplay{# pragma pp-tokensoptnew-line}
     \broken{where the preprocessing token \cinline{STDC} does not immediately
     follow pragma in the directive (prior to any macro replacement)} causes the
     implementation to behave in an implementation-defined manner. The behavior
     might cause translation to fail or cause the translator or the resulting
     program to behave in a non-conforming manner. Any such pragma that is not
     recognized by the implementation is ignored.
     }*/
     rule [Pragma]: Pragma(_:K) => .
          [structural]
          
     rule AttributeWrapper(K:K, _) => K:K [structural, anywhere]
     
     rule loc(Base:SymBase, Offset:Int, BitOffset:Int)
          => loc(Base, Offset +Int BitOffset /Int numBitsPerByte,
               BitOffset %Int numBitsPerByte)
          when BitOffset:Int >=Int numBitsPerByte
          [structural, anywhere]
     
     rule Identifier("___missing_field_name") => #NoName [structural, anywhere]

     rule NothingExpression => emptyValue
endmodule

module COMMON-C-SEMANTICS
     imports COMMON-INCLUDE 
     
     imports COMMON-C-SEMANTICS-MISC
     imports COMMON-C-STATEMENTS
     imports COMMON-C-DECLARATIONS
     imports COMMON-C-TYPING
     
     syntax KLabel ::= "TranslationUnitName" "(" String ")" 
          [klabel('TranslationUnitName)]

endmodule
