## Error Code Examples

The example programs in this folder demonstrate the error codes reported by
`kcc`.
There are currently more than 150 such error codes, listed in
[Error_Codes.csv](Error_Codes.csv) together with their descriptions.
As seen in this list, some of the error codes can only be reported
by special modules implemented in the
[RV-Match](https://runtimeverification.com/match/) tool licensed by
[Runtime Verification, Inc.](https://runtimeverification.com).

The name of each example program starts with the error code that it
illustrates and ends with either `-bad.c` or `-good.c`.
The `-bad.c` variant contains the actual error and the `-good.c` variant
fixes the error.
For the `-bad.c` variant we also include `kcc`'s output (`-bad.output`).

We strongly encourage you to take the time and digest these error code
examples.
They are quite simple and help you better understand C's tricky
undefinedness.
They can also constitute a great simple benchmark for testing and
evaluating C program analysis tools.
