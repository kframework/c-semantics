module C-TYPING-MACROS
     imports C-TYPING-MACROS-SYNTAX
     rule signedCharType => char #Or signed-char [macro]
     rule unsignedCharType => unsigned-char [macro]
endmodule

module C-SETTINGS
     imports BOOL
     imports INT
     imports K-IO
     imports STRING
     imports BITS-SYNTAX
     imports ERROR-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX

     syntax SimpleSignedCharType ::= SimpleCharType
     syntax SimpleSignedType ::= SimpleEnumType

     rule cfg:bitsPerByte => 8

     rule cfg:sizeofBool => 1
     rule cfg:sizeofSignedChar => 1
     rule cfg:sizeofShortInt => 2
     rule cfg:sizeofInt => 4
     rule cfg:sizeofLongInt => 8
     rule cfg:sizeofLongLongInt => 8
     rule cfg:sizeofOversizedInt => 16
     rule cfg:sizeofFloat => 4
     rule cfg:sizeofDouble => 8
     rule cfg:sizeofLongDouble => 16
     rule cfg:sizeofOversizedFloat => 16
     rule cfg:thrdut => int

     rule cfg:precisionofFloat => 24
     rule cfg:precisionofDouble => 53
     rule cfg:precisionofLongDouble => 65
     rule cfg:precisionofOversizedFloat => 113
     rule cfg:exponentofFloat => 8
     rule cfg:exponentofDouble => 11
     rule cfg:exponentofLongDouble => 15
     rule cfg:exponentofOversizedFloat => 15

     rule cfg:largestUnsigned => unsigned-long-long-int

     rule cfg:mtxPlain => 0

     rule cfg:sizeut => unsigned-long-int
     rule cfg:wintut => unsigned-int
     rule cfg:wcharut => int
     rule cfg:ptrsize => 8
     rule cfg:ptrdiffut => long-int

     rule cfg:alignofBool => 1
     rule cfg:alignofSignedChar => 1
     rule cfg:alignofShortInt => 2
     rule cfg:alignofInt => 4
     rule cfg:alignofLongInt => 8
     rule cfg:alignofLongLongInt => 8
     rule cfg:alignofOversizedInt => 16
     rule cfg:alignofFloat => 4
     rule cfg:alignofDouble => 8
     rule cfg:alignofLongDouble => 16
     rule cfg:alignofOversizedFloat => 16
     rule cfg:alignofPointer => 8
     // Max of the above.
     rule cfg:defaultMaxAlign => 16
     rule cfg:alignofMalloc => cfg:defaultMaxAlign

     rule cfg:intToPointer(0, _) => NullPointer
     rule cfg:intToPointer(_, _) => trap [owise]
     rule cfg:pointerToInt(NullPointer, _) => 0
     rule cfg:pointerToInt(L:SymLoc, _) => L [owise]

     rule cfg:maxHeapBound => (1 <<Int 32) -Int 2

     rule isErrorRecovery => true
     rule hasLint => false

     rule cfg:stackSize(_, _) => 0

     rule cfg:reservedKeywordSupported(_) => true

     // Error Recovery
     rule HALT ~> _:Error => .K
          requires isErrorRecovery
     rule HALT ~> recoverFromError(K:K) => K
          requires isErrorRecovery

     rule reportError(ErrorMsg(E::ErrorCategory, ErrorCode::String, Description::String, _), _, _, C::CabsLoc, _, _) => #write(2, printLocation(C) +String ": " +String "warning: " +String Description +String printCategory(E))

     syntax String ::= printLocation(CabsLoc) [function]
                     | printCategory(ErrorCategory) [function]

     rule printLocation(UnknownCabsLoc) => "<unknown>"
     rule printLocation(CabsLoc(File::String, _, Line::Int, Column::Int, _)) => File +String ":" +String Int2String(Line) +String ":" +String Int2String(Column)
     rule printCategory(Undef(_)) => " (Undefined behavior)\n"
     rule printCategory(Unspec(_)) => " (Unspecified value or behavior)\n"
     rule printCategory(Impl(_)) => " (Implementation defined behavior)\n"
     rule printCategory(Cond()) => " (Conditionally-supported behavior)\n"
     rule printCategory(Ill()) => " (Ill-formed program)\n"
     rule printCategory(Drafting(_)) => " (Behavior underspecified by standard)\n"
     rule printCategory(Constraint()) => " (Constraint violation)\n"
     rule printCategory(Syntax(_)) => " (Syntax error)\n"

endmodule

