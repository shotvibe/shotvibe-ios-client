//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/ClassNotFoundException.java
//
//  Created by raptor on 1/9/14.
//

#include "java/lang/ClassNotFoundException.h"
#include "java/lang/Throwable.h"

@implementation JavaLangClassNotFoundException

+ (long long int)serialVersionUID {
  return JavaLangClassNotFoundException_serialVersionUID;
}

- (id)init {
  return [super initWithJavaLangThrowable:(JavaLangThrowable *) check_class_cast(nil, [JavaLangThrowable class])];
}

- (id)initWithNSString:(NSString *)detailMessage {
  return [super initWithNSString:detailMessage withJavaLangThrowable:nil];
}

- (id)initWithNSString:(NSString *)detailMessage
 withJavaLangThrowable:(JavaLangThrowable *)exception {
  if (self = [super initWithNSString:detailMessage]) {
    ex_ = exception;
  }
  return self;
}

- (JavaLangThrowable *)getException {
  return ex_;
}

- (JavaLangThrowable *)getCause {
  return ex_;
}

- (void)copyAllFieldsTo:(JavaLangClassNotFoundException *)other {
  [super copyAllFieldsTo:other];
  other->ex_ = ex_;
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "init", "ClassNotFoundException", NULL, 0x1, NULL },
    { "initWithNSString:", "ClassNotFoundException", NULL, 0x1, NULL },
    { "initWithNSString:withJavaLangThrowable:", "ClassNotFoundException", NULL, 0x1, NULL },
    { "getException", NULL, "Ljava.lang.Throwable;", 0x1, NULL },
    { "getCause", NULL, "Ljava.lang.Throwable;", 0x1, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "serialVersionUID_", NULL, 0x1a, "J" },
    { "ex_", NULL, 0x2, "Ljava.lang.Throwable;" },
  };
  static J2ObjcClassInfo _JavaLangClassNotFoundException = { "ClassNotFoundException", "java.lang", NULL, 0x1, 5, methods, 2, fields, 0, NULL};
  return &_JavaLangClassNotFoundException;
}

@end