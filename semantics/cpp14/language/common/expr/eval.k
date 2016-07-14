module CPP-EXPR-EVAL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule reval(lv(Loc::SymLoc, T:CPPArrayType)
          => convertArray(lv(Loc, T)))


endmodule
