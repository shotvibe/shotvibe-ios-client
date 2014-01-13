//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/Double.java
//
//  Created by raptor on 1/9/14.
//

#include "IOSClass.h"
#include "IOSDoubleArray.h"
#include "java/lang/ClassCastException.h"
#include "java/lang/Double.h"
#include "java/lang/NullPointerException.h"
//#import "java/lang/NumberFormatException.h"

// From apache-harmony/classlib/modules/luni/src/main/native/luni/shared/floatbits.c,
// apache-harmony/classlib/modules/portlib/src/main/native/include/shared/hycomp.h
#define HYCONST64(x)            x##LL
#define DOUBLE_EXPONENT_MASK    HYCONST64(0x7FF0000000000000)
#define DOUBLE_MANTISSA_MASK    HYCONST64(0x000FFFFFFFFFFFFF)
#define DOUBLE_NAN_BITS         (DOUBLE_EXPONENT_MASK | HYCONST64(0x0008000000000000))

@implementation JavaLangDouble

static NSString * JavaLangDouble_FLOATING_POINT_REGEX_ = @"^[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?$";
static IOSClass * JavaLangDouble_TYPE_;

+ (NSString *)FLOATING_POINT_REGEX {
  return JavaLangDouble_FLOATING_POINT_REGEX_;
}

+ (int)EXPONENT_BIAS {
  return JavaLangDouble_EXPONENT_BIAS;
}

+ (int)EXPONENT_BITS {
  return JavaLangDouble_EXPONENT_BITS;
}

+ (int)MANTISSA_BITS {
  return JavaLangDouble_MANTISSA_BITS;
}

+ (int)NON_MANTISSA_BITS {
  return JavaLangDouble_NON_MANTISSA_BITS;
}

+ (long long int)SIGN_MASK {
  return JavaLangDouble_SIGN_MASK;
}

+ (long long int)EXPONENT_MASK {
  return JavaLangDouble_EXPONENT_MASK;
}

+ (long long int)MANTISSA_MASK {
  return JavaLangDouble_MANTISSA_MASK;
}

+ (double)MAX_VALUE {
  return JavaLangDouble_MAX_VALUE;
}

+ (double)MIN_VALUE {
  return JavaLangDouble_MIN_VALUE;
}

+ (double)NaN {
  return JavaLangDouble_NaN;
}

+ (double)POSITIVE_INFINITY {
  return JavaLangDouble_POSITIVE_INFINITY;
}

+ (double)NEGATIVE_INFINITY {
  return JavaLangDouble_NEGATIVE_INFINITY;
}

+ (int)MAX_EXPONENT {
  return JavaLangDouble_MAX_EXPONENT;
}

+ (int)MIN_EXPONENT {
  return JavaLangDouble_MIN_EXPONENT;
}

+ (IOSClass *)TYPE {
  return JavaLangDouble_TYPE_;
}

+ (int)SIZE {
  return JavaLangDouble_SIZE;
}

- (id)initWithDouble:(double)value {
  if (self = [super init]) {
    self->value_ = value;
  }
  return self;
}

- (int)compareToWithId:(JavaLangDouble *)object {
  if (object != nil && ![object isKindOfClass:[JavaLangDouble class]]) {
    @throw [[JavaLangClassCastException alloc] init];
  }
  if (object == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  return [JavaLangDouble compareWithDouble:value_ withDouble:((JavaLangDouble *) nil_chk(object))->value_];
}

- (char)charValue {
  return (char) value_;
}

+ (long long int)doubleToLongBitsWithDouble:(double)value {
  // Modified from Harmony JNI implementation.
  long long longValue = *(long long *) &value;
  if ((longValue & DOUBLE_EXPONENT_MASK) == DOUBLE_EXPONENT_MASK) {
    if (longValue & DOUBLE_MANTISSA_MASK) {
      return DOUBLE_NAN_BITS;
    }
  }
  return longValue;
}

+ (long long int)doubleToRawLongBitsWithDouble:(double)value {
  return *(long long *) &value;
}

- (double)doubleValue {
  return value_;
}

- (BOOL)isEqual:(id)object {
  if (!object || ![object isKindOfClass:[JavaLangDouble class]]) {
    return NO;
  }
  NSComparisonResult result = [self compare:object];
  return result == NSOrderedSame;
}

- (float)floatValue {
  return (float) value_;
}

- (NSUInteger)hash {
  long long int v = [JavaLangDouble doubleToLongBitsWithDouble:value_];
  return (int) (v ^ ((long long) (((unsigned long long) v) >> 32)));
}

- (int)intValue {
  return (int) value_;
}

- (BOOL)isInfinite {
  return [JavaLangDouble isInfiniteWithDouble:value_];
}

+ (BOOL)isInfiniteWithDouble:(double)d {
  return isinf(d);
}

- (BOOL)isNaN {
  return [JavaLangDouble isNaNWithDouble:value_];
}

+ (BOOL)isNaNWithDouble:(double)d {
  return isnan(d);
}

+ (double)longBitsToDoubleWithLong:(long long int)bits {
  return *(double *) &bits;
}

- (long long int)longLongValue {
  return (long long int) value_;
}

+ (double)nativeParseDoubleWithNSString:(NSString *)s {
  return [s doubleValue];
}

- (short int)shortValue {
  return (short int) value_;
}

- (NSString *)description {
  return [JavaLangDouble toStringWithDouble:value_];
}

+ (NSString *)toStringWithDouble:(double)d {
  return nil;
}

+ (int)compareWithDouble:(double)double1
              withDouble:(double)double2 {
  if (double1 > double2) {
    return 1;
  }
  if (double2 > double1) {
    return -1;
  }
  if (double1 == double2 && 0.0 != double1) {
    return 0;
  }
  if ([JavaLangDouble isNaNWithDouble:double1]) {
    if ([JavaLangDouble isNaNWithDouble:double2]) {
      return 0;
    }
    return 1;
  }
  else if ([JavaLangDouble isNaNWithDouble:double2]) {
    return -1;
  }
  long long int d1 = [JavaLangDouble doubleToRawLongBitsWithDouble:double1];
  long long int d2 = [JavaLangDouble doubleToRawLongBitsWithDouble:double2];
  return (int) ((d1 >> 63) - (d2 >> 63));
}

+ (JavaLangDouble *)valueOfWithDouble:(double)d {
  return [[JavaLangDouble alloc] initWithDouble:d];
}

+ (NSString *)toHexStringWithDouble:(double)d {
  return [NSString stringWithFormat:@"%A", d];
}

+ (void)initialize {
  if (self == [JavaLangDouble class]) {
    JavaLangDouble_TYPE_ = (IOSClass *) check_class_cast([[[IOSDoubleArray arrayWithLength:0] getClass] getComponentType], [IOSClass class]);
  }
}

- (void)copyAllFieldsTo:(JavaLangDouble *)other {
  [super copyAllFieldsTo:other];
  other->value_ = value_;
}

- (const char *)objCType {
  return "d";
}

- (void)getValue:(void *)buffer {
  *((double *) buffer) = value_;
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "initWithDouble:", "Double", NULL, 0x1, NULL },
    { "compareToWithJavaLangDouble:", "compareTo", "I", 0x1, NULL },
    { "charValue", "byteValue", "B", 0x1, NULL },
    { "doubleToLongBitsWithDouble:", "doubleToLongBits", "J", 0x109, NULL },
    { "doubleToRawLongBitsWithDouble:", "doubleToRawLongBits", "J", 0x109, NULL },
    { "doubleValue", NULL, "D", 0x1, NULL },
    { "isEqual:", "equals", "Z", 0x101, NULL },
    { "floatValue", NULL, "F", 0x1, NULL },
    { "hash", "hashCode", "I", 0x1, NULL },
    { "intValue", NULL, "I", 0x1, NULL },
    { "isInfinite", NULL, "Z", 0x1, NULL },
    { "isInfiniteWithDouble:", "isInfinite", "Z", 0x109, NULL },
    { "isNaN", NULL, "Z", 0x1, NULL },
    { "isNaNWithDouble:", "isNaN", "Z", 0x109, NULL },
    { "longBitsToDoubleWithLong:", "longBitsToDouble", "D", 0x109, NULL },
    { "longLongValue", "longValue", "J", 0x1, NULL },
    { "nativeParseDoubleWithNSString:", "nativeParseDouble", "D", 0x10a, NULL },
    { "shortValue", NULL, "S", 0x1, NULL },
    { "description", "toString", "Ljava.lang.String;", 0x1, NULL },
    { "toStringWithDouble:", "toString", "Ljava.lang.String;", 0x9, NULL },
    { "compareWithDouble:withDouble:", "compare", "I", 0x9, NULL },
    { "valueOfWithDouble:", "valueOf", "Ljava.lang.Double;", 0x9, NULL },
    { "toHexStringWithDouble:", "toHexString", "Ljava.lang.String;", 0x109, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "FLOATING_POINT_REGEX_", NULL, 0x18, "Ljava.lang.String;" },
    { "EXPONENT_BIAS_", NULL, 0x18, "I" },
    { "EXPONENT_BITS_", NULL, 0x18, "I" },
    { "MANTISSA_BITS_", NULL, 0x18, "I" },
    { "NON_MANTISSA_BITS_", NULL, 0x18, "I" },
    { "SIGN_MASK_", NULL, 0x18, "J" },
    { "EXPONENT_MASK_", NULL, 0x18, "J" },
    { "MANTISSA_MASK_", NULL, 0x18, "J" },
    { "value_", NULL, 0x12, "D" },
    { "MAX_VALUE_", NULL, 0x19, "D" },
    { "MIN_VALUE_", NULL, 0x19, "D" },
    { "NaN_", NULL, 0x19, "D" },
    { "POSITIVE_INFINITY_", NULL, 0x19, "D" },
    { "NEGATIVE_INFINITY_", NULL, 0x19, "D" },
    { "MAX_EXPONENT_", NULL, 0x19, "I" },
    { "MIN_EXPONENT_", NULL, 0x19, "I" },
    { "TYPE_", NULL, 0x19, "Ljava.lang.Class;" },
    { "SIZE_", NULL, 0x19, "I" },
  };
  static J2ObjcClassInfo _JavaLangDouble = { "Double", "java.lang", NULL, 0x11, 23, methods, 18, fields, 0, NULL};
  return &_JavaLangDouble;
}

@end