module CPP-CITATIONS
  imports CITATIONS-SYNTAX

  rule sourceReferences("IMPL++-CCV3", "C++14") => ListItem(reference("4.7", "3"))
  rule sourceReferences("UB++-EIO1", "C++14") => ListItem(reference("4.1", "2.6"))
  rule sourceReferences("DR++-EIO1", "C++ Defect Reports") => ListItem(reference("232",""))
  rule sourceReferences("UB++-CCV1", "C++14") => ListItem(reference("5", "4"))
  rule sourceReferences("UB++-CCV2", "C++14") => ListItem(reference("4.8", "1")) ListItem(reference("5", "4"))
  rule sourceReferences("UB++-CCV4", "C++14") => ListItem(reference("4.8", "1"))
  rule sourceReferences("UB++-CCV5", "C++14") => ListItem(reference("4.9", "1"))
  rule sourceReferences("UB++-CCV6", "C++14") => ListItem(reference("4.9", "2"))
  rule sourceReferences("UB++-CEC1", "C++14") => ListItem(reference("5.2.9", "10"))
  rule sourceReferences("UB++-CEC2", "C++14") => ListItem(reference("5.2.9", "11"))
  rule sourceReferences("UB++-CEC3", "C++14") => ListItem(reference("5.2.9", "12"))
  rule sourceReferences("UB++-CEA1", "C++14") => ListItem(reference("5.7", "4"))
  rule sourceReferences("UB++-CEMX1", "C++14") => ListItem(reference("5.6", "4"))
  rule sourceReferences("UB++-CEMX2", "C++14") => ListItem(reference("5.6", "4"))
  rule sourceReferences("UB++-CEMX3", "C++14") => ListItem(reference("5.6", "4"))
  rule sourceReferences("UB++-CEB1", "C++14") => ListItem(reference("5.8", "2"))
  rule sourceReferences("IMPL++-CEB2", "C++14") => ListItem(reference("5.8", "3"))
  rule sourceReferences("ILF-TIN1", "C++14") => ListItem(reference("18.6.1.1", "11"))
  rule sourceReferences("ILF-TIN2", "C++14") => ListItem(reference("18.6.1.1", "11"))
endmodule
