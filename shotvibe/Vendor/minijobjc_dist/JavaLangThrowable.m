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
//  Throwable.m
//  JreEmulation
//
//  Created by Tom Ball on 6/21/11, using j2objc.
//

#import "IOSClass.h"
#import "IOSObjectArray.h"
//#import "java/io/PrintStream.h"
//#import "java/io/PrintWriter.h"
#import "java/lang/Throwable.h"
#import "java/lang/AssertionError.h"
#import "java/lang/IllegalStateException.h"
#import "java/lang/IllegalArgumentException.h"
#import "java/lang/StackTraceElement.h"
//#import "java/lang/System.h"

#import <TargetConditionals.h>
#import <execinfo.h>

#ifndef MAX_STACK_FRAMES
// This defines the upper limit of the stack frames for any exception.
#define MAX_STACK_FRAMES 128
#endif

@implementation JavaLangThrowable

void FillInStackTraceInternal(JavaLangThrowable *this) {
  void *callStack[MAX_STACK_FRAMES];
  unsigned nFrames = backtrace(callStack, MAX_STACK_FRAMES);
  this->stackTrace = RETAIN_([JavaLangThrowable stackTrace:callStack
                                                     count:nFrames]);
}

// This init message implementation is hand-modified to
// invoke NSException.initWithName:reason:userInfo:.  This
// is necessary so that JRE exceptions can be caught by
// class name.
- (id)initJavaLangThrowableWithNSString:(NSString *)message
                  withJavaLangThrowable:(JavaLangThrowable *)causeArg {
  if ((self = [super initWithName:[[self class] description]
                           reason:message
                         userInfo:nil])) {
    JreMemDebugAdd(self);
    cause = RETAIN_(causeArg);
    detailMessage = RETAIN_(message);
    FillInStackTraceInternal(self);
    suppressedExceptions = nil;
  }
  return self;
}

- (id)init {
  return [self initJavaLangThrowableWithNSString:nil withJavaLangThrowable:nil];
}

- (id)initWithNSString:(NSString *)message {
  return [self initJavaLangThrowableWithNSString:message withJavaLangThrowable:nil];
}

- (id)initWithNSString:(NSString *)message
    withJavaLangThrowable:(JavaLangThrowable *)causeArg {
  return [self initJavaLangThrowableWithNSString:message withJavaLangThrowable:causeArg];
}

- (id)initWithJavaLangThrowable:(JavaLangThrowable *)causeArg {
  return [self initJavaLangThrowableWithNSString:causeArg ? [causeArg description] : nil
                           withJavaLangThrowable:causeArg];
}

- (id)initWithNSString:(NSString *)message
 withJavaLangThrowable:(JavaLangThrowable *)causeArg
           withBoolean:(BOOL)enableSuppression
           withBoolean:(BOOL)writeableStackTrace {
  return [self initJavaLangThrowableWithNSString:message
                           withJavaLangThrowable:causeArg];
}

+ (IOSObjectArray *)stackTrace:(void **)addresses
                         count:(unsigned)count {
  NSMutableArray *frames = [NSMutableArray array];
  for (int i = 0; i < count; i++) {
    JavaLangStackTraceElement *element = AUTORELEASE(
        [[JavaLangStackTraceElement alloc] initWithLong:(long long int)addresses[i]]);
    // Filter out native functions (no class), NSInvocation methods, and internal constructor.
    NSString *className = [element getClassName];
    if (className && ![className isEqualToString:@"NSInvocation"] &&
        ![[element getMethodName] hasPrefix:@"initJavaLangThrowable"]) {
      [frames addObject:element];
    }
  }
  JavaLangStackTraceElement *element = [frames lastObject];
  // Remove initial Method.invoke(), so app's main method is last.
  if ([[element getClassName] isEqualToString:@"JavaLangReflectMethod"] &&
      [[element getMethodName] isEqualToString:@"invoke"]) {
    [frames removeLastObject];
  }
  return [IOSObjectArray arrayWithNSArray:frames
                                     type:[JavaLangStackTraceElement getClass]];
}

- (JavaLangThrowable *)fillInStackTrace {
  FillInStackTraceInternal(self);
  return self;
}

- (JavaLangThrowable *)getCause {
  return cause;
}

- (NSString *)getLocalizedMessage {
  return [self getMessage];
}

- (NSString *)getMessage {
  return detailMessage;
}

- (IOSObjectArray *)getStackTrace {
  return stackTrace;
}

- (JavaLangThrowable *)initCauseWithJavaLangThrowable:
    (JavaLangThrowable *)causeArg {
  if (self->cause != nil) {
    id exception = [[JavaLangIllegalStateException alloc]
                    initWithNSString:@"Can't overwrite cause"];
#if ! __has_feature(objc_arc)
    [exception autorelease];
#endif
    @throw exception;
  }
  if (causeArg == self) {
    id exception = [[JavaLangIllegalArgumentException alloc]
                    initWithNSString:@"Self-causation not permitted"];
#if ! __has_feature(objc_arc)
    [exception autorelease];
#endif
    @throw exception;
  }
  self->cause = RETAIN_(causeArg);
  return self;
}

/*
- (void)printStackTrace {
  [self printStackTraceWithJavaIoPrintStream:[JavaLangSystem err]];
}
*/

/*
- (void)printStackTraceWithJavaIoPrintWriter:(JavaIoPrintWriter *)pw {
  [pw printlnWithNSString:[self description]];
  NSUInteger nFrames = [stackTrace count];
  for (NSUInteger i = 0; i < nFrames; i++) {
    [pw printWithNSString:@"\tat "];
    id trace = stackTrace->buffer_[i];
    [pw printlnWithId:trace];
  }
  if (self->cause) {
    [pw printWithNSString:@"Caused by: "];
    [self->cause printStackTraceWithJavaIoPrintWriter:pw];
  }
}
*/

/*
- (void)printStackTraceWithJavaIoPrintStream:(JavaIoPrintStream *)ps {
  [ps printlnWithNSString:[self description]];
  NSUInteger nFrames = [stackTrace count];
  for (NSUInteger i = 0; i < nFrames; i++) {
    [ps printWithNSString:@"\tat "];
    id trace = stackTrace->buffer_[i];
    [ps printlnWithId:trace];
  }
  if (self->cause) {
    [ps printWithNSString:@"Caused by: "];
    [self->cause printStackTraceWithJavaIoPrintStream:ps];
  }
}
*/

- (void)setStackTraceWithJavaLangStackTraceElementArray:
    (IOSObjectArray *)stackTraceArg {
  nil_chk(stackTraceArg);
  int count = [stackTraceArg count];
  for (int i = 0; i < count; i++) {
    nil_chk(stackTraceArg->buffer_[i]);
  }
#if __has_feature(objc_arc)
  stackTrace = stackTraceArg;
#else
  [stackTrace autorelease];
  stackTrace = [stackTraceArg retain];
#endif
}

- (void)addSuppressedWithJavaLangThrowable:(JavaLangThrowable *)exception {
  nil_chk(exception);
  if (exception == self) {
    @throw AUTORELEASE([[JavaLangIllegalArgumentException alloc] init]);
  }
  NSUInteger existingCount =
      suppressedExceptions ? [suppressedExceptions count] : 0;
  IOSObjectArray *newArray = [[IOSObjectArray alloc]
      initWithLength:existingCount + 1
                type:[IOSClass classWithClass:[JavaLangThrowable class]]];
  for (NSUInteger i = 0; i < existingCount; i++) {
    [newArray replaceObjectAtIndex:i withObject:suppressedExceptions->buffer_[i]];
  }
  [newArray replaceObjectAtIndex:existingCount
                      withObject:exception];
#if ! __has_feature(objc_arc)
  if (suppressedExceptions) {
    [suppressedExceptions release];
  }
#endif
  suppressedExceptions = newArray;
}

- (IOSObjectArray *)getSuppressed {
  return suppressedExceptions
      ? [IOSObjectArray arrayWithArray:suppressedExceptions]
      : [IOSObjectArray arrayWithLength:0
          type:[IOSClass classWithClass:[JavaLangThrowable class]]];
}

- (NSString *)description {
  NSString *className = [[self getClass] getName];
  NSString *msg = [self getMessage];
  if (msg) {
    return [NSString stringWithFormat:@"%@: %@", className, msg];
  } else {
    return className;
  }
}

#if ! __has_feature(objc_arc)
- (void)dealloc {
  JreMemDebugRemove(self);
  [cause release];
  [detailMessage release];
  [stackTrace release];
  [super dealloc];
}
#endif

// Generated by running the translator over the java.lang.Throwable stub file.
+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "initWithNSString:withJavaLangThrowable:withBoolean:withBoolean:", NULL, NULL, 0x4, NULL },
    { "fillInStackTrace", NULL, "Ljava/lang/Throwable;", 0x1, NULL },
    { "getCause", NULL, "Ljava/lang/Throwable;", 0x1, NULL },
    { "getLocalizedMessage", NULL, "Ljava/lang/String;", 0x1, NULL },
    { "getMessage", NULL, "Ljava/lang/String;", 0x1, NULL },
    { "getStackTrace", NULL, "Ljava/lang/StackTraceElement;", 0x1, NULL },
    { "initCauseWithJavaLangThrowable:", NULL, "Ljava/lang/Throwable;", 0x1, NULL },
    { "addSuppressedWithJavaLangThrowable:", NULL, "V", 0x11, NULL },
    { "getSuppressed", NULL, "[Ljava/lang/Throwable;", 0x11, NULL },
  };
  static J2ObjcClassInfo _JavaLangThrowable = { "Throwable", "java.lang", NULL, 0x1, 9, methods, 0, NULL};
  return &_JavaLangThrowable;
}

@end
