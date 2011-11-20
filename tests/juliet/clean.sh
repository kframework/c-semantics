#! /usr/bin/env bash

mkdir -p notApplicable
# these are security properties, but are not necessarily undefined
mv testcases/CWE256_Plaintext_Storage_of_Password notApplicable/
mv testcases/CWE259_Hard_Coded_Password notApplicable/
mv testcases/CWE272_Least_Privilege_Principal notApplicable/
mv testcases/CWE273_Improper_Check_for_Dropped_Privileges notApplicable/
mv testcases/CWE284_Access_Control_Issues notApplicable/
mv testcases/CWE319_Plaintext_Tx_Sensitive_Info notApplicable/
mv testcases/CWE321_Hard_Coded_Cryptographic_Key notApplicable/
mv testcases/CWE327_Use_Broken_Crypto notApplicable/
mv testcases/CWE328_Reversible_Oneway_Hash notApplicable/
mv testcases/CWE338_Weak_PRNG notApplicable/
mv testcases/CWE204_Response_Discrepancy_Information_Leak notApplicable/
mv testcases/CWE222_Truncation_Of_Security_Relevant_Information notApplicable/
mv testcases/CWE223_Omission_Of_Security_Relevant_Information notApplicable/
mv testcases/CWE226_Sensitive_Information_Uncleared_Before_Release notApplicable/
mv testcases/CWE15_External_Control_of_System_or_Configuration_Setting notApplicable/
mv testcases/CWE247_Reliance_On_DNS_Lookups_In_A_Security_Decision notApplicable/

# these are bad programming practices, but are not necessarily undefined
mv testcases/CWE478_Failure_To_Use_Default_Case_In_Switch notApplicable/
mv testcases/CWE36_Absolute_Path_Traversal notApplicable/
mv testcases/CWE365_Race_Condition_In_Switch notApplicable/

# these are system dependent tests, but are not necessarily undefined
mv testcases/CWE114_Process_Control notApplicable/
mv testcases/CWE605_Multiple_Binds_Same_Port notApplicable/
 
# c++ tests
mv testcases/CWE762_Mismatched_Memory_Management_Routines notApplicable/


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


mkdir -p randbehavior
# these tests assume we're doing static analysis and can actually be correct dynamically
mv `grep -l 'global_returns_t_or_f' testcases/*/*.c` randbehavior/
# there is some undefined behavior in some of the tests where they read a value that hasn't been initialized.  This fixes those cases
perl -i -p -e 'undef $/; s/^    char \* data;(\s+char \* \*data_ptr1 = &data;\s+char \* \*data_ptr2 = &data;)/    char \* data = 0;\1/gsm' testcases/*/*.c
