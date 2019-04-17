#include <fstream>
#include <optional>
#include <regex>
#include <stdexcept>
#include <string>
#include <vector>
#include <iostream>

struct FileContext {
	std::string fileName;
	int lineNumber;
};

std::ostream & operator<<(std::ostream &o, FileContext const &fc) {
	o << "{ \"file\": \"" << fc.fileName;
	o << "\", \"line\": \"" << fc.lineNumber << "\" }";
	return o;
}

struct DocumentRef {
	std::string document;
	std::string section;
};

std::ostream & operator<<(std::ostream &o, DocumentRef const &ref) {
	o << "{ \"document\": \"" << ref.document << '"';
	o << ", \"section\": \"" << ref.section << "\" }";
	return o;
}

struct Entry {
	FileContext fileContext;
	DocumentRef documentRef;
};

std::ostream & operator<<(std::ostream &o, Entry const &entry) {
	o << "{\n    \"document\": " << entry.documentRef << ",\n";
	o << "    \"semantics\": " << entry.fileContext << "\n  }";
	return o;
}

using Entries = std::vector<Entry>;

std::ostream & operator<<(std::ostream &o, Entries const &entries) {
	if (entries.empty()) {
		o << "[]";
		return o;
	}

	o << "[\n";
	for (size_t i = 0; i < entries.size(); i++) {
		o << "  " << entries[i];
		if (i < entries.size() - 1)
			o << ",\n";
	}
	o << "\n]\n";

	return o;
}

std::optional<DocumentRef> refFromLine(std::string line) {
	static const std::regex regex(R"(@ref (\S+) (\S+))");
	std::smatch result;
	if (std::regex_search(line, result, regex)) {
		if (result.size() == 2)
			return {DocumentRef{result[1], ""}};
		if (result.size() == 3)
			return {DocumentRef{result[1], result[2]}};
	}
	return {};
}


void print(std::optional<DocumentRef> ref) {
	if (ref)
		std::cout << ref.value();
	else
		std::cout << "empty";
}


Entries entriesFromIstream(std::string filename, std::istream & is) {
	Entries entries;
	FileContext fc {filename, 1};
	std::string line;
	while(std::getline(is, line)) {
		//std::cout << lineNumber << ": " << line << '\n';
		std::optional<DocumentRef> ref = refFromLine(line);
		//print(ref);
		//std::cout << '\n';
		if (ref)
			entries.push_back(Entry{fc, std::move(ref.value())});

		fc.lineNumber++;
	}

	return entries;
};

Entries entriesFromFile(std::string filename) {
	std::ifstream is(filename);
	if (!is.is_open())
		throw std::runtime_error(std::string("Cannot read file: ") + filename);
	return entriesFromIstream(filename, is);
}

void test() {
	//print(refFromLine("@ref n4296 12.3:4.5-6.7"));

	std::stringstream ss{R"(
		@ref n4296 12.3:4.5-6.7
	//	skip this n4296 12.3:4.5-6.7
	//	process this @ref n4296 13.3:4.5-6.7 additional comment
	)"};
	//std::cout << entriesFromIstream("testInput", ss);

}

int main(int argc, char *argv[]) {
	if (argc != 2) {
		std::cerr << "Usage: " << argv[0] << " <filename>\n";
		return 1;
	}
	try {
		std::cout << entriesFromFile(argv[1]);
	} catch (std::exception const &e) {
		std::cerr << "Error: " << e.what() << '\n';
	}
}
