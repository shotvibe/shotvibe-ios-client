//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/Character.java
//
//  Created by raptor on 1/9/14.
//

#include "IOSCharArray.h"
#include "IOSClass.h"
#include "IOSIntArray.h"
#include "IOSObjectArray.h"
#include "java/lang/ArrayIndexOutOfBoundsException.h"
#include "java/lang/CharSequence.h"
#include "java/lang/Character.h"
#include "java/lang/ClassCastException.h"
#include "java/lang/IllegalArgumentException.h"
#include "java/lang/IndexOutOfBoundsException.h"
#include "java/lang/NullPointerException.h"
#include "java/lang/StringIndexOutOfBoundsException.h"

@implementation JavaLangCharacter

static IOSClass * JavaLangCharacter_TYPE_;
static unichar JavaLangCharacter_MIN_HIGH_SURROGATE_;
static unichar JavaLangCharacter_MAX_HIGH_SURROGATE_;
static unichar JavaLangCharacter_MIN_LOW_SURROGATE_;
static unichar JavaLangCharacter_MAX_LOW_SURROGATE_;
static unichar JavaLangCharacter_MIN_SURROGATE_;
static unichar JavaLangCharacter_MAX_SURROGATE_;
static IOSIntArray * JavaLangCharacter_digitKeys_;
static IOSIntArray * JavaLangCharacter_digitValues_;

+ (long long int)serialVersionUID {
  return JavaLangCharacter_serialVersionUID;
}

+ (unichar)MIN_VALUE {
  return JavaLangCharacter_MIN_VALUE;
}

+ (unichar)MAX_VALUE {
  return JavaLangCharacter_MAX_VALUE;
}

+ (int)MIN_RADIX {
  return JavaLangCharacter_MIN_RADIX;
}

+ (int)MAX_RADIX {
  return JavaLangCharacter_MAX_RADIX;
}

+ (IOSClass *)TYPE {
  return JavaLangCharacter_TYPE_;
}

+ (unichar)MIN_HIGH_SURROGATE {
  return JavaLangCharacter_MIN_HIGH_SURROGATE_;
}

+ (unichar)MAX_HIGH_SURROGATE {
  return JavaLangCharacter_MAX_HIGH_SURROGATE_;
}

+ (unichar)MIN_LOW_SURROGATE {
  return JavaLangCharacter_MIN_LOW_SURROGATE_;
}

+ (unichar)MAX_LOW_SURROGATE {
  return JavaLangCharacter_MAX_LOW_SURROGATE_;
}

+ (unichar)MIN_SURROGATE {
  return JavaLangCharacter_MIN_SURROGATE_;
}

+ (unichar)MAX_SURROGATE {
  return JavaLangCharacter_MAX_SURROGATE_;
}

+ (int)MIN_SUPPLEMENTARY_CODE_POINT {
  return JavaLangCharacter_MIN_SUPPLEMENTARY_CODE_POINT;
}

+ (int)MIN_CODE_POINT {
  return JavaLangCharacter_MIN_CODE_POINT;
}

+ (int)MAX_CODE_POINT {
  return JavaLangCharacter_MAX_CODE_POINT;
}

+ (int)SIZE {
  return JavaLangCharacter_SIZE;
}

+ (IOSIntArray *)digitKeys {
  return JavaLangCharacter_digitKeys_;
}

+ (IOSIntArray *)digitValues {
  return JavaLangCharacter_digitValues_;
}

+ (int)CACHE_LEN {
  return JavaLangCharacter_CACHE_LEN;
}

- (id)initWithChar:(unichar)value {
  if (self = [super init]) {
    self->value_ = value;
  }
  return self;
}

- (unichar)charValue {
  return value_;
}

+ (void)checkValidCodePointWithInt:(int)codePoint {
  if (![JavaLangCharacter isValidCodePointWithInt:codePoint]) {
    @throw [[JavaLangIllegalArgumentException alloc] initWithNSString:[NSString stringWithFormat:@"Invalid code point: %d", codePoint]];
  }
}

- (int)compareToWithId:(JavaLangCharacter *)c {
  if (c != nil && ![c isKindOfClass:[JavaLangCharacter class]]) {
    @throw [[JavaLangClassCastException alloc] init];
  }
  return value_ - ((JavaLangCharacter *) nil_chk(c))->value_;
}

+ (int)compareWithChar:(unichar)lhs
              withChar:(unichar)rhs {
  return lhs - rhs;
}

+ (JavaLangCharacter *)valueOfWithChar:(unichar)c {
  if (c >= JavaLangCharacter_CACHE_LEN) {
    return [[JavaLangCharacter alloc] initWithChar:c];
  }
  return IOSObjectArray_Get(nil_chk([JavaLangCharacter_valueOfCache CACHE]), c);
}

+ (BOOL)isValidCodePointWithInt:(int)codePoint {
  return (JavaLangCharacter_MIN_CODE_POINT <= codePoint && JavaLangCharacter_MAX_CODE_POINT >= codePoint);
}

+ (BOOL)isSupplementaryCodePointWithInt:(int)codePoint {
  return (JavaLangCharacter_MIN_SUPPLEMENTARY_CODE_POINT <= codePoint && JavaLangCharacter_MAX_CODE_POINT >= codePoint);
}

+ (BOOL)isHighSurrogateWithChar:(unichar)ch {
  return (JavaLangCharacter_MIN_HIGH_SURROGATE_ <= ch && JavaLangCharacter_MAX_HIGH_SURROGATE_ >= ch);
}

+ (BOOL)isLowSurrogateWithChar:(unichar)ch {
  return (JavaLangCharacter_MIN_LOW_SURROGATE_ <= ch && JavaLangCharacter_MAX_LOW_SURROGATE_ >= ch);
}

+ (BOOL)isSurrogateWithChar:(unichar)ch {
  return ch >= JavaLangCharacter_MIN_SURROGATE_ && ch <= JavaLangCharacter_MAX_SURROGATE_;
}

+ (BOOL)isSurrogatePairWithChar:(unichar)high
                       withChar:(unichar)low {
  return ([JavaLangCharacter isHighSurrogateWithChar:high] && [JavaLangCharacter isLowSurrogateWithChar:low]);
}

+ (int)charCountWithInt:(int)codePoint {
  return (codePoint >= (int) 0x10000 ? 2 : 1);
}

+ (int)toCodePointWithChar:(unichar)high
                  withChar:(unichar)low {
  int h = (high & (int) 0x3FF) << 10;
  int l = low & (int) 0x3FF;
  return (h | l) + (int) 0x10000;
}

+ (int)codePointAtWithJavaLangCharSequence:(id<JavaLangCharSequence>)seq
                                   withInt:(int)index {
  if (seq == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  int len = [((id<JavaLangCharSequence>) nil_chk(seq)) sequenceLength];
  if (index < 0 || index >= len) {
    @throw [[JavaLangStringIndexOutOfBoundsException alloc] initWithInt:index];
  }
  unichar high = [seq charAtWithInt:index++];
  if (index >= len) {
    return high;
  }
  unichar low = [seq charAtWithInt:index];
  if ([JavaLangCharacter isSurrogatePairWithChar:high withChar:low]) {
    return [JavaLangCharacter toCodePointWithChar:high withChar:low];
  }
  return high;
}

+ (int)codePointAtWithCharArray:(IOSCharArray *)seq
                        withInt:(int)index {
  if (seq == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  int len = (int) [((IOSCharArray *) nil_chk(seq)) count];
  if (index < 0 || index >= len) {
    @throw [[JavaLangArrayIndexOutOfBoundsException alloc] initWithInt:index];
  }
  unichar high = IOSCharArray_Get(seq, index++);
  if (index >= len) {
    return high;
  }
  unichar low = IOSCharArray_Get(seq, index);
  if ([JavaLangCharacter isSurrogatePairWithChar:high withChar:low]) {
    return [JavaLangCharacter toCodePointWithChar:high withChar:low];
  }
  return high;
}

+ (int)codePointAtWithCharArray:(IOSCharArray *)seq
                        withInt:(int)index
                        withInt:(int)limit {
  if (index < 0 || index >= limit || limit < 0 || limit > (int) [((IOSCharArray *) nil_chk(seq)) count]) {
    @throw [[JavaLangArrayIndexOutOfBoundsException alloc] init];
  }
  unichar high = IOSCharArray_Get(nil_chk(seq), index++);
  if (index >= limit) {
    return high;
  }
  unichar low = IOSCharArray_Get(seq, index);
  if ([JavaLangCharacter isSurrogatePairWithChar:high withChar:low]) {
    return [JavaLangCharacter toCodePointWithChar:high withChar:low];
  }
  return high;
}

+ (int)codePointBeforeWithJavaLangCharSequence:(id<JavaLangCharSequence>)seq
                                       withInt:(int)index {
  if (seq == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  int len = [((id<JavaLangCharSequence>) nil_chk(seq)) sequenceLength];
  if (index < 1 || index > len) {
    @throw [[JavaLangStringIndexOutOfBoundsException alloc] initWithInt:index];
  }
  unichar low = [seq charAtWithInt:--index];
  if (--index < 0) {
    return low;
  }
  unichar high = [seq charAtWithInt:index];
  if ([JavaLangCharacter isSurrogatePairWithChar:high withChar:low]) {
    return [JavaLangCharacter toCodePointWithChar:high withChar:low];
  }
  return low;
}

+ (int)codePointBeforeWithCharArray:(IOSCharArray *)seq
                            withInt:(int)index {
  if (seq == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  int len = (int) [((IOSCharArray *) nil_chk(seq)) count];
  if (index < 1 || index > len) {
    @throw [[JavaLangArrayIndexOutOfBoundsException alloc] initWithInt:index];
  }
  unichar low = IOSCharArray_Get(seq, --index);
  if (--index < 0) {
    return low;
  }
  unichar high = IOSCharArray_Get(seq, index);
  if ([JavaLangCharacter isSurrogatePairWithChar:high withChar:low]) {
    return [JavaLangCharacter toCodePointWithChar:high withChar:low];
  }
  return low;
}

+ (int)codePointBeforeWithCharArray:(IOSCharArray *)seq
                            withInt:(int)index
                            withInt:(int)start {
  if (seq == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  int len = (int) [((IOSCharArray *) nil_chk(seq)) count];
  if (index <= start || index > len || start < 0 || start >= len) {
    @throw [[JavaLangArrayIndexOutOfBoundsException alloc] init];
  }
  unichar low = IOSCharArray_Get(seq, --index);
  if (--index < start) {
    return low;
  }
  unichar high = IOSCharArray_Get(seq, index);
  if ([JavaLangCharacter isSurrogatePairWithChar:high withChar:low]) {
    return [JavaLangCharacter toCodePointWithChar:high withChar:low];
  }
  return low;
}

+ (int)toCharsWithInt:(int)codePoint
        withCharArray:(IOSCharArray *)dst
              withInt:(int)dstIndex {
  if (![JavaLangCharacter isValidCodePointWithInt:codePoint]) {
    @throw [[JavaLangIllegalArgumentException alloc] init];
  }
  if (dst == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  if (dstIndex < 0 || dstIndex >= (int) [((IOSCharArray *) nil_chk(dst)) count]) {
    @throw [[JavaLangIndexOutOfBoundsException alloc] init];
  }
  if ([JavaLangCharacter isSupplementaryCodePointWithInt:codePoint]) {
    if (dstIndex == (int) [((IOSCharArray *) nil_chk(dst)) count] - 1) {
      @throw [[JavaLangIndexOutOfBoundsException alloc] init];
    }
    int cpPrime = codePoint - (int) 0x10000;
    int high = (int) 0xD800 | ((cpPrime >> 10) & (int) 0x3FF);
    int low = (int) 0xDC00 | (cpPrime & (int) 0x3FF);
    (*IOSCharArray_GetRef(dst, dstIndex)) = (unichar) high;
    (*IOSCharArray_GetRef(dst, dstIndex + 1)) = (unichar) low;
    return 2;
  }
  (*IOSCharArray_GetRef(nil_chk(dst), dstIndex)) = (unichar) codePoint;
  return 1;
}

+ (IOSCharArray *)toCharsWithInt:(int)codePoint {
  if (![JavaLangCharacter isValidCodePointWithInt:codePoint]) {
    @throw [[JavaLangIllegalArgumentException alloc] init];
  }
  if ([JavaLangCharacter isSupplementaryCodePointWithInt:codePoint]) {
    int cpPrime = codePoint - (int) 0x10000;
    int high = (int) 0xD800 | ((cpPrime >> 10) & (int) 0x3FF);
    int low = (int) 0xDC00 | (cpPrime & (int) 0x3FF);
    return [IOSCharArray arrayWithChars:(unichar[]){ (unichar) high, (unichar) low } count:2];
  }
  return [IOSCharArray arrayWithChars:(unichar[]){ (unichar) codePoint } count:1];
}

+ (int)codePointCountWithJavaLangCharSequence:(id<JavaLangCharSequence>)seq
                                      withInt:(int)beginIndex
                                      withInt:(int)endIndex {
  if (seq == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  int len = [((id<JavaLangCharSequence>) nil_chk(seq)) sequenceLength];
  if (beginIndex < 0 || endIndex > len || beginIndex > endIndex) {
    @throw [[JavaLangIndexOutOfBoundsException alloc] init];
  }
  int result = 0;
  for (int i = beginIndex; i < endIndex; i++) {
    unichar c = [seq charAtWithInt:i];
    if ([JavaLangCharacter isHighSurrogateWithChar:c]) {
      if (++i < endIndex) {
        c = [seq charAtWithInt:i];
        if (![JavaLangCharacter isLowSurrogateWithChar:c]) {
          result++;
        }
      }
    }
    result++;
  }
  return result;
}

+ (int)codePointCountWithCharArray:(IOSCharArray *)seq
                           withInt:(int)offset
                           withInt:(int)count {
  if (seq == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  int len = (int) [((IOSCharArray *) nil_chk(seq)) count];
  int endIndex = offset + count;
  if (offset < 0 || count < 0 || endIndex > len) {
    @throw [[JavaLangIndexOutOfBoundsException alloc] init];
  }
  int result = 0;
  for (int i = offset; i < endIndex; i++) {
    unichar c = IOSCharArray_Get(seq, i);
    if ([JavaLangCharacter isHighSurrogateWithChar:c]) {
      if (++i < endIndex) {
        c = IOSCharArray_Get(seq, i);
        if (![JavaLangCharacter isLowSurrogateWithChar:c]) {
          result++;
        }
      }
    }
    result++;
  }
  return result;
}

+ (int)offsetByCodePointsWithJavaLangCharSequence:(id<JavaLangCharSequence>)seq
                                          withInt:(int)index
                                          withInt:(int)codePointOffset {
  if (seq == nil) {
    @throw [[JavaLangNullPointerException alloc] init];
  }
  int len = [((id<JavaLangCharSequence>) nil_chk(seq)) sequenceLength];
  if (index < 0 || index > len) {
    @throw [[JavaLangIndexOutOfBoundsException alloc] init];
  }
  if (codePointOffset == 0) {
    return index;
  }
  if (codePointOffset > 0) {
    int codePoints = codePointOffset;
    int i = index;
    while (codePoints > 0) {
      codePoints--;
      if (i >= len) {
        @throw [[JavaLangIndexOutOfBoundsException alloc] init];
      }
      if ([JavaLangCharacter isHighSurrogateWithChar:[seq charAtWithInt:i]]) {
        int next = i + 1;
        if (next < len && [JavaLangCharacter isLowSurrogateWithChar:[seq charAtWithInt:next]]) {
          i++;
        }
      }
      i++;
    }
    return i;
  }
  NSAssert(codePointOffset < 0, @"src/jre/java/lang/Character.java:884 condition failed: assert codePointOffset < 0;");
  int codePoints = -codePointOffset;
  int i = index;
  while (codePoints > 0) {
    codePoints--;
    i--;
    if (i < 0) {
      @throw [[JavaLangIndexOutOfBoundsException alloc] init];
    }
    if ([JavaLangCharacter isLowSurrogateWithChar:[seq charAtWithInt:i]]) {
      int prev = i - 1;
      if (prev >= 0 && [JavaLangCharacter isHighSurrogateWithChar:[seq charAtWithInt:prev]]) {
        i--;
      }
    }
  }
  return i;
}

+ (int)digitWithChar:(unichar)c
             withInt:(int)radix {
  if (radix >= JavaLangCharacter_MIN_RADIX && radix <= JavaLangCharacter_MAX_RADIX) {
    if (c < 128) {
      int result = -1;
      if ('0' <= c && c <= '9') {
        result = c - '0';
      }
      else if ('a' <= c && c <= 'z') {
        result = c - ('a' - 10);
      }
      else if ('A' <= c && c <= 'Z') {
        result = c - ('A' - 10);
      }
      return result < radix ? result : -1;
    }
    int result = [JavaLangCharacter indexOfCharWithIntArray:JavaLangCharacter_digitKeys_ withChar:c];
    if (result >= 0 && c <= IOSIntArray_Get(nil_chk(JavaLangCharacter_digitValues_), result * 2)) {
      int value = (unichar) (c - IOSIntArray_Get(JavaLangCharacter_digitValues_, result * 2 + 1));
      if (value >= radix) {
        return -1;
      }
      return value;
    }
  }
  return -1;
}

- (BOOL)isEqual:(id)object {
  return ([object isKindOfClass:[JavaLangCharacter class]]) && (value_ == ((JavaLangCharacter *) nil_chk(object))->value_);
}

+ (unichar)forDigitWithInt:(int)digit
                   withInt:(int)radix {
  if (JavaLangCharacter_MIN_RADIX <= radix && radix <= JavaLangCharacter_MAX_RADIX) {
    if (0 <= digit && digit < radix) {
      return (unichar) (digit < 10 ? digit + '0' : digit + 'a' - 10);
    }
  }
  return 0;
}

- (NSUInteger)hash {
  return value_;
}

+ (unichar)highSurrogateWithInt:(int)codePoint {
  return (unichar) ((codePoint >> 10) + (int) 0xd7c0);
}

+ (unichar)lowSurrogateWithInt:(int)codePoint {
  return (unichar) ((codePoint & (int) 0x3ff) | (int) 0xdc00);
}

+ (BOOL)isBmpCodePointWithInt:(int)codePoint {
  return codePoint >= JavaLangCharacter_MIN_VALUE && codePoint <= JavaLangCharacter_MAX_VALUE;
}

+ (unichar)reverseBytesWithChar:(unichar)c {
  return (unichar) ((c << 8) | (c >> 8));
}

- (NSString *)description {
  return [NSString valueOfChar:value_];
}

+ (NSString *)toStringWithChar:(unichar)value {
  return [NSString valueOfChar:value];
}

+ (int)indexOfCharWithIntArray:(IOSIntArray *)table
                      withChar:(unichar)c {
  for (int i = 0; i < (int) [((IOSIntArray *) nil_chk(table)) count]; i++) {
    if (IOSIntArray_Get(table, i) == (int) c) {
      return i;
    }
  }
  return -1;
}

+ (void)initialize {
  if (self == [JavaLangCharacter class]) {
    JavaLangCharacter_TYPE_ = (IOSClass *) check_class_cast([[[IOSCharArray arrayWithLength:0] getClass] getComponentType], [IOSClass class]);
    {
      JavaLangCharacter_MIN_HIGH_SURROGATE_ = 0xd800;
      JavaLangCharacter_MAX_HIGH_SURROGATE_ = 0xdbff;
      JavaLangCharacter_MIN_LOW_SURROGATE_ = 0xdc00;
      JavaLangCharacter_MAX_LOW_SURROGATE_ = 0xdfff;
      JavaLangCharacter_MIN_SURROGATE_ = 0xd800;
      JavaLangCharacter_MAX_SURROGATE_ = 0xdfff;
    }
    JavaLangCharacter_digitKeys_ = [IOSIntArray arrayWithInts:(int[]){ (int) 0x0030, (int) 0x0041, (int) 0x0061, (int) 0x0660, (int) 0x06f0, (int) 0x0966, (int) 0x09e6, (int) 0x0a66, (int) 0x0ae6, (int) 0x0b66, (int) 0x0be7, (int) 0x0c66, (int) 0x0ce6, (int) 0x0d66, (int) 0x0e50, (int) 0x0ed0, (int) 0x0f20, (int) 0x1040, (int) 0x1369, (int) 0x17e0, (int) 0x1810, (int) 0xff10, (int) 0xff21, (int) 0xff41 } count:24];
    JavaLangCharacter_digitValues_ = [IOSIntArray arrayWithInts:(int[]){ (int) 0x0039, (int) 0x0030, (int) 0x005a, (int) 0x0037, (int) 0x007a, (int) 0x0057, (int) 0x0669, (int) 0x0660, (int) 0x06f9, (int) 0x06f0, (int) 0x096f, (int) 0x0966, (int) 0x09ef, (int) 0x09e6, (int) 0x0a6f, (int) 0x0a66, (int) 0x0aef, (int) 0x0ae6, (int) 0x0b6f, (int) 0x0b66, (int) 0x0bef, (int) 0x0be6, (int) 0x0c6f, (int) 0x0c66, (int) 0x0cef, (int) 0x0ce6, (int) 0x0d6f, (int) 0x0d66, (int) 0x0e59, (int) 0x0e50, (int) 0x0ed9, (int) 0x0ed0, (int) 0x0f29, (int) 0x0f20, (int) 0x1049, (int) 0x1040, (int) 0x1371, (int) 0x1368, (int) 0x17e9, (int) 0x17e0, (int) 0x1819, (int) 0x1810, (int) 0xff19, (int) 0xff10, (int) 0xff3a, (int) 0xff17, (int) 0xff5a, (int) 0xff37 } count:48];
  }
}

- (void)copyAllFieldsTo:(JavaLangCharacter *)other {
  [super copyAllFieldsTo:other];
  other->value_ = value_;
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "initWithChar:", "Character", NULL, 0x1, NULL },
    { "charValue", NULL, "C", 0x1, NULL },
    { "checkValidCodePointWithInt:", "checkValidCodePoint", "V", 0xa, NULL },
    { "compareToWithJavaLangCharacter:", "compareTo", "I", 0x1, NULL },
    { "compareWithChar:withChar:", "compare", "I", 0x9, NULL },
    { "valueOfWithChar:", "valueOf", "Ljava.lang.Character;", 0x9, NULL },
    { "isValidCodePointWithInt:", "isValidCodePoint", "Z", 0x9, NULL },
    { "isSupplementaryCodePointWithInt:", "isSupplementaryCodePoint", "Z", 0x9, NULL },
    { "isHighSurrogateWithChar:", "isHighSurrogate", "Z", 0x9, NULL },
    { "isLowSurrogateWithChar:", "isLowSurrogate", "Z", 0x9, NULL },
    { "isSurrogateWithChar:", "isSurrogate", "Z", 0x9, NULL },
    { "isSurrogatePairWithChar:withChar:", "isSurrogatePair", "Z", 0x9, NULL },
    { "charCountWithInt:", "charCount", "I", 0x9, NULL },
    { "toCodePointWithChar:withChar:", "toCodePoint", "I", 0x9, NULL },
    { "codePointAtWithJavaLangCharSequence:withInt:", "codePointAt", "I", 0x9, NULL },
    { "codePointAtWithCharArray:withInt:", "codePointAt", "I", 0x9, NULL },
    { "codePointAtWithCharArray:withInt:withInt:", "codePointAt", "I", 0x9, NULL },
    { "codePointBeforeWithJavaLangCharSequence:withInt:", "codePointBefore", "I", 0x9, NULL },
    { "codePointBeforeWithCharArray:withInt:", "codePointBefore", "I", 0x9, NULL },
    { "codePointBeforeWithCharArray:withInt:withInt:", "codePointBefore", "I", 0x9, NULL },
    { "toCharsWithInt:withCharArray:withInt:", "toChars", "I", 0x9, NULL },
    { "toCharsWithInt:", "toChars", "[C", 0x9, NULL },
    { "codePointCountWithJavaLangCharSequence:withInt:withInt:", "codePointCount", "I", 0x9, NULL },
    { "codePointCountWithCharArray:withInt:withInt:", "codePointCount", "I", 0x9, NULL },
    { "offsetByCodePointsWithJavaLangCharSequence:withInt:withInt:", "offsetByCodePoints", "I", 0x9, NULL },
    { "digitWithChar:withInt:", "digit", "I", 0x9, NULL },
    { "isEqual:", "equals", "Z", 0x1, NULL },
    { "forDigitWithInt:withInt:", "forDigit", "C", 0x9, NULL },
    { "hash", "hashCode", "I", 0x1, NULL },
    { "highSurrogateWithInt:", "highSurrogate", "C", 0x9, NULL },
    { "lowSurrogateWithInt:", "lowSurrogate", "C", 0x9, NULL },
    { "isBmpCodePointWithInt:", "isBmpCodePoint", "Z", 0x9, NULL },
    { "reverseBytesWithChar:", "reverseBytes", "C", 0x9, NULL },
    { "description", "toString", "Ljava.lang.String;", 0x1, NULL },
    { "toStringWithChar:", "toString", "Ljava.lang.String;", 0x9, NULL },
    { "indexOfCharWithIntArray:withChar:", "indexOfChar", "I", 0xa, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "serialVersionUID_", NULL, 0x1a, "J" },
    { "value_", NULL, 0x12, "C" },
    { "MIN_VALUE_", NULL, 0x19, "C" },
    { "MAX_VALUE_", NULL, 0x19, "C" },
    { "MIN_RADIX_", NULL, 0x19, "I" },
    { "MAX_RADIX_", NULL, 0x19, "I" },
    { "TYPE_", NULL, 0x19, "Ljava.lang.Class;" },
    { "MIN_HIGH_SURROGATE_", NULL, 0x19, "C" },
    { "MAX_HIGH_SURROGATE_", NULL, 0x19, "C" },
    { "MIN_LOW_SURROGATE_", NULL, 0x19, "C" },
    { "MAX_LOW_SURROGATE_", NULL, 0x19, "C" },
    { "MIN_SURROGATE_", NULL, 0x19, "C" },
    { "MAX_SURROGATE_", NULL, 0x19, "C" },
    { "MIN_SUPPLEMENTARY_CODE_POINT_", NULL, 0x19, "I" },
    { "MIN_CODE_POINT_", NULL, 0x19, "I" },
    { "MAX_CODE_POINT_", NULL, 0x19, "I" },
    { "SIZE_", NULL, 0x19, "I" },
    { "digitKeys_", NULL, 0x1a, "[I" },
    { "digitValues_", NULL, 0x1a, "[I" },
    { "CACHE_LEN_", NULL, 0x1a, "I" },
  };
  static J2ObjcClassInfo _JavaLangCharacter = { "Character", "java.lang", NULL, 0x11, 36, methods, 20, fields, 0, NULL};
  return &_JavaLangCharacter;
}

@end
@implementation JavaLangCharacter_valueOfCache

static IOSObjectArray * JavaLangCharacter_valueOfCache_CACHE_;

+ (IOSObjectArray *)CACHE {
  return JavaLangCharacter_valueOfCache_CACHE_;
}

- (id)init {
  return [super init];
}

+ (void)initialize {
  if (self == [JavaLangCharacter_valueOfCache class]) {
    JavaLangCharacter_valueOfCache_CACHE_ = [IOSObjectArray arrayWithLength:JavaLangCharacter_CACHE_LEN type:[IOSClass classWithClass:[JavaLangCharacter class]]];
    {
      for (int i = 0; i < (int) [JavaLangCharacter_valueOfCache_CACHE_ count]; i++) {
        (void) IOSObjectArray_Set(JavaLangCharacter_valueOfCache_CACHE_, i, [[JavaLangCharacter alloc] initWithChar:(unichar) i]);
      }
    }
  }
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "init", NULL, NULL, 0x0, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "CACHE_", NULL, 0x1a, "[Ljava.lang.Character;" },
  };
  static J2ObjcClassInfo _JavaLangCharacter_valueOfCache = { "valueOfCache", "java.lang", "Character", 0x8, 1, methods, 1, fields, 0, NULL};
  return &_JavaLangCharacter_valueOfCache;
}

@end
