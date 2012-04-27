module DYNAMIC-SEMANTICS-TYPE-INCLUDE is
	// FIXME need to automatically pad structs
	including DYNAMIC-INCLUDE 
	including COMMON-SEMANTICS-TYPE-INCLUDE
end module

module DYNAMIC-C-TYPING is
	including DYNAMIC-SEMANTICS-TYPE-INCLUDE 
end module
