//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/Short.java
//
//  Created by raptor on 1/9/14.
//

#include "IOSClass.h"
#include "IOSObjectArray.h"
#include "IOSShortArray.h"
#include "java/lang/ClassCastException.h"
#include "java/lang/Integer.h"
#include "java/lang/NullPointerException.h"
#include "java/lang/Short.h"

@implementation JavaLangShort

static IOSClass * JavaLangShort_TYPE_;

+ (short int)MAX_VALUE {
  return JavaLangShort_MAX_VALUE;
}

+ (short int)MIN_VALUE {
  return JavaLangShort_MIN_VALUE;
}

+ (int)SIZE {
  return JavaLangShort_SIZE;
}

+ (IOSClass *)TYPE {
  return JavaLangShort_TYPE_;
}

- (id)initWithShort:(short int)value {
  if (self = [super init]) {
    self->value_ = value;
  }
  return self;
}

- (char)charValue {
  return (char) value_;
}

- (int)compareToWithId:(JavaLangShort *)object {
  if (object != nil && ![object isKindOfClass:[JavaLangShort class]]) {
    @throw [[JavaLangClassCastException alloc] init];
  }
  if (object == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  return value_ > ((JavaLangShort *) nil_chk(object))->value_ ? 1 : (value_ < object->value_ ? -1 : 0);
}

+ (int)compareWithShort:(short int)lhs
              withShort:(short int)rhs {
  return lhs > rhs ? 1 : (lhs < rhs ? -1 : 0);
}

- (double)doubleValue {
  return value_;
}

- (BOOL)isEqual:(id)object {
  return ([object isKindOfClass:[JavaLangShort class]]) && (value_ == ((JavaLangShort *) nil_chk(object))->value_);
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

+ (NSString *)toStringWithShort:(short int)value {
  return [JavaLangInteger toStringWithInt:value];
}

+ (short int)reverseBytesWithShort:(short int)s {
  int high = (s >> 8) & (int) 0xFF;
  int low = (s & (int) 0xFF) << 8;
  return (short int) (low | high);
}

+ (JavaLangShort *)valueOfWithShort:(short int)s {
  if (s < -128 || s > 127) {
    return [[JavaLangShort alloc] initWithShort:s];
  }
  return IOSObjectArray_Get(nil_chk([JavaLangShort_valueOfCache CACHE]), s + 128);
}

+ (void)initialize {
  if (self == [JavaLangShort class]) {
    JavaLangShort_TYPE_ = (IOSClass *) check_class_cast([[[IOSShortArray arrayWithLength:0] getClass] getComponentType], [IOSClass class]);
  }
}

- (void)copyAllFieldsTo:(JavaLangShort *)other {
  [super copyAllFieldsTo:other];
  other->value_ = value_;
}

- (const char *)objCType {
  return "s";
}

- (void)getValue:(void *)buffer {
  *((short int *) buffer) = value_;
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "initWithShort:", "Short", NULL, 0x1, NULL },
    { "charValue", "byteValue", "B", 0x1, NULL },
    { "compareToWithJavaLangShort:", "compareTo", "I", 0x1, NULL },
    { "compareWithShort:withShort:", "compare", "I", 0x9, NULL },
    { "doubleValue", NULL, "D", 0x1, NULL },
    { "isEqual:", "equals", "Z", 0x1, NULL },
    { "floatValue", NULL, "F", 0x1, NULL },
    { "hash", "hashCode", "I", 0x1, NULL },
    { "intValue", NULL, "I", 0x1, NULL },
    { "longLongValue", "longValue", "J", 0x1, NULL },
    { "shortValue", NULL, "S", 0x1, NULL },
    { "description", "toString", "Ljava.lang.String;", 0x1, NULL },
    { "toStringWithShort:", "toString", "Ljava.lang.String;", 0x9, NULL },
    { "reverseBytesWithShort:", "reverseBytes", "S", 0x9, NULL },
    { "valueOfWithShort:", "valueOf", "Ljava.lang.Short;", 0x9, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "value_", NULL, 0x12, "S" },
    { "MAX_VALUE_", NULL, 0x19, "S" },
    { "MIN_VALUE_", NULL, 0x19, "S" },
    { "SIZE_", NULL, 0x19, "I" },
    { "TYPE_", NULL, 0x19, "Ljava.lang.Class;" },
  };
  static J2ObjcClassInfo _JavaLangShort = { "Short", "java.lang", NULL, 0x11, 15, methods, 5, fields, 0, NULL};
  return &_JavaLangShort;
}

@end
@implementation JavaLangShort_valueOfCache

static IOSObjectArray * JavaLangShort_valueOfCache_CACHE_;

+ (IOSObjectArray *)CACHE {
  return JavaLangShort_valueOfCache_CACHE_;
}

- (id)init {
  return [super init];
}

+ (void)initialize {
  if (self == [JavaLangShort_valueOfCache class]) {
    JavaLangShort_valueOfCache_CACHE_ = [IOSObjectArray arrayWithLength:256 type:[IOSClass classWithClass:[JavaLangShort class]]];
    {
      for (int i = -128; i <= 127; i++) {
        (void) IOSObjectArray_Set(JavaLangShort_valueOfCache_CACHE_, i + 128, [[JavaLangShort alloc] initWithShort:(short int) i]);
      }
    }
  }
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "init", NULL, NULL, 0x0, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "CACHE_", NULL, 0x1a, "[Ljava.lang.Short;" },
  };
  static J2ObjcClassInfo _JavaLangShort_valueOfCache = { "valueOfCache", "java.lang", "Short", 0x8, 1, methods, 1, fields, 0, NULL};
  return &_JavaLangShort_valueOfCache;
}

@end
