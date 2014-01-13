//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/StackTraceElement.java
//
//  Created by raptor on 1/9/14.
//

#include "java/lang/StackTraceElement.h"
#import "IOSClass.h"
#import "java/lang/ClassNotFoundException.h"

#import <execinfo.h>

@implementation JavaLangStackTraceElement

- (NSString *)getClassName {
  [self initializeFromAddress];
  return className__;
}

- (NSString *)getMethodName {
  [self initializeFromAddress];
  return methodName_;
}

- (NSString *)getFileName {
  return fileName_;
}

- (int)getLineNumber {
  return lineNumber_;
}

- (id)initJavaLangStackTraceElementWithNSString:(NSString *)className_
                                   withNSString:(NSString *)methodName
                                   withNSString:(NSString *)fileName
                                        withInt:(int)lineNumber {
  if (self = [super init]) {
    self->className__ = className_;
    self->methodName_ = methodName;
    self->fileName_ = fileName;
    self->lineNumber_ = lineNumber;
  }
  return self;
}

- (id)initWithNSString:(NSString *)className_
          withNSString:(NSString *)methodName
          withNSString:(NSString *)fileName
               withInt:(int)lineNumber {
  return [self initJavaLangStackTraceElementWithNSString:className_ withNSString:methodName withNSString:fileName withInt:lineNumber];
}

- (id)initWithLong:(long long int)address {
  if (self = [self initJavaLangStackTraceElementWithNSString:nil withNSString:nil withNSString:nil withInt:-1]) {
    self->address_ = address;
  }
  return self;
}

- (NSString *)description {
  [self initializeFromAddress];
  NSString *result = @"";
  result = [NSString stringWithFormat:@"%@%@", result, hexAddress_];
  result = [NSString stringWithFormat:@"%@ ", result];
  if (className__ != nil) {
    result = [NSString stringWithFormat:@"%@%@", result, className__];
    result = [NSString stringWithFormat:@"%@.", result];
  }
  if (methodName_ != nil) {
    result = [NSString stringWithFormat:@"%@%@", result, methodName_];
  }
  if (fileName_ != nil || lineNumber_ != -1) {
    result = [NSString stringWithFormat:@"%@(", result];
    if (fileName_ != nil) {
      result = [NSString stringWithFormat:@"%@%@", result, fileName_];
    }
    if (lineNumber_ != -1) {
      result = [NSString stringWithFormat:@"%@:", result];
      result = [NSString stringWithFormat:@"%@%d", result, lineNumber_];
    }
    result = [NSString stringWithFormat:@"%@)", result];
  }
  else if (className__ != nil) {
    result = [NSString stringWithFormat:@"%@()", result];
  }
  if (offset_ != nil) {
    result = [NSString stringWithFormat:@"%@ + ", result];
    result = [NSString stringWithFormat:@"%@%@", result, offset_];
  }
  return result;
}

- (void)initializeFromAddress {
  if (address_ == 0L || methodName_) {
    return;
  }
  void *shortStack[1];
  shortStack[0] = (void *)address_;
  char **stackSymbol = backtrace_symbols(shortStack, 1);
  
  // Extract hexAddress.
  char *start = strstr(*stackSymbol, "0x");  // Skip text before address.
  char *addressEnd = strstr(start, " ");
  char *hex = strndup(start, addressEnd - start);
  hexAddress_ = [[NSString alloc] initWithCString:hex
  encoding:[NSString defaultCStringEncoding]];
  free(hex);
  start = addressEnd + 1;
  
  // See if a class and method names can be extracted.
  char *leftBrace = strchr(start, '[');
  char *rightBrace = strchr(start, ']');
  if (rightBrace && strlen(rightBrace) > 4) {  // If pattern is similar to: ...] + 123
  // Save trailing function address offset, then "remove" it.
  offset_ = [[NSString alloc] initWithCString:rightBrace + 4
  encoding:[NSString defaultCStringEncoding]];
  *(rightBrace + 1) = '\0';
}
if (leftBrace && rightBrace && (rightBrace - leftBrace) > 0) {
  char *signature = leftBrace + 1;
  char *className = strsep(&signature, "[ ]");
  if (className && strlen(className) > 0) {
    IOSClass *cls = [IOSClass classForIosName:[NSString stringWithCString:className
    encoding:[NSString defaultCStringEncoding]]];
    if (cls) {
      className__ = RETAIN_([cls getName]);
    }
  }
  char *selector = strsep(&signature, "[ ]");
  if (selector) {
    char *methodName = NULL;
    
    // Strip all parameter type mangling.
    char *colon = strchr(selector, ':');
    if (colon) {
      if (strlen(selector) > 8 &&
      strncmp(selector, "initWith", 8) == 0) {
        methodName = "<init>";
      } else {
        char *paramsStart = strstr(selector, "With");
        if (paramsStart) {
          *paramsStart = '\0';
        }
        methodName = selector;
      }
    } else if (strcmp(selector, "init") == 0) {
      methodName = "<init>";
    } else if (strcmp(selector, "initialize") == 0) {
      methodName = "<clinit>";
    } else {
      methodName = selector;
    }
    if (methodName) {
      methodName_ = [[NSString alloc] initWithCString:methodName
      encoding:[NSString defaultCStringEncoding]];
    }
  }
} else {
  // Copy rest of stack symbol to methodName.
  methodName_ = [[NSString alloc] initWithCString:start
  encoding:[NSString defaultCStringEncoding]];
}
free(stackSymbol);
}

- (void)copyAllFieldsTo:(JavaLangStackTraceElement *)other {
  [super copyAllFieldsTo:other];
  other->address_ = address_;
  other->className__ = className__;
  other->fileName_ = fileName_;
  other->hexAddress_ = hexAddress_;
  other->lineNumber_ = lineNumber_;
  other->methodName_ = methodName_;
  other->offset_ = offset_;
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "getClassName", NULL, "Ljava.lang.String;", 0x1, NULL },
    { "getMethodName", NULL, "Ljava.lang.String;", 0x1, NULL },
    { "getFileName", NULL, "Ljava.lang.String;", 0x1, NULL },
    { "getLineNumber", NULL, "I", 0x1, NULL },
    { "initWithNSString:withNSString:withNSString:withInt:", "StackTraceElement", NULL, 0x1, NULL },
    { "initWithLong:", "StackTraceElement", NULL, 0x0, NULL },
    { "description", "toString", "Ljava.lang.String;", 0x1, NULL },
    { "initializeFromAddress", NULL, "V", 0x102, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "className__", "className", 0x2, "Ljava.lang.String;" },
    { "methodName_", NULL, 0x2, "Ljava.lang.String;" },
    { "fileName_", NULL, 0x2, "Ljava.lang.String;" },
    { "lineNumber_", NULL, 0x12, "I" },
    { "address_", NULL, 0x2, "J" },
    { "hexAddress_", NULL, 0x2, "Ljava.lang.String;" },
    { "offset_", NULL, 0x2, "Ljava.lang.String;" },
  };
  static J2ObjcClassInfo _JavaLangStackTraceElement = { "StackTraceElement", "java.lang", NULL, 0x1, 8, methods, 7, fields, 0, NULL};
  return &_JavaLangStackTraceElement;
}

@end