#define _XOPEN_SOURCE 700

#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wcomment"
#elif defined __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomment"
#endif

#include "clang/AST/ASTConsumer.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendAction.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/Support/CommandLine.h"

#include "GetKastVisitor.h"
#include "ClangKast.h"

#ifdef __GNUC__
#pragma GCC diagnostic pop
#elif defined __clang__
#pragma clang diagnostic pop
#endif

#include <cstdio>
#include <vector>
#include <fcntl.h>
#include <unistd.h>

#include <iostream>

using namespace std;
using namespace clang;
using namespace clang::tooling;
namespace cl = llvm::cl;

// *** Command line setup ***

// Apply a custom category to all command-line options so that they are the
// only ones displayed.
static cl::OptionCategory KastOptionCategory("K++ parser options");

// CommonOptionsParser declares HelpMessage with a description of the common
// command-line options related to the compilation database and input files.
// It's nice to have this help message in all tools.
static cl::extrahelp CommonHelp(CommonOptionsParser::HelpMessage);

static cl::opt<bool> Kore("kore", cl::desc("Output kore instead of kast."), cl::cat(KastOptionCategory));
static cl::opt<bool> Cparser("cparser", cl::desc("Parse C instead of C++."), cl::cat(KastOptionCategory));
static cl::opt<bool> NoLocation("no-location", cl::desc("Do not emit location information (CabsLoc)."), cl::cat(KastOptionCategory));

bool cparser() {
  return Cparser;
};

bool noLocation() {
  return NoLocation;
}

// *** Sort to string ***

std::ostream& operator<<(std::ostream & os, const Sort & sort) {
  if (Kore) os << "Sort";
  switch (sort) {
    case Sort::ACCESSSPECIFIER:       os << "AccessSpecifier"; break;
    case Sort::AEXPR:                 os << "AExpr"; break;
    case Sort::ASTMT:                 os << "AStmt"; break;
    case Sort::ATYPE:                 os << "AType"; break;
    case Sort::ATYPERESULT:           os << "ATypeResult"; break;
    case Sort::AUTOSPECIFIER:         os << "AutoSpecifier"; break;
    case Sort::BASESPECIFIER:         os << "BaseSpecifier"; break;
    case Sort::BOOL:                  os << "Bool"; break;
    case Sort::BRACEINIT:             os << "BraceInit"; break;
    case Sort::CABSLOC:               os << "CabsLoc"; break;
    case Sort::CAPTUREDEFAULT:        os << "CaptureDefault"; break;
    case Sort::CAPTUREKIND:           os << "CaptureKind"; break;
    case Sort::CAPTURE:               os << "Capture"; break;
    case Sort::CATCHDECL:             os << "CatchDecl"; break;
    case Sort::CHARKIND:              os << "CharKind"; break;
    case Sort::CID:                   os << "CId"; break;
    case Sort::CLASSKEY:              os << "ClassKey"; break;
    case Sort::CONSTANT:              os << "Constant"; break;
    case Sort::CTORINIT:              os << "CtorInit"; break;
    case Sort::CVALUE:                os << "CValue"; break;
    case Sort::DECLARATOR:            os << "Declarator"; break;
    case Sort::DECL:                  os << "Decl"; break;
    case Sort::DESTRUCTORID:          os << "DestructorId"; break;
    case Sort::DTYPE:                 os << "DType"; break;
    case Sort::ENUMERATOR:            os << "Enumerator"; break;
    case Sort::EXCEPTIONSPEC:         os << "ExceptionSpec"; break;
    case Sort::EXPRESSIONLIST:        os << "ExpressionList"; break;
    case Sort::EXPRLOC:               os << "ExprLoc"; break;
    case Sort::EXPR:                  os << "Expr"; break;
    case Sort::FLOAT:                 os << "Float"; break;
    case Sort::FUNCTIONSPECIFIER:     os << "FunctionSpecifier"; break;
    case Sort::INIT:                  os << "Init"; break;
    case Sort::INT:                   os << "Int"; break;
    case Sort::K:                     os << "K"; break;
    case Sort::KITEM:                 os << "KItem"; break;
    case Sort::KRESULT:               os << "KResult"; break;
    case Sort::LIST:                  os << "List"; break;
    case Sort::MODIFIER:              os << "Modifier"; break;
    case Sort::NAME:                  os << "Name"; break;
    case Sort::NAMESPACE:             os << "Namespeace"; break;
    case Sort::NNS:                   os << "NNS"; break;
    case Sort::NNSSPECIFIER:          os << "NNSSpecifier"; break;
    case Sort::NONAME:                os << "NoName"; break;
    case Sort::OPID:                  os << "OpId"; break;
    case Sort::QUALIFIER:             os << "Qualifier"; break;
    case Sort::REFQUALIFIER:          os << "RefQualifier"; break;
    case Sort::RESOLVEDEXPR:          os << "ResolvedExpr"; break;
    case Sort::RVALUE:                os << "RValue"; break;
    case Sort::SET:                   os << "Set"; break;
    case Sort::SIMPLEFUNCTIONTYPE:    os << "SimpleFunctionType"; break;
    case Sort::SIMPLEFIXEDARRAYTYPE:  os << "SimpleFixedArrayType"; break;
    case Sort::SIMPLEINCOMPLETEARRAYTYPE:  os << "SimpleIncompleteArrayType"; break;
    case Sort::SIMPLEVARIABLEARRAYTYPE:  os << "SimpleVariableArrayType"; break;
    case Sort::SIMPLEPOINTERTYPE:     os << "SimplePointerType"; break;
    case Sort::SIMPLETYPE:            os << "SimpleType"; break;
    case Sort::SIMPLEUTYPE:           os << "SimpleUType"; break;
    case Sort::SPECIFIER:             os << "Specifier"; break;
    case Sort::SPECIFIERELEM:         os << "SpecifierElem"; break;
    case Sort::STMT:                  os << "Stmt"; break;
    case Sort::STORAGECLASSSPECIFIER: os << "StorageClassSpecifier"; break;
    case Sort::STRICTLIST:            os << "StrictList"; break;
    case Sort::STRICTLISTRESULT:      os << "StrictListResult"; break;
    case Sort::STRING:                os << "String"; break;
    case Sort::STRINGLITERAL:         os << "StringLiteral"; break;
    case Sort::TAG:                   os << "Tag"; break;
    case Sort::TEMPLATEARGUMENT:      os << "TemplateArgument"; break;
    case Sort::TEMPLATEPARAMETER:     os << "TemplateParameter"; break;
    case Sort::THIS:                  os << "This"; break;
    case Sort::TYPE:                  os << "Type"; break;
    case Sort::TYPEID:                os << "TypeId"; break;
    case Sort::TYPESPECIFIER:         os << "TypeSpecifier"; break;
    case Sort::UNNAMEDCID:            os << "UnnamedCId"; break;
    case Sort::UTYPE:                 os << "UType"; break;
    case Sort::VARIADIC:              os << "Variadic"; break;
  }
  if (Kore) os << "{}";
  return os;
}


// *** Kast::Nodes ***

vector<unique_ptr<const Kast::Node>> Kast::Nodes;

// *** Kast::Node ***

string Kast::Node::makeKLabel(const string & label) {
  if (Kore) {
    return "Lbl" + escapeKLabel(label) + "{}";
  } else {
    return "`" + label + "`";
  }
}

string Kast::Node::escapeKLabel(const string & label) {
  string res;
  for (char c : label) {
    const char * subst = NULL;
    switch (c) {
      case ' ':  subst = "Spce'"; break;
      case '!':  subst = "Bang'"; break;
      case '"':  subst = "Quot'"; break;
      case '#':  subst = "Hash'"; break;
      case '$':  subst = "Dolr'"; break;
      case '%':  subst = "Perc'"; break;
      case '&':  subst = "And'" ; break;
      case '\'': subst = "Apos'"; break;
      case '(':  subst = "LPar'"; break;
      case ')':  subst = "RPar'"; break;
      case '*':  subst = "Star'"; break;
      case '+':  subst = "Plus'"; break;
      case ',':  subst = "Comm'"; break;
      case '.':  subst = "Stop'"; break;
      case '/':  subst = "Slsh'"; break;
      case ':':  subst = "Coln'"; break;
      case ';':  subst = "SCln'"; break;
      case '<':  subst = "-LT-'"; break;
      case '=':  subst = "Eqls'"; break;
      case '>':  subst = "-GT-'"; break;
      case '?':  subst = "Ques'"; break;
      case '@':  subst = "-AT-'"; break;
      case '[':  subst = "LSqB'"; break;
      case '\\': subst = "Bash'"; break;
      case ']':  subst = "RSqB'"; break;
      case '^':  subst = "Xor-'"; break;
      case '_':  subst = "Unds'"; break;
      case '`':  subst = "BQuo'"; break;
      case '{':  subst = "LBra'"; break;
      case '|':  subst = "Pipe'"; break;
      case '}':  subst = "RBra'"; break;
      case '~':  subst = "Tild'"; break;
    }

    if (subst) {
      if (res.length() > 0 && res.back() == '\'')
        res.pop_back();
      else res.push_back('\'');
      res += subst;
    } else {
      res.push_back(c);
    }

  }
  return res;
}

// *** Kast::KApply ***

void Kast::KApply::print(Sort parentSort, function<void (Sort)> printChild) const {
  if (Kore && sort != parentSort) {
      if (parentSort == Sort::K) {
        cout << "kseq{}(";
        if (sort != Sort::KITEM) {
          cout << "inj{" << sort << ", " << Sort::KITEM << "}(";
        }
      } else {
        cout << "inj{" << sort << ", " << parentSort << "}(";
      }
  }

  cout << makeKLabel(label) << "(";
  if (!Kore && sig.size() == 0) {
    cout << ".KList";
  }

  bool first = true;
  for (Sort s : sig) {
    if (!first) cout << ",";
    first = false;
    printChild(s);
  }
  cout << ")";

  if (Kore && sort != parentSort) {
    if (parentSort == Sort::K) {
      if (sort != Sort::KITEM) {
        cout << ")";
      }
      cout << ", dotk{}())";
    } else {
      cout << ")";
    }
  }
}

// *** Kast::KToken ***

string Kast::KToken::toKString(const string & s) {
  return string(Kore ? escape(s) : "\"" + escape(s) + "\"");
}

string Kast::KToken::toKString(bool b) {
  return string(b ? "true" : "false");
}

string Kast::KToken::toKString(llvm::APInt i) {
  return string(i.toString(10, false));
}

string Kast::KToken::toKString(unsigned i) {
  char buf[11];
  sprintf(buf, "%d", i);
  return string(buf);
}

string Kast::KToken::toKString(unsigned long long s) {
  char name[21];
  sprintf(name, "%llu", s);
  return string(name);
}

string Kast::KToken::toKString(llvm::APFloat f) {
  unsigned precision = f.semanticsPrecision(f.getSemantics());
  const unsigned numBytes = 6      // max length of signed short
                          + 4      // -1.E
                          + 3 + 11 // p4294967295x16
                          + 1      // null byte
                          + precision;
  char result[numBytes] = {0}, suffix[14] = {0};
  SmallVector<char, 80> buf;
  f.toString(buf, 0, 0);
  const unsigned range = [&]{
      if (precision == 24)
        return 8;
      if (precision == 53)
        return 11;
      if (precision == 64)
        return 15;
      throw std::logic_error("Unexpected precision: " + std::to_string(precision));
  }();
  if (precision == 64)
    precision = 65;
  sprintf(suffix, "p%ux%d", precision, range);
  strncpy(result, buf.data(), buf.size());
  strcat(result, suffix);
  return string(result);
}

void Kast::KToken::print(Sort parentSort, function<void (Sort)>) const {
  if (Kore) {
    cout << "\\dv{" << sort << "}(\"" << escape(value) << "\")";
  } else {
    cout << "#token(\"" << escape(value) << "\", \"" << sort << "\")";
  }
}

string Kast::KToken::escape(const string & str) {
  string res;
  for(char c : str) {
    switch (c) {
      case '"':  res += "\\\""; break;
      case '\\': res += "\\\\"; break;
      case '\n': res += "\\n";  break;
      case '\t': res += "\\t";  break;
      case '\r': res += "\\r";  break;
      default:
        if (c >= 32 && c < 127) {
          res.push_back(c);
        } else {
          char buf[5];
          sprintf(buf, "\\x%02hhx", (unsigned char)c);
          res += buf;
        }
    }
  }
  return res;
}

// *** Kast::KSequence

void Kast::KSequence::print(Sort parentSort, function<void (Sort)> printChild) const {
  if (size == 0) {
    cout << (Kore ? "dotk{}()" : ".K");
  }
  for (int i = 0; i < size; i++) {
    printChild(Sort::KITEM);
    if (i != size - 1) {
      cout << (Kore ? ", " : "~>");
    }
  }
}

// *** Kast ***


void Kast::print() { print(Sort::K, 0); }

int Kast::print(Sort parentSort, int idx) {
  if (idx >= Nodes.size() || !Nodes[idx])
    throw logic_error("parse error");

  Nodes[idx]->print(parentSort, [&idx](Sort sort) { idx = print(sort, idx + 1); });

  return idx;
}

// *** GetKastConsumer ***

class GetKastConsumer : public clang::ASTConsumer {
public:
  explicit GetKastConsumer(ASTContext *Context, llvm::StringRef InFile)
    : Visitor(Context, InFile) { }
  virtual void HandleTranslationUnit(clang::ASTContext &Context) {
    Visitor.TraverseDecl(Context.getTranslationUnitDecl());
  }

private:
  GetKastVisitor Visitor;
};

// *** GetKastAction ***

class GetKastAction : public clang::ASTFrontendAction {
public:
  virtual unique_ptr<clang::ASTConsumer> CreateASTConsumer(
    clang::CompilerInstance &Compiler, llvm::StringRef InFile) {
    return unique_ptr<clang::ASTConsumer>(
      new GetKastConsumer(&Compiler.getASTContext(), InFile));
  }
};

// *** main ***

int main(int argc, const char **argv) {
  CommonOptionsParser OptionsParser(argc, argv, KastOptionCategory);
  ClangTool Tool(OptionsParser.getCompilations(),
                 OptionsParser.getSourcePathList());
  try {
    if (int r = Tool.run(newFrontendActionFactory<GetKastAction>().get())) {
      return r;
    }
  }catch(...){
    cout << "Caught exception. The output will be incomplete\n";
    try {
      Kast::print();
    } catch(...) {
      std::cout << std::endl;
    }
    throw;
  }

  try {
    Kast::print();
  } catch(...) {
    cout << flush;
    throw;
  }
  cout << endl;
}
