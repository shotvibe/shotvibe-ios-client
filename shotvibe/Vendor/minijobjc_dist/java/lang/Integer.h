//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/lang/Integer.java
//
//  Created by raptor on 1/9/14.
//

#ifndef _JavaLangInteger_H_
#define _JavaLangInteger_H_

@class IOSClass;
@class IOSObjectArray;

#import "JreEmulation.h"
#include "java/lang/Comparable.h"

#define JavaLangInteger_MAX_VALUE 2147483647
#define JavaLangInteger_MIN_VALUE ((int) 0x80000000)
#define JavaLangInteger_SIZE 32

@interface JavaLangInteger : NSNumber < JavaLangComparable > {
 @public
  int value_;
}

+ (int)MAX_VALUE;
+ (int)MIN_VALUE;
+ (int)SIZE;
+ (IOSClass *)TYPE;
- (id)initWithInt:(int)value;
- (char)charValue;
- (int)compareToWithId:(JavaLangInteger *)object;
+ (int)compareWithInt:(int)lhs
              withInt:(int)rhs;
- (double)doubleValue;
- (BOOL)isEqual:(id)o;
- (float)floatValue;
- (NSUInteger)hash;
- (int)intValue;
- (long long int)longLongValue;
- (short int)shortValue;
- (NSString *)description;
+ (NSString *)toStringWithInt:(int)value;
+ (int)highestOneBitWithInt:(int)i;
+ (int)lowestOneBitWithInt:(int)i;
+ (int)numberOfLeadingZerosWithInt:(int)i;
+ (int)numberOfTrailingZerosWithInt:(int)i;
+ (int)bitCountWithInt:(int)i;
+ (int)rotateLeftWithInt:(int)i
                 withInt:(int)distance;
+ (int)rotateRightWithInt:(int)i
                  withInt:(int)distance;
+ (int)reverseBytesWithInt:(int)i;
+ (int)reverseWithInt:(int)i;
+ (int)signumWithInt:(int)i;
+ (JavaLangInteger *)valueOfWithInt:(int)i;
- (void)copyAllFieldsTo:(JavaLangInteger *)other;
@end

BOXED_INC_AND_DEC(Int, intValue, JavaLangInteger)

@interface JavaLangInteger_valueOfCache : NSObject {
}

+ (IOSObjectArray *)CACHE;
- (id)init;
@end

#endif // _JavaLangInteger_H_
