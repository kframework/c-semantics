module CPP-MEMORY-READING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= read(SymLoc, Trace, CPPType) [klabel(readCpp)]
                    | readBytes(SymLoc, Int, CPPType) [klabel(readBytesCpp)]

     syntax PRVal ::= interpret(PRVal) [function, klabel(interpretCpp)]

endmodule

module CPP-MEMORY-READING
     imports CPP-MEMORY-READING-SYNTAX
     imports INT
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule read(Loc::SymLoc, Tr::Trace, T::CPPType)
          => concretize(readBytes(stripProv(Loc), byteSizeofType(T), T), Loc, Tr, utype(T))

     syntax Expr ::= concretize(KItem, SymLoc, Trace, CPPType) [klabel(concretizeCpp), strict(1)]

     rule concretize(dataList(L::List), _, Tr::Trace, T::CPPType)
          => interpret(prv(joinBytes(L), Tr, prvalType(T)))
          requires notBool isCPPClassType(T)

     rule concretize(_, Loc::SymLoc, Tr::Trace, t(... st: classType(...)) #as T::CPPType)
          => prv(Loc, Tr, prvalType(T))

     rule interpret(prv(encodedPtr(L:SymLoc, 0, To::Int), Tr::Trace, t(... st: pointerType(...)) #as T::CPPType)) => prv(L, Tr, T)
          requires To ==Int (cfg:ptrsize *Int cfg:bitsPerByte)

     rule interpret(prv(encodedValue(F:Float, 0, To::Int), Tr::Trace, t(... st: _:CPPSimpleFloatingType) #as T::CPPType)) => prv(F, Tr, T)
          requires isFullFloat(F, To)

     rule interpret(prv(I:Int, Tr::Trace, cppIntegerType #as T::CPPType))
          => #if max(T) >=Int I #then prv(I, Tr, T) #else interpret(prv(I -Int (1 <<Int absInt(bitSizeofType(T))), Tr, T)) #fi

     rule interpret(prv(encodedPtr(nullptrVal, 0, To::Int), Tr::Trace, t(... st: nullptr_t) #as T::CPPType)) => prv(nullptrVal, Tr, T)
          requires To ==Int (cfg:ptrsize *Int cfg:bitsPerByte)

     rule interpret(prv(encodedPtr(NullMemberFunctionPointer, 0, To::Int), Tr::Trace, t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T::CPPType)) => prv(NullMemberFunctionPointer, Tr, T)
          requires To ==Int (cfg:memberFunctionPtrSize *Int cfg:bitsPerByte)

     rule interpret(prv(encodedPtr(NullMemberPointer, 0, To::Int), Tr::Trace, t(... st: memberPointerType(...)) #as T::CPPType)) => prv(NullMemberPointer, Tr, T)
          requires notBool(isCPPMemberFunctionPointerType(T))
               andBool To ==Int (cfg:memberDataPtrSize *Int cfg:bitsPerByte)

     rule interpret(prv(0, Tr::Trace, t(... st: nullptr_t) #as T::CPPType)) => prv(nullptrVal, Tr, T)

     rule interpret(prv(0, Tr::Trace, t(... st: pointerType(...)) #as T::CPPType)) => prv(NullPointer, Tr, T)

     rule interpret(prv(0, Tr::Trace, t(... st: pointerType(...)) #as T::CPPType)) => prv(NullPointer, Tr, T)

     rule interpret(prv(0, Tr::Trace, t(... st: memberPointerType(...)) #as T::CPPType)) => prv(#if isCPPMemberFunctionPointerType(T) #then NullMemberFunctionPointer #else NullMemberPointer #fi, Tr, T)

     rule interpret(prv(I:Int, Tr::Trace, cppEnumType #as T::CPPType)) => interpretEnum(interpret(prv(I, Tr, underlyingType(T))), T)

     rule interpret(V::PRVal) => V [owise]

     syntax PRVal ::= interpretEnum(PRVal, CPPType)

     rule interpretEnum(prv(I:Int, Tr::Trace, cppIntegerType #as T::CPPType), cppEnumType #as E::CPPType) => prv(I, Tr, E)

endmodule
