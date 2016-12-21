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
endmodule
