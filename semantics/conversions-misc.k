module C-CONVERSIONS-INCLUDE
     syntax Bool ::= hasSameSignedness(Type, Type) [function]
     syntax Type ::= correspondingUnsignedType(Type) [function] 
endmodule

module C-CONVERSIONS-HELPERS
     imports C-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-HELPERS
     imports C-COMPAT-SYNTAX
     imports C-CONFIGURATION
     
     
     rule [hasSameSignedness]: 
          hasSameSignedness(T:KResult, T':KResult)
          => (hasSignedIntegerType(T:KResult)
                    andBool hasSignedIntegerType(T':KResult))
               orBool (hasUnsignedIntegerType(T:KResult)
                    andBool hasUnsignedIntegerType(T':KResult))
     
     rule [correspondingUnsigned-int]: 
          correspondingUnsignedType(t(S:Set, int))
          => t(S:Set, unsigned-int)
     rule [correspondingUnsigned-long-int]: 
          correspondingUnsignedType(t(S:Set, long-int))
          => t(S:Set, unsigned-long-int)
     rule [correspondingUnsigned-long-long-int]: 
          correspondingUnsignedType(t(S:Set, long-long-int))
          => t(S:Set, unsigned-long-long-int)
endmodule

module C-CONVERSIONS-MISC
     imports C-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-HELPERS
     imports C-COMPAT-SYNTAX
     imports C-CONFIGURATION
     

     // fixme not sure about this
     // interpret is used to "cast" values read from memory
     // shouldn't need to do the < min one since values start positive
     syntax K ::= "interpret-aux" "(" Type "," K ")" [function]
     
     rule [interpret-start]:
          interpret(T:Type, piece(N:Int, _)) => interpret-aux(T, N)
     
     rule [interpret-done]:
          interpret-aux(T:Type, I:Int) => tv(I, T)
          when (min(T) <=Int I) 
               andBool (max(T) >=Int I)
               andBool hasIntegerType(T)
     rule [interpret-too-big]:
          interpret-aux(T:Type, I:Int) 
          => interpret-aux(T, I:Int -Int (2 ^Int absInt(numBits(T))))
          when (I:Int >Int max(T))
               andBool hasIntegerType(T)
     rule [interpret-too-little]:
          interpret-aux(T:Type, I:Int) 
          => interpret-aux(T, I:Int +Int (2 ^Int absInt(numBits(T))))
          when (I:Int <Int min(T))
               andBool hasIntegerType(T)
          
     rule [arithInterpret-done]:
          arithInterpret(T:Type, I:Int) => tv(I, T)
          when (min(T) <=Int I) 
               andBool (max(T) >=Int I)
               andBool hasIntegerType(T)
          
     rule [arithInterpret-unknown]:
          arithInterpret(T:Type, piece(unknown(N:Int), N:Int)) 
          => tv(piece(unknown(N:Int), N:Int), T)
          
     // these could be so much better...
     rule ~Bits X:Int => ~Int X
     rule [bnot-unknown]: 
          ~Bits piece(unknown(Len:Int), Len:Int) 
          => piece(unknown(Len:Int), Len:Int)
     
     rule X:Int /Bits Y:Int => X /Int Y

     rule X:Int xorBits Y:Int => X xorInt Y
     rule [xor-unknown-right]: 
          _:Bits xorBits piece(unknown(Len:Int), Len:Int) 
          => piece(unknown(Len:Int), Len:Int)
     rule [xor-unknown-left]: 
          piece(unknown(Len:Int), Len:Int) xorBits _:Bits 
          => piece(unknown(Len:Int), Len:Int)

     rule X:Int |Bits Y:Int => X |Int Y
     rule [or-unknown-right]: 
          _:Bits |Bits piece(unknown(Len:Int), Len:Int) 
          => piece(unknown(Len:Int), Len:Int)
     rule [or-unknown-left]: 
          piece(unknown(Len:Int), Len:Int) |Bits _:Bits 
          => piece(unknown(Len:Int), Len:Int)

     rule X:Int &Bits Y:Int => X &Int Y
     rule [and-unknown-zero-right]:
          N:Int &Bits piece(unknown(Len:Int), Len)
          => 0
          when N ==Int 0 
     rule [and-unknown-right]:
          N:Int &Bits piece(unknown(Len:Int), Len)
          => 0
          when N =/=Int 0 
     rule [and-unknown-zero-left]:
          piece(unknown(Len:Int), Len) &Bits N:Int
          => 0
          when N ==Int 0 
     rule [and-unknown-left]:
          piece(unknown(Len:Int), Len) &Bits N:Int
          => 0
          when N =/=Int 0
     
     // fixme
     rule [arithInterpret-float]: 
          arithInterpret(t(S:Set, T:K), F:Float) => tv(F:Float, t(S:Set, T:K))
          when (T:K ==K double)
               orBool (T:K ==K float)
               orBool (T:K ==K long-double)
     // signed arithmetic isn't supposed to overflow
     rule [arithInterpret-unsigned-big]:
          arithInterpret(T:Type, I:Int) => tv(I:Int %Int (max(T) +Int 1), T)
          when hasUnsignedIntegerType(T)
               andBool (I:Int >Int max(T))
     rule [arithInterpret-unsigned-small]:
          arithInterpret(T:Type, I:Int) 
          => arithInterpret(T, (I %Int (max(T) +Int 1)) +Int (max(T) +Int 1))
          // must be like this so ((unsigned int)(~((unsigned int)~0)) != 0)
          // will work, but not sure why
          when hasUnsignedIntegerType(T)
               andBool (I:Int <Int min(T))

     rule unsignedIntegerTypes => 
          SetItem(bool)
          SetItem(unsigned-char)
          SetItem(unsigned-short-int)
          SetItem(unsigned-int)
          SetItem(unsigned-long-int)
          SetItem(unsigned-long-long-int)

     rule signedIntegerTypes => 
          SetItem(char)
          SetItem(signed-char)
          SetItem(short-int)
          SetItem(int)
          SetItem(long-int)
          SetItem(long-long-int)

endmodule
