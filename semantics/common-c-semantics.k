require "c-syntax.k"
require "common-c-helpers.k"
require "c-configuration.k"

require "common-c-statements.k"
require "common-c-expressions.k"
require "common-c-declarations.k"
require "common-c-typing.k"

module COMPAT-SYNTAX
     imports COMMON-INCOMING-MODULES 

     syntax VT ::= Value | Type
     syntax VTList ::= List{VT, ","}

     syntax Bool ::= Bag "==Bag" Bag [function]
     syntax Bool ::= Bag "=/=Bag" Bag [function]

     syntax Bag ::= toBag(List) [function]
                | toBag(KList) [function]

     syntax Int ::= "lengthKList" KList [function]

     //syntax Bool ::= K "in" Bag [function]
     //            | BagItem "in" Bag [function]
     syntax Bool ::= BagItem "in" Bag [function]
               | K "#inBag" Bag //TODO: function?!?

     syntax KList ::= eraseKLabel(KLabel, KList) [function]
endmodule

module COMMON-INCOMING-MODULES
     imports K
     imports C-SYNTAX 
     imports C-CONFIGURATION 
     // TODO(chathhorn) ??
     //imports K-CONTEXTS 
     
endmodule

module COMMON-SEMANTIC-SYNTAX
     imports COMMON-INCOMING-MODULES 
     
     syntax BaseValue ::= Int | Float
     syntax C ::= BaseValue | Type | Value
     syntax KResult ::= Value | Type

     // TODO(chathhorn): surely not necessary?
     // fixme super sketchy
     // define true orBool _ => true
     // define _ orBool true => true
     // define false andBool _ => false
     // define _ andBool false => false

     // these are used for runtime settings
     // syntax SimpleType ::= "kccSettingSimpleType" "(" String ")"
     // syntax #NzNat ::= "kccSettingNzNat" "(" String ")"
     // syntax Int ::= "kccSettingInt" "(" String ")"
     
     syntax K      ::= "fromUnion" "(" Id ")" [klabel('fromUnion)]
          
     // Types
     syntax Type ::= "typedDeclaration" "(" Type "," Id ")" [latex(\terminal{typedDecl}\!({#1},{#2}\!))] // would rather this be KResult, but can't get the subsorting to work
     
     syntax K ::= "DeclType" "(" K "," K ")" [strict(1)] // represents a type before canonicalization.  as in "int *x", first arg is "Int", second arg is "PointerType(JustBase)"
     syntax "DeclType" -/- [a-zA-Z\:]
     // op 'isTypeResult_ : K -> Bool 
     syntax Set ::= "setOfTypes" [function]
     
     syntax K ::= "usualArithmeticConversion" "(" Type "," Type ")"
     syntax K ::= "callMain-aux" "(" K "," Int "," Id "," K ")" [strict(1)] // having to put this out here so errors can see it
     syntax K ::= "initFunction" "(" K "," K ")" [strict]
     syntax K ::= "populateFromGlobal"
     
     syntax K ::= "checkValidLoc" "(" K ")"
     syntax K ::= "checkDerefLoc" "(" K ")"
     syntax ListItem ::= "ListItem" "(" Bag ")"
     syntax K ::= ListToK(List)
     syntax K ::= "Map" "(" Map ")"
     syntax Int ::= "piece" "(" Int "," Int ")"
     //define 'isInt(piece(_, _)) => true
     
     syntax Int ::= "unknown" "(" Int ")"
     //define 'isInt(unknown(_)) => true
     
     syntax KResult ::= "skipval"
     syntax K ::= "debug"
     syntax K ::= "debug-m" "(" K ")"
     syntax K ::= "discard"
     syntax Id ::= "file-scope" // [ctor] 
     syntax Id ::= "unnamedBitField" // [ctor] 

     
     syntax SymLoc ::= "loc" "(" Int "," Int "," Int ")" // Base, byte offset, bit offset
     syntax Int ::= SymLoc
     //define 'isInt(loc(_, _, _)) => true
     
     // fixme maybe if we keep it reduced here, things can go faster
     syntax K ::= K "+bits" K [function]
     rule loc(Base:Int, Offset:Int, BitOffset:Int) +bits N:Int
          => loc(Base:Int, Offset:Int, BitOffset:Int +Int N:Int)

     //declare bitoffset : Int -> Int 
     //declare byteoffset : Int -> Int
     syntax Value ::= "enumItem" "(" Id "," Value ")"
     syntax K ::= "resolveReferences"
     
     syntax String ::= "toString" "(" K ")" [function]
     
     syntax Type ::= "maxType" "(" Type "," Type ")" [function]
     
     syntax Int ::= "bitRange" "(" Int "," Int "," Int ")" // original number, from, to inclusive
     
     syntax K ::= "fillToBytes" "(" K ")" [strict] 
     
     syntax Int ::= "floorLoc" "(" Int ")" [function] // loc with possible bit offset returning base byte     
     syntax Int ::= "ceilingLoc" "(" Int ")" [function] // loc with possible bit offset returning upperbounded byte     
     syntax K ::= "readFunction" "(" Int ")"
     
     syntax Type ::= innerType(Type) [function]
     
     // syntax KResult ::= "AttributeValue" "(" String "," KList ")"
     
     syntax K ::= "extractBitsFromList" "(" K "," Int "," Int ")" [strict(1)] // data, offset, size in bits
     syntax Id ::= "typedef" "(" Id ")"
     syntax Id ::= "unnamed" "(" Int ")"
     
     syntax Int ::= "NullPointerConstant" [function]
     //define 'isInt(NullPointerConstant) => true
     
     syntax Int ::= "NullPointer"
     //define 'isInt(NullPointer) => true
     
     syntax Value ::= "emptyValue"
     syntax K ::= "allocate" "(" Type "," K ")"
     
     syntax K ::= "zero" "(" K ")"
     syntax K ::= "zeroBlock" "(" Int ")"
          
     syntax K ::= "value" "(" K ")"
          
     syntax K ::= "sizeofLocation" "(" K ")"
     syntax Type ::= "type" "(" K ")"
     
     syntax K ::= "flush" "(" Int ")"
     
     syntax K ::= "allocateType" "(" Int "," Type ")"
     syntax K ::= "allocateTypeIfAbsent" "(" Int "," Type ")"
     syntax K ::= "giveType" "(" Id "," Type ")"
     syntax K ::= "addToEnv" "(" Id "," Int ")"
     
     syntax K ::= "read" "(" K "," K ")" [strict(2)] // location, type
     syntax K ::= "write" "(" K "," K ")" [strict(2)] // location, value
     syntax K ::= "writeByte" "(" Int "," K ")" 

     syntax Bool ::= isTypeCompatible(K, K) [function]
     
     syntax Bool ::= isPromoted(Type) [function]
     // syntax Bool ::= "isPromotedInteger" "(" Type ")"
     
     
     syntax SymLoc ::= "inc" "(" SymLoc ")" [function]
     
     //define 'isInt(threadId(N:Int) +Int M:Int) => true
     //define 'isInt(allocatedDuration +Int M:Int) => true
     syntax Int ::= "threadId" "(" Int ")" // used for symbolic locations based on threadid
     syntax Int ::= "allocatedDuration" // fake threadid for above when location is of allocated duration
     // syntax Int ::= "readOnly" // fake threadid for above when location can't be written to
          
     syntax K ::= "initialize" "(" Id "," Type "," K ")"
     // syntax K ::= "memblock" "(" Bag "," Map ")" // length and an array from offsets to bytes
     syntax BagItem ::= "mlength" "(" Int ")" 
     syntax BagItem ::= "mconst"
     syntax K ::= "makeUnwritable" "(" Int ")" 
     syntax K ::= "makeUnwritableSubObject" "(" K ")" 
     syntax K ::= "makeUnwritableVar" "(" K ")"
     context makeUnwritableSubObject((HOLE => peval(HOLE)))
     
     syntax K ::= "klistToK" "(" KList ")" 
     syntax K ::= "UnknownCabsLoc"
     
     
     syntax K ::= "assert" "(" Bool "," Int ")" // check, error#
     
     // Basic types
     syntax SimpleType ::= "void" | "bool" | "char" | "short-int" | "int" | "long-int" | "long-long-int"
     syntax SimpleType ::= "float" | "double" | "long-double"
     syntax SimpleType ::= "signed-char" | "unsigned-char"
     syntax SimpleType ::= "unsigned-short-int" | "unsigned-int" | "unsigned-long-int" | "unsigned-long-long-int"
     syntax SimpleType ::= "no-type"
     
     syntax Type ::= "t" "(" Set "," SimpleType ")" [klabel('t)]
     
     syntax Bool ::= "isBasicType" "(" K ")" [function]
     
     // Composite types
     syntax SimpleType ::= "enumType" "(" Id ")" [klabel('enumType)] // [ctor] 
     syntax SimpleType ::= "arrayType" "(" Type "," Int ")" [klabel('arrayType)] // [ctor] 
     syntax SimpleType ::= "incompleteArrayType" "(" Type ")" [klabel('incompleteArrayType)] // [ctor] 
     syntax SimpleType ::= "flexibleArrayType" "(" Type ")" [klabel('flexibleArrayType)] // [ctor] 
     syntax SimpleType ::= "bitfieldType" "(" Type "," Int ")" [klabel('bitfieldType)] // [ctor] 
     syntax SimpleType ::= "functionType" "(" Type "," KList ")" [klabel('functionType)] // [ctor] 
     syntax SimpleType ::= "pointerType" "(" Type ")" [klabel('pointerType)] // [ctor] 
     syntax SimpleType ::= "structType" "(" Id ")" [klabel('structType)] // [ctor] 
     syntax SimpleType ::= "unionType" "(" Id ")" [klabel('unionType)] // [ctor] 
     syntax SimpleType ::= "qualifiedType" "(" Type "," K ")" [klabel('qualifiedType)] // [ctor]
     
     syntax Type ::= unqualifyType(K) [function] // takes a type, but sometimes things like maps give K
     syntax Type ::= removeStorageSpecifiers(K) [function]
     
     // these aren't real types, but are values that can appear in type contexts
     syntax SimpleType ::= "prototype" "(" Type ")" [klabel('prototype)]
     syntax SimpleType ::= "typedefType" "(" Id "," Type ")"
     syntax SimpleType ::= "variadic"

     syntax KResult ::= "dataList" "(" KList ")"
     
     // syntax Int ::= "K2Int" "(" K ")"
     syntax K ::= "sizeofType" "(" K ")" [strict] // generates a tv(size, cfg:sizeut)
     syntax K ::= "bitSizeofType" "(" K ")" [strict] // needs to be heated to top of K for struct and union types
     syntax K ::= "byteSizeofType" "(" K ")" [strict] 
     syntax Int ::= "bitsToBytes" "(" K ")" [function]
     syntax K ::= "l" "(" KLabel ")"
     syntax "l" -/- [a-zA-Z]
     // metadata "wrapper=(builtin)"
     // syntax Bool ::= Set "contains" SetItem [function]

     syntax Bool ::= K "in" List [function] // chathhorn
     syntax "in" -/- [a-zA-Z]
     
     syntax Set ::= "assignmentLabels"
     rule 
          assignmentLabels => 
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
     
     rule AllowWrite(lv(N:Int, T:KResult)) => lv(N:Int, stripConst(T:KResult)) [structural, anywhere]

     syntax Type ::= stripConst(Type) [function]
     rule stripConst(t((SetItem(Const) => .Set) _, _))
     rule stripConst(t(S:Set, T:K)) => t(S:Set, T:K)
          when notBool Const in S:Set
          [structural]
     
     syntax K ::= "bind" "(" VTList "," VTList ")"
     syntax Value ::= "tv" "(" KList "," Type ")" [latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]
     syntax Value ::= "lv" "(" KList "," Type ")"
     syntax K ::= "concretize" "(" Type "," K ")" [strict(2)] 
     syntax Value ::= "functionObject" "(" Id "," Type "," K ")"
     syntax Value ::= "functionPrototype" "(" Id "," Type ")"
     
     syntax String ::= firstChar(String) [function]
     syntax String ::= "nthChar" "(" String "," Int ")" [function]
     syntax String ::= "butFirstChar" "(" String ")" [function]
     // chathhorn
     //syntax Int ::= "charToAscii" "(" String ")" [function]
     //syntax Int ::= "asciiCharString" "(" String ")" [function]
     
     
     
     syntax KList ::=  Int "to" Int [function]
     syntax K ::= cast(K, K) [strict] // as described in 6.3 // totype, fromvalue
     context cast(_, (HOLE => reval(HOLE)))
     syntax K ::= arithInterpret(Type, BaseValue) [function] // interpret the result of arithmetic as in 6.5.4
     syntax K ::= interpret(Type, K) [function] // interpret the values of reading from mem
     
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
     
     syntax K ::= "aggregateInfo" "(" KList "," Map "," Map ")" // first map is for type, second map is for offset
     syntax Int ::= getFieldOffset(Id, K) [function] // these expect an aggregateInfo term as second argument
     syntax Type ::= getFieldType(Id, K) [function]
     
     syntax Bool ::= isArithBinConversionOp(KLabel) [function]
     syntax Bool ::= isArithUnaryOp(KLabel) [function]
     syntax K ::= "kpair" "(" K "," K ")"
     syntax Type ::= promote(K) [function] // should be K, but is Type for efficiency reasons
     syntax K ::= argPromote(K) [function]
     syntax K ::= "extractField" "(" KList "," K "," Id ")"  // bytes of struct, type, field id
     syntax K ::= "allocString" "(" Int "," String ")"
     syntax K ::= "allocWString" "(" Int "," KList ")"
     syntax K ::= "sequencePoint"
     
     syntax K ::= "handleBuiltin" "(" Id "," Type ")"
     
     syntax Int ::= min(Type) [function]
     syntax Int ::= max(Type) [function]
     syntax K ::= "alloc" "(" K "," K ")" // should be K K 
     syntax K ::= "realloc" "(" K "," K "," K "," K ")" // should be K K 
     
     // these are also used by compound literals
     syntax KResult ::= "initValue" "(" Id "," Type "," K ")"
     syntax K ::= "figureInit" "(" Id "," K "," K ")" [strict(2)] // id, type, initializer
     
          
     syntax K ::= "append" "(" Int "," Int "," Value ")" // appends a new subobject to a current object.  this is unsafe and should only be used for variadic functions
     syntax K ::= "deleteBlock" "(" Int ")" // deletes the base object from memory, given a location
     syntax K ::= "deleteSizedBlock" "(" Int "," Int ")" // deletes the base object from memory, given a location and it size (as a check)
     
     syntax Bool ::= isConcreteNumber(Int) [function]
endmodule

module COMMON-C-SETTINGS
     imports COMMON-SEMANTIC-SYNTAX 
     
     // S 6.2.5 p.35 i.15.  "The implementation shall define char to have the same range, representation, and behavior as either signed char or unsigned char.  37)... Irrespective of the choice made, char is a separate type from the other two and is not compatible with either"
     // fixme I'm not sure what consequence being a separate type entails, so for now it will just be rewritten to the chosen type
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
     
     rule [numBytes-enum]: numBytes(t(S:Set, enumType(X:Id))) => numBytes(t(S:Set, int))
     
     syntax Int ::= "cfg:mtxPlain" [function]
     rule [cfg-mtxPlain]: cfg:mtxPlain => 0
     
     syntax Type ::= "cfg:sizeut" [function]
     rule [cfg-size-t]: cfg:sizeut => t(.Set, unsigned-int)
     
     syntax Type ::= "cfg:wcharut" [function]
     rule [cfg-wchar-t]: cfg:wcharut => t(.Set, int)
     
     syntax SimpleType ::= simpleType(Type) [function]
     rule simpleType(t(_, T:K)) => T:K
     
     syntax Type ::= "cfg:largestUnsigned" [function]
     rule [cfg-largestUnsigned]: cfg:largestUnsigned => t(.Set, unsigned-long-long-int)

     syntax Int ::= "cfg:ptrsize" [function]
     rule [cfg-ptrsize]: cfg:ptrsize => 4
     
     syntax Type ::= "cfg:ptrdiffut" [function]
     rule [cfg-ptrdiff-t]: cfg:ptrdiffut => t(.Set, int)
     
     rule [min]: min(t(S:Set, enumType(_:Id))) => min(t(S:Set, int))
     rule [max]: max(t(S:Set, enumType(_:Id))) => max(t(S:Set, int))
     
     syntax Int ::= rank(Type) [function]
     
endmodule

// load common-c-sized-operations

module COMMON-NOHELPER-INCLUDE
     imports COMMON-SEMANTIC-SYNTAX
     imports COMMON-C-SETTINGS
     imports COMPAT-SYNTAX
endmodule


module COMMON-INCLUDE
     imports COMMON-NOHELPER-INCLUDE
     imports COMMON-C-HELPERS
     imports COMPAT-SYNTAX
endmodule

module COMMON-C-SEMANTICS-MISC
     imports COMMON-INCLUDE 
     
     rule loc(Base:Int, ByOff:Int, BiOff:Int) +Int Offset:Int
          => loc(Base:Int, ByOff:Int +Int Offset:Int, BiOff:Int)
          [structural, anywhere]
     rule (threadId(N:Int) +Int M:Int) +Int N':Int
          => threadId(N:Int) +Int (M:Int +Int N':Int)
          [structural, anywhere]
     rule (allocatedDuration +Int M:Int) +Int N':Int
          => allocatedDuration +Int (M:Int +Int N':Int)
          [structural, anywhere]
     rule inc(loc(N:Int, M:Int, M':Int)) => loc(N +Int 1, M, M)

     rule [unknown-loc]: CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc [structural, anywhere]

     rule [expression-loc]: ExpressionLoc(K:K, _) => K:K [structural, anywhere]

     rule [CodeLoc-k]:
          <k> CodeLoc(K:K, L:CabsLoc) => K:K ...</k>
          <currentProgramLoc> _ => L:CabsLoc </currentProgramLoc>
          [structural]
          
          
     /*@ \fromStandard{\source[n1570]{\para{6.10.6}{1}}}{
     A preprocessing directive of the form
     \cdisplay{# pragma pp-tokensoptnew-line}
\broken{where the preprocessing token \cinline{STDC} does not immediately follow pragma in the directive (prior to any macro replacement)} causes the implementation to behave in an implementation-defined manner. The behavior might cause translation to fail or cause the translator or the resulting program to behave in a non-conforming manner. Any such pragma that is not recognized by the implementation is ignored.
     }*/
     rule [Pragma]:
          <k> Pragma(_:K) => .K ...</k>
          [structural]
          
     rule AttributeWrapper(K:K, _) => K:K [structural, anywhere]
     
     rule loc(Base:Int, Offset:Int, BitOffset:Int)
          => loc(Base:Int, Offset:Int +Int BitOffset:Int /Int numBitsPerByte, BitOffset:Int %Int numBitsPerByte)
          when BitOffset:Int >=Int numBitsPerByte
          [structural, anywhere]
     
     rule Identifier("___missing_field_name") => #NoName [structural, anywhere]
endmodule

module COMMON-C-SEMANTICS
     imports COMMON-INCLUDE 
     
     imports COMMON-C-SEMANTICS-MISC
     imports COMMON-C-EXPRESSIONS
     imports COMMON-C-STATEMENTS
     imports COMMON-C-DECLARATIONS
     imports COMMON-C-TYPING
     
     // TODO(chathhorn): the klabel attribute doesn't seem to work on things
     // of sort Bag ...?
     //syntax Bag ::= "eval" "(" K ")" [klabel('eval)]
     syntax Bag ::= "eval" "(" K "," KList "," String "," Int ")"
     syntax K ::= "callMain" "(" Int "," K ")" [klabel('callMain)]
     syntax K ::= "incomingArguments" "(" KList ")" [klabel('incomingArguments)]
     
     syntax KLabel ::= "TranslationUnitName" "(" String ")" [klabel('TranslationUnitName)]

endmodule
