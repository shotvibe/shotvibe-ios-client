//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/Byte.java
//
//  Created by raptor on 1/9/14.
//

#include "IOSByteArray.h"
#include "IOSClass.h"
#include "IOSObjectArray.h"
#include "java/lang/Byte.h"
#include "java/lang/ClassCastException.h"
#include "java/lang/Integer.h"
#include "java/lang/NullPointerException.h"

@implementation JavaLangByte

static IOSObjectArray * JavaLangByte_CACHE_;
static IOSClass * JavaLangByte_TYPE_;

+ (char)MAX_VALUE {
  return JavaLangByte_MAX_VALUE;
}

+ (char)MIN_VALUE {
  return JavaLangByte_MIN_VALUE;
}

+ (int)SIZE {
  return JavaLangByte_SIZE;
}

+ (IOSObjectArray *)CACHE {
  return JavaLangByte_CACHE_;
}

+ (IOSClass *)TYPE {
  return JavaLangByte_TYPE_;
}

- (id)initWithByte:(char)value {
  if (self = [super init]) {
    self->value_ = value;
  }
  return self;
}

- (char)charValue {
  return value_;
}

- (int)compareToWithId:(JavaLangByte *)object {
  if (object != nil && ![object isKindOfClass:[JavaLangByte class]]) {
    @throw [[JavaLangClassCastException alloc] init];
  }
  if (object == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  return value_ > ((JavaLangByte *) nil_chk(object))->value_ ? 1 : (value_ < object->value_ ? -1 : 0);
}

+ (int)compareWithByte:(char)lhs
              withByte:(char)rhs {
  return lhs > rhs ? 1 : (lhs < rhs ? -1 : 0);
}

- (double)doubleValue {
  return value_;
}

- (BOOL)isEqual:(id)object {
  return (object == self) || (([object isKindOfClass:[JavaLangByte class]]) && (value_ == ((JavaLangByte *) nil_chk(object))->value_));
}

- (float)floatValue {
  return value_;
}

- (NSUInteger)hash {
  return value_;
}

- (int)intValue {
  return value_;
}

- (long long int)longLongValue {
  return value_;
}

- (short int)shortValue {
  return value_;
}

- (NSString *)description {
  return [JavaLangInteger toStringWithInt:value_];
}

+ (NSString *)toStringWithByte:(char)value {
  return [JavaLangInteger toStringWithInt:value];
}

+ (JavaLangByte *)valueOfWithByte:(char)b {
  @synchronized (JavaLangByte_CACHE_) {
    int idx = b - JavaLangByte_MIN_VALUE;
    JavaLangByte *result = IOSObjectArray_Get(nil_chk(JavaLangByte_CACHE_), idx);
    return (result == nil ? IOSObjectArray_Set(JavaLangByte_CACHE_, idx, [[JavaLangByte alloc] initWithByte:b]) : result);
  }
}

+ (void)initialize {
  if (self == [JavaLangByte class]) {
    JavaLangByte_CACHE_ = [IOSObjectArray arrayWithLength:256 type:[IOSClass classWithClass:[JavaLangByte class]]];
    JavaLangByte_TYPE_ = (IOSClass *) check_class_cast([[[IOSByteArray arrayWithLength:0] getClass] getComponentType], [IOSClass class]);
  }
}

- (void)copyAllFieldsTo:(JavaLangByte *)other {
  [super copyAllFieldsTo:other];
  other->value_ = value_;
}

- (const char *)objCType {
  return "c";
}

- (void)getValue:(void *)buffer {
  *((char *) buffer) = value_;
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "initWithByte:", "Byte", NULL, 0x1, NULL },
    { "charValue", "byteValue", "B", 0x1, NULL },
    { "compareToWithJavaLangByte:", "compareTo", "I", 0x1, NULL },
    { "compareWithByte:withByte:", "compare", "I", 0x9, NULL },
    { "doubleValue", NULL, "D", 0x1, NULL },
    { "isEqual:", "equals", "Z", 0x1, NULL },
    { "floatValue", NULL, "F", 0x1, NULL },
    { "hash", "hashCode", "I", 0x1, NULL },
    { "intValue", NULL, "I", 0x1, NULL },
    { "longLongValue", "longValue", "J", 0x1, NULL },
    { "shortValue", NULL, "S", 0x1, NULL },
    { "description", "toString", "Ljava.lang.String;", 0x1, NULL },
    { "toStringWithByte:", "toString", "Ljava.lang.String;", 0x9, NULL },
    { "valueOfWithByte:", "valueOf", "Ljava.lang.Byte;", 0x9, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "value_", NULL, 0x12, "B" },
    { "MAX_VALUE_", NULL, 0x19, "B" },
    { "MIN_VALUE_", NULL, 0x19, "B" },
    { "SIZE_", NULL, 0x19, "I" },
    { "CACHE_", NULL, 0x1a, "[Ljava.lang.Byte;" },
    { "TYPE_", NULL, 0x19, "Ljava.lang.Class;" },
  };
  static J2ObjcClassInfo _JavaLangByte = { "Byte", "java.lang", NULL, 0x11, 14, methods, 6, fields, 0, NULL};
  return &_JavaLangByte;
}

@end
