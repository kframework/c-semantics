module CPP-SYMLOC-SORTS
     imports SYMLOC-SORTS
     syntax MemberPtr

     syntax EnvEntry

     syntax DefaultArgumentsResult
endmodule

module CPP-SYMLOC-SYNTAX
     imports CPP-SYMLOC-SORTS
     imports SYMLOC-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax SymBase ::= bnew(Int, CPPType, Set, Duration) [function, klabel(bnewCPP)]

     syntax SymBase ::= bnew(Int, CPPType, Set, LinkDuration) [function, klabel(bnewCPP2)]

     syntax SymLoc ::= lnew(SymBase) [function, klabel(lnewCpp)]

     syntax Bool ::= ifFromArrayInBounds(SymLoc, CPPType, Int) [function, klabel(ifFromArrayInBoundsCPP)]

     syntax MemberPtr ::= "NullMemberPointer"
                        | MemberFunctionPtr

     syntax MemberFunctionPtr ::= "NullMemberFunctionPointer"
                                | memberPointer(Class, CId, CPPType)

     syntax ValResult ::= dataMemberValue(MemberPtr, Trace, CPPType)

     syntax MemberPtr ::= derivedClassSuperobject(MemberPtr, CPPType, CPPType) [function]
                        | baseClassSubobject(MemberPtr, base: CPPType, derived: CPPType) [function]

     syntax SymLoc ::= baseClassSubobject(SymLoc, base: CPPType, derived: CPPType) [function]
                     | derivedClassSuperobject(SymLoc, CPPType, CPPType) [function]

     syntax Bool ::= containsMember(MemberPtr, CPPType) [function]
                   | isBaseClassSubobject(SymLoc, CPPType, CPPType) [function]

     syntax EnvEntry ::= envEntry(base: SymBase, using: Bool, defaultArgs: DefaultArgumentsResult)

     syntax MemberBase ::= memberBase(CId, CId, CPPType)

     syntax SymBase ::= MemberBase

     syntax DefaultArgumentsResult ::= NoDefArgs()

     syntax SymBase ::= getBase(EnvEntry) [function, klabel(getEnvEntryBase)]

endmodule

module CPP-SYMLOC
     imports CPP-SYMLOC-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports SETTINGS-SYNTAX
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule bnew(I::Int, T::CPPType, Mods::Set, D::Duration)
          => obj(I, getAlignas(T, Mods), D)

     rule bnew(I::Int, T::CPPType, Mods::Set, D::LinkDuration)
          => obj(I, getAlignas(T, Mods), D)

     rule lnew(Base::SymBase)
          => loc(Base, 0)

     syntax Bool ::= #ifFromArrayInBounds(K, Int) [function, klabel(#ifFromArrayInBoundsCPP)]

     rule ifFromArrayInBounds(Loc::SymLoc, T::CPPType, I::Int) => #ifFromArrayInBounds(getFromArray(Loc), byteSizeofType(innerType(T)) *Int I)

     rule #ifFromArrayInBounds(fromArray(Offset::Int, Len::Int, _), NewOffset::Int) => Offset +Int NewOffset >=Int 0 andBool Offset +Int NewOffset <=Int Len

     rule #ifFromArrayInBounds(.K, _) => true

     rule getBase(envEntry(... base: B::SymBase)) => B

     rule baseClassSubobject(NullPointer, _, _) => NullPointer

     rule baseClassSubobject(NullMemberPointer, _, _) => NullMemberPointer

     rule baseClassSubobject(NullMemberFunctionPointer, _, _) => NullMemberFunctionPointer

     rule derivedClassSuperobject(NullPointer, _, _) => NullPointer

     rule derivedClassSuperobject(NullMemberPointer, _, _) => NullMemberPointer

     rule derivedClassSuperobject(NullMemberFunctionPointer, _, _) => NullMemberFunctionPointer

     rule baseClassSubobject(L:SymLoc, t(... st: classType(B::Class)), t(... st: classType(D::Class)))
          => L +bytes getBaseClassOffset(B, D) /Int cfg:bitsPerByte
          requires L =/=K NullPointer

endmodule
