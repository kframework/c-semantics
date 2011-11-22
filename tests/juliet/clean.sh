#! /usr/bin/env bash

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
mv testcases/CWE547_Hardcoded_Security_Constants/ notApplicable/
mv testcases/CWE560_Use_Of_umask_With_chmod_Style_Argument/ notApplicable/
mv testcases/CWE591_Sensitive_Data_Storage_in_Improperly_Locked_Memory/ notApplicable/
mv testcases/CWE620_Unverified_Password_Change/ notApplicable/
mv testcases/CWE78_OS_Command_Injection/ notApplicable/
mv testcases/CWE534_Info_Leak_Debug_Log/ notApplicable/
mv testcases/CWE535_Info_Leak_Shell_Error/ notApplicable/

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

# these are system dependent tests, but are not necessarily undefined
mv testcases/CWE114_Process_Control/ notApplicable/
mv testcases/CWE605_Multiple_Binds_Same_Port/ notApplicable/
mv testcases/CWE785_Path_Manipulation_Function_Without_Max_Sized_Buffer/ notApplicable/

# just io tests
mv testcases/CWE123_Write_What_Where_Condition/ notApplicable/
 
# c++ tests
mv testcases/CWE762_Mismatched_Memory_Management_Routines/ notApplicable/

echo "Moving tests that use functions we don't handle"
mkdir -p alloca
mv `ls testcases/*/*alloca*.c` alloca/
mkdir -p float
mv `ls testcases/*/*float*.c` float/
mkdir -p io
mv `ls testcases/*/*socket*.c` io/
mv `ls testcases/*/*fscanf*.c` io/
mv `ls testcases/*/*fgets*.c` io/
mv `ls testcases/*/*fopen*.c` io/
mkdir -p snprintf
mv `ls testcases/*/*snprintf*.c` snprintf/
mkdir -p w32
mv `ls testcases/*/*w32*.c` w32/
mkdir -p wchar
mv `ls testcases/*/*wchar*.c` wchar/
mkdir -p random
mv `ls testcases/*/*rand*.c` random/
mkdir -p cpp
rm -f `ls testcases/*/main.cpp`
mv -f `ls testcases/*/*.cpp` cpp/
# mv `grep -l 'RAND32' testcases/*/*.c` random/
# mv `grep -l 'RAND64' testcases/*/*.c` random/
# mv `grep -l ')rand(' testcases/*/*.c` random/

mkdir -p randbehavior
# these tests assume we're doing static analysis and can actually be correct dynamically
mv `grep -l 'global_returns_t_or_f' testcases/*/*.c` randbehavior/

echo "Fixing some tests that have undefined behavior in the good branches"
# there is some undefined behavior in some of the tests where they read a value that hasn't been initialized.  This fixes those cases
perl -i -p -e 'undef $/; s/^    (char|int|long|long long|double) \* data;(\s+\1 \* \*data_ptr1 = &data;\s+\1 \* \*data_ptr2 = &data;)/    \1 \* data = 0;\2/gsm' testcases/*/*.c

echo "Done!"
