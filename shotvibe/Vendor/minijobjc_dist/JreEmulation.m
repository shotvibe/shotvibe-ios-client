// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  JreEmulation.m
//  J2ObjC
//
//  Created by Tom Ball on 4/23/12.
//

#import "JreEmulation.h"
#import "java/lang/NullPointerException.h"

void JreThrowNullPointerException() {
  @throw AUTORELEASE([[JavaLangNullPointerException alloc] init]);
}

#ifdef J2OBJC_COUNT_NIL_CHK
int j2objc_nil_chk_count = 0;
#endif

void JrePrintNilChkCount() {
#ifdef J2OBJC_COUNT_NIL_CHK
  printf("nil_chk count: %d\n", j2objc_nil_chk_count);
#endif
}

void JrePrintNilChkCountAtExit() {
  atexit(JrePrintNilChkCount);
}
