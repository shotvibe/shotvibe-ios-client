//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/Void.java
//
//  Created by raptor on 3/11/14.
//

#include "IOSClass.h"
#include "java/lang/Void.h"

@implementation JavaLangVoid

static IOSClass * JavaLangVoid_TYPE_;

+ (IOSClass *)TYPE {
  return JavaLangVoid_TYPE_;
}

- (id)init {
  return [super init];
}

+ (void)initialize {
  if (self == [JavaLangVoid class]) {
    JavaLangVoid_TYPE_ = [IOSClass voidClass];
  }
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "init", NULL, NULL, 0x1, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "TYPE_", NULL, 0x19, "Ljava.lang.Class;" },
  };
  static J2ObjcClassInfo _JavaLangVoid = { "Void", "java.lang", NULL, 0x11, 1, methods, 1, fields, 0, NULL};
  return &_JavaLangVoid;
}

@end
