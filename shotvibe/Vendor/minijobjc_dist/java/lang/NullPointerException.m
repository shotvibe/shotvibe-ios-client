//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/NullPointerException.java
//
//  Created by raptor on 1/9/14.
//

#include "java/lang/NullPointerException.h"

@implementation JavaLangNullPointerException

+ (long long int)serialVersionUID {
  return JavaLangNullPointerException_serialVersionUID;
}

- (id)init {
  return [super init];
}

- (id)initWithNSString:(NSString *)detailMessage {
  return [super initWithNSString:detailMessage];
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "init", "NullPointerException", NULL, 0x1, NULL },
    { "initWithNSString:", "NullPointerException", NULL, 0x1, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "serialVersionUID_", NULL, 0x1a, "J" },
  };
  static J2ObjcClassInfo _JavaLangNullPointerException = { "NullPointerException", "java.lang", NULL, 0x1, 2, methods, 1, fields, 0, NULL};
  return &_JavaLangNullPointerException;
}

@end
