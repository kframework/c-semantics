#! /usr/bin/env bash

# 758 no_return 01 has no newline at end of file

echo "Unzipping Juliet..."
unzip -q -o Juliet-2010-12.c.cpp.zip

mkdir -p notApplicable
rm -rf notApplicable/*

echo "Moving tests that aren't applicable"
# these are security properties, but are not necessarily undefined
mv testcases/CWE15_External_Control_of_System_or_Configuration_Setting/ notApplicable/
mv testcases/CWE204_Response_Discrepancy_Information_Leak/ notApplicable/
mv testcases/CWE222_Truncation_Of_Security_Relevant_Information/ notApplicable/
mv testcases/CWE223_Omission_Of_Security_Relevant_Information/ notApplicable/
mv testcases/CWE226_Sensitive_Information_Uncleared_Before_Release/ notApplicable/
mv testcases/CWE244_Failure_to_Clear_Heap_Before_Release/ notApplicable/
mv testcases/CWE247_Reliance_On_DNS_Lookups_In_A_Security_Decision/ notApplicable/
mv testcases/CWE252_Unchecked_Return_Value/ notApplicable/
mv testcases/CWE256_Plaintext_Storage_of_Password/ notApplicable/
mv testcases/CWE259_Hard_Coded_Password/ notApplicable/
mv testcases/CWE272_Least_Privilege_Principal/ notApplicable/
mv testcases/CWE273_Improper_Check_for_Dropped_Privileges/ notApplicable/
mv testcases/CWE284_Access_Control_Issues/ notApplicable/
mv testcases/CWE319_Plaintext_Tx_Sensitive_Info/ notApplicable/
mv testcases/CWE321_Hard_Coded_Cryptographic_Key/ notApplicable/
mv testcases/CWE327_Use_Broken_Crypto/ notApplicable/
mv testcases/CWE328_Reversible_Oneway_Hash/ notApplicable/
mv testcases/CWE338_Weak_PRNG/ notApplicable/
mv testcases/CWE377_Insecure_Temporary_File/ notApplicable/
mv testcases/CWE547_Hardcoded_Security_Constants/ notApplicable/
mv testcases/CWE560_Use_Of_umask_With_chmod_Style_Argument/ notApplicable/
mv testcases/CWE591_Sensitive_Data_Storage_in_Improperly_Locked_Memory/ notApplicable/
mv testcases/CWE620_Unverified_Password_Change/ notApplicable/
mv testcases/CWE78_OS_Command_Injection/ notApplicable/
mv testcases/CWE534_Info_Leak_Debug_Log/ notApplicable/
mv testcases/CWE535_Info_Leak_Shell_Error/ notApplicable/
mv testcases/CWE134_Uncontrolled_Format_String/ notApplicable/
mv testcases/CWE426_Untrusted_Search_Path/ notApplicable/
mv testcases/CWE427_Uncontrolled_Search_Path_Element/ notApplicable/

# these are bad programming practices, but are not necessarily undefined
mv testcases/CWE478_Failure_To_Use_Default_Case_In_Switch/ notApplicable/
mv testcases/CWE36_Absolute_Path_Traversal/ notApplicable/
mv testcases/CWE365_Race_Condition_In_Switch/ notApplicable/
mv testcases/CWE401_Memory_Leak/ notApplicable/
mv testcases/CWE481_Assigning_instead_of_Comparing/ notApplicable/
mv testcases/CWE482_Comparing_instead_of_Assigning/ notApplicable/
mv testcases/CWE23_Relative_Path_Traversal/ notApplicable/
mv testcases/CWE242_Use_of_Inherently_Dangerous_Function/ notApplicable/
mv testcases/CWE546_Suspicious_Comment/ notApplicable/
mv testcases/CWE561_Dead_Code/ notApplicable/
mv testcases/CWE563_Unused_Variable/ notApplicable/
mv testcases/CWE570_Expression_Always_False/ notApplicable/
mv testcases/CWE571_Expression_Always_True/ notApplicable/
mv testcases/CWE511_Logic_Time_Bomb/ notApplicable/
mv testcases/CWE789_Uncontrolled_Mem_Alloc/ notApplicable/
mv testcases/CWE484_Omitted_Break_Statement/ notApplicable/
mv testcases/CWE483_Incorrect_Block_Delimitation/ notApplicable/
mv testcases/CWE187_Partial_Comparison/ notApplicable/
mv testcases/CWE195_Signed_To_Unsigned_Conversion/ notApplicable/
mv testcases/CWE196_Unsigned_To_Signed_Conversion_Error/ notApplicable/
mv testcases/CWE197_Numeric_Truncation_Error/ notApplicable/
mv testcases/CWE253_Incorrect_Check_of_Function_Return_Value/ notApplicable/
mv testcases/CWE480_Use_of_Incorrect_Operator/ notApplicable/
mv testcases/CWE690_NULL_Deref_from_Return/ notApplicable/

# these are system dependent tests, but are not necessarily undefined
mv testcases/CWE114_Process_Control/ notApplicable/
mv testcases/CWE605_Multiple_Binds_Same_Port/ notApplicable/
mv testcases/CWE785_Path_Manipulation_Function_Without_Max_Sized_Buffer/ notApplicable/
mv testcases/CWE188_Reliance_On_Data_Memory_Layout/ notApplicable/

# just io tests
mv testcases/CWE123_Write_What_Where_Condition/ notApplicable/


# see "The value of a pointer to an object whose lifetime has ended is used (6.2.4)" and "(7.22.3) The lifetime of an allocated object extends from the allocation until the deallocation."
mv testcases/CWE415_Double_Free/ notApplicable/
mv testcases/CWE416_Use_After_Free/ notApplicable/
# in the good branches, using value of a local after its lifetime has ended
mv testcases/CWE476_NULL_Pointer_Dereference/ notApplicable/
# there are tests for unsigned overflow, and there are tests for things that overflow before promotion but not afterwards
mv testcases/CWE190_Integer_Overflow/ notApplicable/
mv testcases/CWE191_Integer_Underflow/ notApplicable/

# assume static analysis
mv testcases/CWE129_Improper_Validation_Of_Array_Index/ notApplicable/

# this one is usually okay, but mallocs 4 gigs of ram
mv testcases/CWE194_Unexpected_Sign_Extension/ notApplicable/
 
# c++ tests
mv testcases/CWE762_Mismatched_Memory_Management_Routines/ notApplicable/
mv testcases/CWE248_Uncaught_Exception/ notApplicable/
mv testcases/CWE374_Passing_Mutable_Objects_to_Untrusted_Method/ notApplicable/

# not going to deal with signal stuff
rm -rf signal/*
mkdir -p signal
mv testcases/CWE364_Signal_Handler_Race_Condition/ signal/
mv testcases/CWE479_Unsafe_Call_from_a_Signal_Handler/ signal/

echo "Moving tests that use functions we don't handle or are not standard"
mkdir -p alloca
mv `ls testcases/*/*alloca*.c` alloca/
mkdir -p float
mv `ls testcases/*/*float*.c` float/
mkdir -p io
mv `ls testcases/*/*socket*.c` io/
mv `ls testcases/*/*fscanf*.c` io/
mv `ls testcases/*/*fgets*.c` io/
mv `ls testcases/*/*fopen*.c` io/
# mkdir -p snprintf
# mv `ls testcases/*/*snprintf*.c` snprintf/
mkdir -p w32
mv `ls testcases/*/*w32*.c` w32/
mkdir -p wchar
mv `ls testcases/*/*wchar*.c` wchar/
mkdir -p cpp
rm -f `ls testcases/*/main.cpp`
mv -f `ls testcases/*/*.cpp` cpp/
# mv `grep -l 'RAND32' testcases/*/*.c` random/
# mv `grep -l 'RAND64' testcases/*/*.c` random/
# mv `grep -l ')rand(' testcases/*/*.c` random/
# mkdir -p signal
# mv `grep -l '<signal\.h>' testcases/*/*.c` signal/

mkdir -p environment
mv -f `ls testcases/*/*Environment*.c` environment/
mv -f `ls testcases/*/*fromConsole*.c` environment/
mv -f `ls testcases/*/*fromFile*.c` environment/

# these tests assume we're doing static analysis and can actually be correct dynamically
mkdir -p random
mv `ls testcases/*/*rand*.c` random/
mv `grep -l 'global_returns_t_or_f' testcases/*/*.c` random/

echo "Fixing some tests that have undefined behavior in the good branches"
# there is some undefined behavior in some of the tests where they read a value that hasn't been initialized.  This fixes those cases
perl -i -p -e 'undef $/; s/^    (char|int|long|long long|double) \* data;(\s+\1 \* \*data_ptr1 = &data;\s+\1 \* \*data_ptr2 = &data;)/    \1 \* data = 0;\2/gsm' testcases/*/*.c

echo "Changing \"_snprintf\" to \"snprintf\""
perl -i -p -e 's/(\s)_snprintf/\1snprintf/gsm' testcases/*/*.c

echo "Saving the known good tests"
rm -rf good
mkdir -p good
mv testcases/CWE121_Stack_Based_Buffer_Overflow/ good/
mv testcases/CWE122_Heap_Based_Buffer_Overflow/ good/
mv testcases/CWE124_Buffer_Underwrite/ good/
mv testcases/CWE126_Buffer_Overread/ good/
mv testcases/CWE127_Buffer_Underread/ good/
mv testcases/CWE131_Incorrect_Calculation_Of_Buffer_Size/ good/
mv testcases/CWE170_Improper_Null_Termination/ good/
mv testcases/CWE193_Off_by_One_Error/ good/
mv testcases/CWE369_Divide_By_Zero/ good/
mv testcases/CWE562_Return_Of_Stack_Variable_Address/ good/
mv testcases/CWE590_Free_Of_Invalid_Pointer_Not_On_The_Heap/ good/
mv testcases/CWE665_Improper_Initialization/ good/
mv testcases/CWE680_Integer_Overflow_To_Buffer_Overflow/ good/
mv testcases/CWE685_Function_Call_With_Incorrect_Number_Of_Arguments/ good/
mv testcases/CWE688_Function_Call_With_Incorrect_Variable_Or_Reference_As_Argument/ good/
mv testcases/CWE761_Free_Pointer_Not_At_Start_Of_Buffer/ good/

echo "Done!"
