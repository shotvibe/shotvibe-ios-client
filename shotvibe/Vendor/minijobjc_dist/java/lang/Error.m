//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/Error.java
//
//  Created by raptor on 1/9/14.
//

#include "java/lang/Error.h"
#include "java/lang/Throwable.h"

@implementation JavaLangError

+ (long long int)serialVersionUID {
  return JavaLangError_serialVersionUID;
}

- (id)init {
  return [super init];
}

- (id)initWithNSString:(NSString *)detailMessage {
  return [super initWithNSString:detailMessage];
}

- (id)initWithNSString:(NSString *)detailMessage
 withJavaLangThrowable:(JavaLangThrowable *)throwable {
  return [super initWithNSString:detailMessage withJavaLangThrowable:throwable];
}

- (id)initWithJavaLangThrowable:(JavaLangThrowable *)throwable {
  return [super initWithJavaLangThrowable:throwable];
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "init", "Error", NULL, 0x1, NULL },
    { "initWithNSString:", "Error", NULL, 0x1, NULL },
    { "initWithNSString:withJavaLangThrowable:", "Error", NULL, 0x1, NULL },
    { "initWithJavaLangThrowable:", "Error", NULL, 0x1, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "serialVersionUID_", NULL, 0x1a, "J" },
  };
  static J2ObjcClassInfo _JavaLangError = { "Error", "java.lang", NULL, 0x1, 4, methods, 1, fields, 0, NULL};
  return &_JavaLangError;
}

@end
