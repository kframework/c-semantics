module C-SETTINGS
     imports C-SYNTAX
     imports C-SEMANTIC-SYNTAX 
     
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

