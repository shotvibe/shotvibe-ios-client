//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/IllegalArgumentException.java
//
//  Created by raptor on 1/9/14.
//

#include "java/lang/IllegalArgumentException.h"
#include "java/lang/Throwable.h"

@implementation JavaLangIllegalArgumentException

+ (long long int)serialVersionUID {
  return JavaLangIllegalArgumentException_serialVersionUID;
}

- (id)init {
  return [super init];
}

- (id)initWithNSString:(NSString *)detailMessage {
  return [super initWithNSString:detailMessage];
}

- (id)initWithNSString:(NSString *)message
 withJavaLangThrowable:(JavaLangThrowable *)cause {
  return [super initWithNSString:message withJavaLangThrowable:cause];
}

- (id)initWithJavaLangThrowable:(JavaLangThrowable *)cause {
  return [super initWithNSString:(cause == nil ? nil : [cause description]) withJavaLangThrowable:cause];
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "init", "IllegalArgumentException", NULL, 0x1, NULL },
    { "initWithNSString:", "IllegalArgumentException", NULL, 0x1, NULL },
    { "initWithNSString:withJavaLangThrowable:", "IllegalArgumentException", NULL, 0x1, NULL },
    { "initWithJavaLangThrowable:", "IllegalArgumentException", NULL, 0x1, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "serialVersionUID_", NULL, 0x1a, "J" },
  };
  static J2ObjcClassInfo _JavaLangIllegalArgumentException = { "IllegalArgumentException", "java.lang", NULL, 0x1, 4, methods, 1, fields, 0, NULL};
  return &_JavaLangIllegalArgumentException;
}

@end