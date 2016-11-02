module CPP-SETTINGS
     imports CPP-TYPING-SYNTAX

     rule underlyingType(char) => signed-char
     rule underlyingType(char16_t) => unsigned-short
     rule underlyingType(char32_t) => unsigned
     rule underlyingType(wchar_t) => int

     rule size_t => unsigned
     rule ptrdiff_t => int

endmodule

module CPP-COMPILER-SETTINGS
     imports CPP-SETTINGS-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule cfg:maxNewSize => max(type(size_t))
endmodule
