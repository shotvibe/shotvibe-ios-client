//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/CloneNotSupportedException.java
//
//  Created by raptor on 1/9/14.
//

#include "java/lang/CloneNotSupportedException.h"

@implementation JavaLangCloneNotSupportedException

+ (long long int)serialVersionUID {
  return JavaLangCloneNotSupportedException_serialVersionUID;
}

- (id)init {
  return [super init];
}

- (id)initWithNSString:(NSString *)detailMessage {
  return [super initWithNSString:detailMessage];
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "init", "CloneNotSupportedException", NULL, 0x1, NULL },
    { "initWithNSString:", "CloneNotSupportedException", NULL, 0x1, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "serialVersionUID_", NULL, 0x1a, "J" },
  };
  static J2ObjcClassInfo _JavaLangCloneNotSupportedException = { "CloneNotSupportedException", "java.lang", NULL, 0x1, 2, methods, 1, fields, 0, NULL};
  return &_JavaLangCloneNotSupportedException;
}

@end