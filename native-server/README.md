# RV-Match native code server

This code is intended to be deployed with the production version of the C Semantics, found at https://runtimeverification.com/match. It is included in the open-source C Semantics repository because it is intended to be distributed with as permissive a license as possible in order to allow developers to customize and create an RV-Match that suits their specific platform-specific needs.

## High-level purpose

This is intended to be a portable C application which interfaces with the RV-Match runtime library in order to execute native code. It provides one half of a client/server communication interface which implements the following operations needed for support of the RV-Match native plugin:

* `_INVOKE`: takes a pointer to a function, a list of arguments, a pointer to the return value's location in memory, and a set of native memory to be marshalled, and executes the specified function, then unmarshals the native memory back tto the server.

* `_GET_SYMBOL_TABLE`: returns a list of all native symbols that may be used by the application, as well as their addresses.

* `_ALLOC`: takes an integer size and allocates dynamically native memory of the specified size, returning the address.

* `_SYNC_READ`: takes an address and a width in bytes and returns the content of the specified byte range.

* `_EXIT`: shuts down the native code server upon termination of the application.

## Use

The main use of the native code server is with the kcc -fnative-binary flag, or accompanied with kcc cross-compilation mode. When used with the -fnative-binary flag, no customization is required; simply pass the flag to the compiler and build and run your project normally.

When running cross-compiled to a specific platform, you may need to provide an implementation of platform.h for the specific platform. While details on how to integrate the resulting code into your specific platform are forthcoming (support for cross-compilation is still in development), you can implement a new platform by creating a platform.c that implements the interface defined in the comments of platform.h. 
