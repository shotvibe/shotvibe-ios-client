//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/Enum.java
//
//  Created by raptor on 1/9/14.
//

#include "IOSClass.h"
#include "java/lang/ClassCastException.h"
#include "java/lang/CloneNotSupportedException.h"
#include "java/lang/Enum.h"

@implementation JavaLangEnum

+ (long long int)serialVersionUID {
  return JavaLangEnum_serialVersionUID;
}

- (id)initWithNSString:(NSString *)name
               withInt:(int)ordinal {
  if (self = [super init]) {
    self->name__ = name;
    self->ordinal__ = ordinal;
  }
  return self;
}

- (NSString *)name {
  return name__;
}

- (int)ordinal {
  return ordinal__;
}

- (NSString *)description {
  return name__;
}

- (BOOL)isEqual:(id)other {
  return self == other;
}

- (NSUInteger)hash {
  return ordinal__ + (name__ == nil ? 0 : [name__ hash]);
}

- (id)clone {
  @throw [[JavaLangCloneNotSupportedException alloc] initWithNSString:@"Enums may not be cloned"];
}

- (int)compareToWithId:(JavaLangEnum *)o {
  if (o != nil && ![o isKindOfClass:[JavaLangEnum class]]) {
    @throw [[JavaLangClassCastException alloc] init];
  }
  return ordinal__ - ((JavaLangEnum *) nil_chk(o))->ordinal__;
}

- (IOSClass *)getDeclaringClass {
  IOSClass *myClass = [self getClass];
  IOSClass *mySuperClass = [myClass getSuperclass];
  if ([[IOSClass classWithClass:[JavaLangEnum class]] isEqual:mySuperClass]) {
    return (IOSClass *) check_class_cast(myClass, [IOSClass class]);
  }
  return (IOSClass *) check_class_cast(mySuperClass, [IOSClass class]);
}

- (void)copyAllFieldsTo:(JavaLangEnum *)other {
  [super copyAllFieldsTo:other];
  other->name__ = name__;
  other->ordinal__ = ordinal__;
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "initWithNSString:withInt:", "Enum", NULL, 0x4, NULL },
    { "name", NULL, "Ljava.lang.String;", 0x11, NULL },
    { "ordinal", NULL, "I", 0x11, NULL },
    { "description", "toString", "Ljava.lang.String;", 0x1, NULL },
    { "isEqual:", "equals", "Z", 0x11, NULL },
    { "hash", "hashCode", "I", 0x11, NULL },
    { "clone", NULL, "Ljava.lang.Object;", 0x14, "Ljava.lang.CloneNotSupportedException;" },
    { "compareToWithId:", "compareTo", "I", 0x11, NULL },
    { "getDeclaringClass", NULL, "Ljava.lang.Class;", 0x11, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "serialVersionUID_", NULL, 0x1a, "J" },
    { "name__", "name", 0x12, "Ljava.lang.String;" },
    { "ordinal__", "ordinal", 0x12, "I" },
  };
  static J2ObjcClassInfo _JavaLangEnum = { "Enum", "java.lang", NULL, 0x401, 9, methods, 3, fields, 0, NULL};
  return &_JavaLangEnum;
}

@end