module CPP-SETTINGS
     imports CPP-SETTINGS-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule underlyingType(char) => signed-char
     rule underlyingType(char16_t) => unsigned-short
     rule underlyingType(char32_t) => unsigned
     rule underlyingType(wchar_t) => int

     rule size_t => unsigned
     rule ptrdiff_t => int

     rule cfg:memberDataPtrSize => 4
     rule cfg:memberFunctionPtrSize => 8
     rule cfg:memberDataPtrAlign => 4
     rule cfg:memberFunctionPtrAlign => 8
     rule cfg:alignofReference => 4
     rule cfg:alignofNullPtrT => 4

endmodule

module CPP-COMPILER-SETTINGS
     imports CPP-SETTINGS-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule cfg:maxNewSize => max(type(size_t))
endmodule
