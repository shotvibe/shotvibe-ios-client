//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/StringIndexOutOfBoundsException.java
//
//  Created by raptor on 1/9/14.
//

#include "java/lang/StringIndexOutOfBoundsException.h"

@implementation JavaLangStringIndexOutOfBoundsException

+ (long long int)serialVersionUID {
  return JavaLangStringIndexOutOfBoundsException_serialVersionUID;
}

- (id)init {
  return [super init];
}

- (id)initWithInt:(int)index {
  return [super initWithNSString:[NSString stringWithFormat:@"String index out of range: %d", index]];
}

- (id)initWithNSString:(NSString *)detailMessage {
  return [super initWithNSString:detailMessage];
}

- (id)initWithNSString:(NSString *)s
               withInt:(int)index {
  return [self initJavaLangStringIndexOutOfBoundsExceptionWithInt:[((NSString *) nil_chk(s)) length] withInt:index];
}

- (id)initJavaLangStringIndexOutOfBoundsExceptionWithInt:(int)sourceLength
                                                 withInt:(int)index {
  return [super initWithNSString:[NSString stringWithFormat:@"length=%d; index=%d", sourceLength, index]];
}

- (id)initWithInt:(int)sourceLength
          withInt:(int)index {
  return [self initJavaLangStringIndexOutOfBoundsExceptionWithInt:sourceLength withInt:index];
}

- (id)initWithNSString:(NSString *)s
               withInt:(int)offset
               withInt:(int)count {
  return [self initJavaLangStringIndexOutOfBoundsExceptionWithInt:[((NSString *) nil_chk(s)) length] withInt:offset withInt:count];
}

- (id)initJavaLangStringIndexOutOfBoundsExceptionWithInt:(int)sourceLength
                                                 withInt:(int)offset
                                                 withInt:(int)count {
  return [super initWithNSString:[NSString stringWithFormat:@"length=%d; regionStart=%d; regionLength=%d", sourceLength, offset, count]];
}

- (id)initWithInt:(int)sourceLength
          withInt:(int)offset
          withInt:(int)count {
  return [self initJavaLangStringIndexOutOfBoundsExceptionWithInt:sourceLength withInt:offset withInt:count];
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "init", "StringIndexOutOfBoundsException", NULL, 0x1, NULL },
    { "initWithInt:", "StringIndexOutOfBoundsException", NULL, 0x1, NULL },
    { "initWithNSString:", "StringIndexOutOfBoundsException", NULL, 0x1, NULL },
    { "initWithNSString:withInt:", "StringIndexOutOfBoundsException", NULL, 0x1, NULL },
    { "initWithInt:withInt:", "StringIndexOutOfBoundsException", NULL, 0x1, NULL },
    { "initWithNSString:withInt:withInt:", "StringIndexOutOfBoundsException", NULL, 0x1, NULL },
    { "initWithInt:withInt:withInt:", "StringIndexOutOfBoundsException", NULL, 0x1, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "serialVersionUID_", NULL, 0x1a, "J" },
  };
  static J2ObjcClassInfo _JavaLangStringIndexOutOfBoundsException = { "StringIndexOutOfBoundsException", "java.lang", NULL, 0x1, 7, methods, 1, fields, 0, NULL};
  return &_JavaLangStringIndexOutOfBoundsException;
}

@end