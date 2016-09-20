module CPP-EXECUTION-CONVERSION
     imports CPP-CONVERSION-SYNTAX
     imports CPP-SYNTAX

     context ConvertType(_, (HOLE:Expr => reval(HOLE))) [result(PRVal)]
     rule ConvertType(T::CPPType, R:PRVal) => convertType(T, R)

endmodule
