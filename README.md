# Memcached on Windows

A build tool to get recent ```memcached``` builds working under Windows. Friends
don't let friends use software built six years ago.

* * *

## Disclaimer

Don't use this. Especially not in production.

* Windows is a _terrible_ server platform.
* I am a _terrible_ at Windows system administration.

## Installing

1. Download and install [MinGW](http://www.mingw.org/).
2. Install [MSYS](http://www.mingw.org/wiki/msys) and ensure ```fstab``` is
   configured correctly for your system.

## Building

    > powershell -ExecutionPolicy RemoteSigned .\memcached.ps1
