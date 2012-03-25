#! /usr/bin/env bash

function saveAndPrint {
	echo -n "$1: "
	ls -1 *.c testcases/$1/ | sed 's/\([1-9][0-9]\?\)[a-z]\?\.c/\1\.c/' | sort | uniq | wc -l
	mv testcases/$1/ good/
}

# 758 no_return 01 has no newline at end of file

echo "Unzipping Juliet..."
unzip -q -o Juliet-2010-12.c.cpp.zip

rm -rf notApplicable

DIR=notApplicable/misc/
mkdir -p $DIR

echo "Moving tests that aren't applicable"

# these are security properties, but are not necessarily undefined
mv testcases/CWE15_External_Control_of_System_or_Configuration_Setting/ $DIR
mv testcases/CWE204_Response_Discrepancy_Information_Leak/ $DIR
mv testcases/CWE222_Truncation_Of_Security_Relevant_Information/ $DIR
mv testcases/CWE223_Omission_Of_Security_Relevant_Information/ $DIR
mv testcases/CWE226_Sensitive_Information_Uncleared_Before_Release/ $DIR
mv testcases/CWE244_Failure_to_Clear_Heap_Before_Release/ $DIR
mv testcases/CWE247_Reliance_On_DNS_Lookups_In_A_Security_Decision/ $DIR
mv testcases/CWE252_Unchecked_Return_Value/ $DIR
mv testcases/CWE256_Plaintext_Storage_of_Password/ $DIR
mv testcases/CWE259_Hard_Coded_Password/ $DIR
mv testcases/CWE272_Least_Privilege_Principal/ $DIR
mv testcases/CWE273_Improper_Check_for_Dropped_Privileges/ $DIR
mv testcases/CWE284_Access_Control_Issues/ $DIR
mv testcases/CWE319_Plaintext_Tx_Sensitive_Info/ $DIR
mv testcases/CWE321_Hard_Coded_Cryptographic_Key/ $DIR
mv testcases/CWE327_Use_Broken_Crypto/ $DIR
mv testcases/CWE328_Reversible_Oneway_Hash/ $DIR
mv testcases/CWE338_Weak_PRNG/ $DIR
mv testcases/CWE377_Insecure_Temporary_File/ $DIR
mv testcases/CWE547_Hardcoded_Security_Constants/ $DIR
mv testcases/CWE560_Use_Of_umask_With_chmod_Style_Argument/ $DIR
mv testcases/CWE591_Sensitive_Data_Storage_in_Improperly_Locked_Memory/ $DIR
mv testcases/CWE620_Unverified_Password_Change/ $DIR
mv testcases/CWE78_OS_Command_Injection/ $DIR
mv testcases/CWE534_Info_Leak_Debug_Log/ $DIR
mv testcases/CWE535_Info_Leak_Shell_Error/ $DIR
mv testcases/CWE134_Uncontrolled_Format_String/ $DIR
mv testcases/CWE426_Untrusted_Search_Path/ $DIR
mv testcases/CWE427_Uncontrolled_Search_Path_Element/ $DIR

# these are bad programming practices, but are not necessarily undefined
mv testcases/CWE478_Failure_To_Use_Default_Case_In_Switch/ $DIR
mv testcases/CWE36_Absolute_Path_Traversal/ $DIR
mv testcases/CWE365_Race_Condition_In_Switch/ $DIR
mv testcases/CWE401_Memory_Leak/ $DIR
mv testcases/CWE481_Assigning_instead_of_Comparing/ $DIR
mv testcases/CWE482_Comparing_instead_of_Assigning/ $DIR
mv testcases/CWE23_Relative_Path_Traversal/ $DIR
mv testcases/CWE242_Use_of_Inherently_Dangerous_Function/ $DIR
mv testcases/CWE546_Suspicious_Comment/ $DIR
mv testcases/CWE561_Dead_Code/ $DIR
mv testcases/CWE563_Unused_Variable/ $DIR
mv testcases/CWE570_Expression_Always_False/ $DIR
mv testcases/CWE571_Expression_Always_True/ $DIR
mv testcases/CWE511_Logic_Time_Bomb/ $DIR
mv testcases/CWE789_Uncontrolled_Mem_Alloc/ $DIR
mv testcases/CWE484_Omitted_Break_Statement/ $DIR
mv testcases/CWE483_Incorrect_Block_Delimitation/ $DIR
mv testcases/CWE187_Partial_Comparison/ $DIR
mv testcases/CWE195_Signed_To_Unsigned_Conversion/ $DIR
mv testcases/CWE196_Unsigned_To_Signed_Conversion_Error/ $DIR
mv testcases/CWE197_Numeric_Truncation_Error/ $DIR
mv testcases/CWE253_Incorrect_Check_of_Function_Return_Value/ $DIR
mv testcases/CWE480_Use_of_Incorrect_Operator/ $DIR
mv testcases/CWE690_NULL_Deref_from_Return/ $DIR
mv testcases/CWE674_Uncontrolled_Recursion/ $DIR
mv testcases/CWE587_Assignment_Of_Fixed_Address_To_Pointer/ $DIR
mv testcases/CWE489_Leftover_Debug_Code/ $DIR
mv testcases/CWE468_Incorrect_Pointer_Scaling/ $DIR
mv testcases/CWE467_Use_of_sizeof_on_Pointer_Type/ $DIR
mv testcases/CWE459_Incomplete_Cleanup/ $DIR
mv testcases/CWE392_Failure_To_Report_Error_In_Status_Code/ $DIR
mv testcases/CWE390_Error_Without_Action/ $DIR
mv testcases/CWE391_Unchecked_Error_Condition/ $DIR
mv testcases/CWE135_Incorrect_Calculation_Of_Multibyte_String_Length/ $DIR
mv testcases/CWE617_Reachable_Assertion/ $DIR

# these are system dependent tests, but are not necessarily undefined
mv testcases/CWE114_Process_Control/ $DIR
mv testcases/CWE605_Multiple_Binds_Same_Port/ $DIR
mv testcases/CWE785_Path_Manipulation_Function_Without_Max_Sized_Buffer/ $DIR
mv testcases/CWE188_Reliance_On_Data_Memory_Layout/ $DIR
mv testcases/CWE666_Operation_on_Resource_in_Wrong_Phase_of_Lifetime/ $DIR
mv testcases/CWE366_Race_Condition_Within_A_Thread/ $DIR

# just io tests
mv testcases/CWE123_Write_What_Where_Condition/ $DIR
mv testcases/CWE772_Missing_Release_of_Resource_after_Effective_Lifetime/ $DIR
mv testcases/CWE464_Insertion_Of_Data_Structure_Sentinel/ $DIR
mv testcases/CWE404_Improper_Resource_Shutdown/ $DIR
mv testcases/CWE367_TOC_TOU/ $DIR

# moving "empty" directories
mv testcases/CWE676_Use_of_Potentially_Dangerous_Function/ $DIR
mv testcases/CWE675_Duplicate_Operations_on_Resource/ $DIR
mv testcases/CWE672_Operation_on_Resource_After_Expiration_or_Release/ $DIR
mv testcases/CWE606_Unchecked_Loop_Condition/ $DIR
mv testcases/CWE440_Expected_Behavior_Violation/ $DIR
mv testcases/CWE400_Resource_Exhaustion/ $DIR
mv testcases/CWE397_Throw_Generic_Exception/ $DIR
mv testcases/CWE396_Catch_Generic_Exception/ $DIR

# see "The value of a pointer to an object whose lifetime has ended is used (6.2.4)" and "(7.22.3) The lifetime of an allocated object extends from the allocation until the deallocation."
mv testcases/CWE415_Double_Free/ $DIR
mv testcases/CWE416_Use_After_Free/ $DIR
# in the good branches, using value of a local after its lifetime has ended
mv testcases/CWE476_NULL_Pointer_Dereference/ $DIR
# there are tests for unsigned overflow, and there are tests for things that overflow before promotion but not afterwards
mv testcases/CWE190_Integer_Overflow/ $DIR
mv testcases/CWE191_Integer_Underflow/ $DIR

# assume static analysis
mv testcases/CWE129_Improper_Validation_Of_Array_Index/ $DIR

# this one is usually okay, but mallocs 4 gigs of ram
mv testcases/CWE194_Unexpected_Sign_Extension/ $DIR
 
# c++ tests
mv testcases/CWE762_Mismatched_Memory_Management_Routines/ $DIR
mv testcases/CWE248_Uncaught_Exception/ $DIR
mv testcases/CWE374_Passing_Mutable_Objects_to_Untrusted_Method/ $DIR

# these variations introduce undefined behavior (reads uninit memory in good branch)
mv testcases/CWE457_Use_of_Uninitialized_Variable/CWE457_Use_of_Uninitialized_Variable__*_64*.c $DIR
mv testcases/CWE457_Use_of_Uninitialized_Variable/CWE457_Use_of_Uninitialized_Variable__*_63*.c $DIR

# these variations aren't actually undefined
mv testcases/CWE469_Use_Of_Pointer_Subtraction_To_Determine_Size/CWE469_Use_Of_Pointer_Subtraction_To_Determine_Size__char_loop_*.c $DIR

# not going to deal with signal stuff
DIR=notApplicable/signal/
mkdir -p $DIR
mv testcases/CWE364_Signal_Handler_Race_Condition/ $DIR
mv testcases/CWE479_Unsafe_Call_from_a_Signal_Handler/ $DIR


echo "Moving tests that use functions we don't handle or are not standard"
DIR=notApplicable/alloca/
mkdir -p $DIR
mv `ls testcases/*/*alloca*.c` $DIR
DIR=notApplicable/float/
mkdir -p $DIR
mv `ls testcases/*/*float*.c` $DIR
DIR=notApplicable/io/
mkdir -p $DIR
mv `ls testcases/*/*socket*.c` $DIR
mv `ls testcases/*/*fscanf*.c` $DIR
mv `ls testcases/*/*fgets*.c` $DIR
# mv `ls testcases/*/*fopen*.c` $DIR

# DIR=notApplicable/w32/
# mkdir -p $DIR
# mv `ls testcases/*/*w32*.c` $DIR

DIR=notApplicable/wchar/
mkdir -p $DIR
mv `ls testcases/*/*wchar*.c` $DIR
DIR=notApplicable/cpp/
mkdir -p $DIR
rm -f `ls testcases/*/main.cpp`
mv -f `ls testcases/*/*.cpp` $DIR
# mv `grep -l 'RAND32' testcases/*/*.c` random/
# mv `grep -l 'RAND64' testcases/*/*.c` random/
# mv `grep -l ')rand(' testcases/*/*.c` random/
# mkdir -p signal
# mv `grep -l '<signal\.h>' testcases/*/*.c` signal/

DIR=notApplicable/environment/
mkdir -p $DIR
mv -f `ls testcases/*/*Environment*.c` $DIR
mv -f `ls testcases/*/*fromConsole*.c` $DIR
mv -f `ls testcases/*/*fromFile*.c` $DIR

# these tests assume we're doing static analysis and can actually be correct dynamically
DIR=notApplicable/random/
mkdir -p $DIR
mv `ls testcases/*/*rand*.c` $DIR
mv `grep -l 'global_returns_t_or_f' testcases/*/*.c` $DIR

echo "Fixing some tests that have undefined behavior in the good branches"
# there is some undefined behavior in some of the tests where they read a value that hasn't been initialized.  This fixes those cases
perl -i -p -e 'undef $/; s/^    (void|char|int|long|long long|double|twoints) \* data;(\s+\1 \* \*data_ptr1 = &data;\s+\1 \* \*data_ptr2 = &data;)/    \1 \* data = 0;\2/gsm' testcases/*/*.c

echo "Changing \"_snprintf\" to \"snprintf\""
perl -i -p -e 's/(\s)_snprintf/\1snprintf/gsm' testcases/*/*.c

echo "Commenting out use of wprintf"
sed -i 's/\(wprintf(L"%s\\n", line);\)/\/\/ \1/' testcasesupport/io.c

echo "Adding newlines to files that need them"
FIX=testcases/CWE758_Undefined_Behavior/CWE758_Undefined_Behavior__no_return_implicit_01.c
echo | cat $FIX - > fix.tmp
mv fix.tmp $FIX
FIX=testcases/CWE758_Undefined_Behavior/CWE758_Undefined_Behavior__no_return_01.c
echo | cat $FIX - > fix.tmp
mv fix.tmp $FIX
FIX=testcases/CWE758_Undefined_Behavior/CWE758_Undefined_Behavior__bare_return_01.c
echo | cat $FIX - > fix.tmp
mv fix.tmp $FIX
FIX=testcases/CWE758_Undefined_Behavior/CWE758_Undefined_Behavior__bare_return_implicit_01.c
echo | cat $FIX - > fix.tmp
mv fix.tmp $FIX

echo "Saving the known good tests"
rm -rf good
mkdir -p good

GOODTESTS='CWE121_Stack_Based_Buffer_Overflow CWE122_Heap_Based_Buffer_Overflow CWE124_Buffer_Underwrite CWE126_Buffer_Overread CWE127_Buffer_Underread CWE131_Incorrect_Calculation_Of_Buffer_Size CWE170_Improper_Null_Termination CWE193_Off_by_One_Error CWE369_Divide_By_Zero CWE457_Use_of_Uninitialized_Variable CWE469_Use_Of_Pointer_Subtraction_To_Determine_Size CWE562_Return_Of_Stack_Variable_Address CWE590_Free_Of_Invalid_Pointer_Not_On_The_Heap CWE665_Improper_Initialization CWE680_Integer_Overflow_To_Buffer_Overflow CWE685_Function_Call_With_Incorrect_Number_Of_Arguments CWE688_Function_Call_With_Incorrect_Variable_Or_Reference_As_Argument CWE758_Undefined_Behavior CWE761_Free_Pointer_Not_At_Start_Of_Buffer CWE588_Attempt_To_Access_Child_Of_A_Non_Structure_Pointer'

for dir in $GOODTESTS
do
	saveAndPrint $dir
done

echo "Done!"
