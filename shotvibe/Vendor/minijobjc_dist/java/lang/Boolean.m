//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/Boolean.java
//
//  Created by raptor on 1/9/14.
//

#include "IOSBooleanArray.h"
#include "IOSClass.h"
#include "java/lang/Boolean.h"
#include "java/lang/ClassCastException.h"
#include "java/lang/NullPointerException.h"

@implementation JavaLangBoolean

static IOSClass * JavaLangBoolean_TYPE_;
static JavaLangBoolean * JavaLangBoolean_TRUE__;
static JavaLangBoolean * JavaLangBoolean_FALSE__;

+ (IOSClass *)TYPE {
  return JavaLangBoolean_TYPE_;
}

+ (JavaLangBoolean *)getTRUE {
  return JavaLangBoolean_TRUE__;
}

+ (JavaLangBoolean *)getFALSE {
  return JavaLangBoolean_FALSE__;
}

- (id)initWithNSString:(NSString *)string {
  return [self initJavaLangBooleanWithBoolean:[JavaLangBoolean parseBooleanWithNSString:string]];
}

- (id)initJavaLangBooleanWithBoolean:(BOOL)value {
  if (self = [super init]) {
    self->value_ = value;
  }
  return self;
}

- (id)initWithBoolean:(BOOL)value {
  return [self initJavaLangBooleanWithBoolean:value];
}

- (BOOL)booleanValue {
  return value_;
}

- (BOOL)isEqual:(id)o {
  return (o == self) || (([o isKindOfClass:[JavaLangBoolean class]]) && (value_ == ((JavaLangBoolean *) nil_chk(o))->value_));
}

- (int)compareToWithId:(JavaLangBoolean *)that {
  if (that != nil && ![that isKindOfClass:[JavaLangBoolean class]]) {
    @throw [[JavaLangClassCastException alloc] init];
  }
  if (that == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  if (self->value_ == ((JavaLangBoolean *) nil_chk(that))->value_) {
    return 0;
  }
  return self->value_ ? 1 : -1;
}

+ (int)compareWithBoolean:(BOOL)lhs
              withBoolean:(BOOL)rhs {
  return lhs == rhs ? 0 : lhs ? 1 : -1;
}

- (NSUInteger)hash {
  return value_ ? 1231 : 1237;
}

- (NSString *)description {
  return [NSString valueOfBool:value_];
}

+ (BOOL)parseBooleanWithNSString:(NSString *)s {
  return [@"true" equalsIgnoreCase:s];
}

+ (NSString *)toStringWithBoolean:(BOOL)value {
  return [NSString valueOfBool:value];
}

+ (JavaLangBoolean *)valueOfWithNSString:(NSString *)string {
  return [JavaLangBoolean parseBooleanWithNSString:string] ? JavaLangBoolean_TRUE__ : JavaLangBoolean_FALSE__;
}

+ (JavaLangBoolean *)valueOfWithBoolean:(BOOL)b {
  return b ? JavaLangBoolean_TRUE__ : JavaLangBoolean_FALSE__;
}

+ (void)initialize {
  if (self == [JavaLangBoolean class]) {
    JavaLangBoolean_TYPE_ = (IOSClass *) check_class_cast([[[IOSBooleanArray arrayWithLength:0] getClass] getComponentType], [IOSClass class]);
    JavaLangBoolean_TRUE__ = [[JavaLangBoolean alloc] initWithBoolean:YES];
    JavaLangBoolean_FALSE__ = [[JavaLangBoolean alloc] initWithBoolean:NO];
  }
}

- (void)copyAllFieldsTo:(JavaLangBoolean *)other {
  [super copyAllFieldsTo:other];
  other->value_ = value_;
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "initWithNSString:", "Boolean", NULL, 0x1, NULL },
    { "initWithBoolean:", "Boolean", NULL, 0x1, NULL },
    { "booleanValue", NULL, "Z", 0x1, NULL },
    { "isEqual:", "equals", "Z", 0x1, NULL },
    { "compareToWithJavaLangBoolean:", "compareTo", "I", 0x1, NULL },
    { "compareWithBoolean:withBoolean:", "compare", "I", 0x9, NULL },
    { "hash", "hashCode", "I", 0x1, NULL },
    { "description", "toString", "Ljava.lang.String;", 0x1, NULL },
    { "parseBooleanWithNSString:", "parseBoolean", "Z", 0x9, NULL },
    { "toStringWithBoolean:", "toString", "Ljava.lang.String;", 0x9, NULL },
    { "valueOfWithNSString:", "valueOf", "Ljava.lang.Boolean;", 0x9, NULL },
    { "valueOfWithBoolean:", "valueOf", "Ljava.lang.Boolean;", 0x9, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "value_", NULL, 0x12, "Z" },
    { "TYPE_", NULL, 0x19, "Ljava.lang.Class;" },
    { "TRUE__", "TRUE", 0x19, "Ljava.lang.Boolean;" },
    { "FALSE__", "FALSE", 0x19, "Ljava.lang.Boolean;" },
  };
  static J2ObjcClassInfo _JavaLangBoolean = { "Boolean", "java.lang", NULL, 0x11, 12, methods, 4, fields, 0, NULL};
  return &_JavaLangBoolean;
}

@end
