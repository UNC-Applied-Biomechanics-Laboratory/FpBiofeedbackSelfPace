/*
Copyright (c) 2009, 2014 Bertec Corporation
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list
  of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
  list of conditions and the following disclaimer in the documentation and/or other
  materials provided with the distribution.

* Neither the name of the Bertec Corporation nor the names of its contributors may
  be used to endorse or promote products derived from this software without specific
  prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef TREADMILL_REMOTE_H
#define TREADMILL_REMOTE_H

#ifdef _WIN32

#include <windows.h>
#ifdef TREADMILLREMOTEDLL_EXPORTS
#define TREADMILLREMOTEDLL_API __declspec(dllexport)
#else
#define TREADMILLREMOTEDLL_API __declspec(dllimport)
#endif

#else

#define WINAPI
#define TREADMILLREMOTEDLL_API

#endif


enum {
   TREADMILL_OK = 0,
   // errors in TREADMILL_initialize
   TREADMILL_WSA_STARTUP = 10,
   TREADMILL_ADDRESS = 11,
   TREADMILL_SOCKET = 12,
   TREADMILL_CONNECT = 13,
   TREADMILL_SETSOCKOPT = 14,
   // errors in TREADMILL_setSpeed
   TREADMILL_NOT_CONNECTED = 20,
   TREADMILL_SEND = 21
};

#ifdef __cplusplus
extern "C" {
#endif

typedef int (WINAPI *t_TREADMILL_initialize)(char *, char *);
typedef int (WINAPI *t_TREADMILL_setSpeed)(double, double, double);
typedef int (WINAPI *t_TREADMILL_setSpeed4)(double, double, double, double, double);
typedef int (WINAPI *t_TREADMILL_close)(void);
typedef int (WINAPI *t_TREADMILL_initializeUDP)(char *, char *);

TREADMILLREMOTEDLL_API int WINAPI TREADMILL_initialize(char * ip, char * port);
TREADMILLREMOTEDLL_API int WINAPI TREADMILL_setSpeed(double left, double right,
                                                     double acceleration);
TREADMILLREMOTEDLL_API int WINAPI TREADMILL_setSpeed4(double frontLeft,
                                                      double frontRight,
                                                      double rearLeft,
                                                      double rearRight,
                                                      double acceleration);
TREADMILLREMOTEDLL_API void WINAPI TREADMILL_close(void);
TREADMILLREMOTEDLL_API int WINAPI TREADMILL_initializeUDP(char * ip, char * port);

#ifdef __cplusplus
}
#endif

#endif
