module CPP-SETTINGS
     imports CPP-TYPING-SYNTAX

     rule underlyingType(char) => signed-char
     rule underlyingType(char16_t) => unsigned-short
     rule underlyingType(char32_t) => unsigned
     rule underlyingType(wchar_t) => int

     rule size_t => unsigned

endmodule
