module CPP-COMPILER-SETTINGS
     imports CPP-SETTINGS-SYNTAX
     imports BOOL-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule cfg:maxNewSize => max(type(size_t))
     rule cfg:unwindBeforeTerminate => false
endmodule
