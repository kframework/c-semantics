#include <filesystem>
#include <fstream>
#include <optional>
#include <regex>
#include <stdexcept>
#include <string>
#include <vector>
#include <iostream>

namespace fs = std::filesystem;

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


void addEntriesFromIstream(Entries & entries, std::string path, std::istream & is) {
	FileContext fc {path, 1};
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
};

void addEntriesFromRegularFile(Entries & entries, fs::path filepath) {
	// Ignore files not matching '*.k'
	if (filepath.extension() != ".k" && filepath.extension() != ".cc")
		return;

	std::ifstream is(filepath);
	if (!is.is_open())
		throw std::runtime_error(std::string("Cannot read file: ") + filepath.string());
	addEntriesFromIstream(entries, filepath.string(), is);
}

void addEntriesFromDirectory(Entries & entries, fs::path dirpath) {
	for(auto& current: fs::recursive_directory_iterator(dirpath)) {
		addEntriesFromRegularFile(entries, current);
	}

}


void addEntriesFromPath(Entries & entries, fs::path p) {
	if (fs::is_regular_file(p))
		return addEntriesFromRegularFile(entries, p);

	if (fs::is_directory(p))
		return addEntriesFromDirectory(entries, p);
}

Entries entriesFromPath(fs::path path) {
	Entries entries;
	addEntriesFromPath(entries, path);
	return entries;
}

int main(int argc, char *argv[]) {
	if (argc != 2) {
		std::cerr << "Usage: " << argv[0] << " <path>\n";
		return 1;
	}
	try {
		std::cout << entriesFromPath(argv[1]);
	} catch (std::exception const &e) {
		std::cerr << "Error: " << e.what() << '\n';
	}
}
