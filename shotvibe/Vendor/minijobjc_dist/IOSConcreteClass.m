// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  IOSConcreteClass.m
//  JreEmulation
//
//  Created by Keith Stanger on 8/16/13.
//

#import "IOSConcreteClass.h"
#import "IOSReflection.h"
#import "JavaMetadata.h"
//#import "java/lang/ClassCastException.h"
#import "java/lang/Enum.h"
//#import "java/lang/InstantiationException.h"
//#import "java/lang/NoSuchMethodException.h"
//#import "java/lang/Void.h"
//#import "java/lang/reflect/Constructor.h"
//#import "java/lang/reflect/Method.h"
//#import "java/lang/reflect/Modifier.h"
//#import "java/lang/reflect/ParameterizedTypeImpl.h"
#import "objc/runtime.h"

@implementation IOSConcreteClass

@synthesize objcClass = class_;

- (id)initWithClass:(Class)cls {
  if ((self = [super init])) {
    class_ = RETAIN_(cls);
  }
  return self;
}

- (IOSClass *)getSuperclass {
  Class superclass = [class_ superclass];
  if (superclass != nil) {
    return [IOSClass classWithClass:superclass];
  }
  return nil;
}

- (BOOL)isInstance:(id)object {
  return [object isKindOfClass:class_];
}

- (NSString *)getName {
  JavaClassMetadata *metadata = [self getMetadata];
  return metadata ? [metadata qualifiedName] : NSStringFromClass(class_);
}

- (NSString *)getSimpleName {
  JavaClassMetadata *metadata = [self getMetadata];
  return metadata ? metadata.typeName : NSStringFromClass(class_);
}

- (NSString *)objcName {
  return NSStringFromClass(class_);
}

- (BOOL)isAssignableFrom:(IOSClass *)cls {
  return [cls.objcClass isSubclassOfClass:class_];
}

- (BOOL)isAnonymousClass {
  JavaClassMetadata *metadata = [self getMetadata];
  if (metadata) {
    return (metadata.modifiers & 0x8000) > 0;
  }
  return NO;
}

static BOOL IsConstructor(NSString *name) {
  return [name isEqualToString:@"init"] || [name hasPrefix:@"initWith"];
}

// Methods that have invalid parameter or return Objective-C types.
static NSArray *_invalidMethodNames;

+ (void)initialize {
  if (self == [IOSConcreteClass class]) {
    _invalidMethodNames =
        [NSArray arrayWithObjects:@"__metadata", @"__boxValue:", @"__unboxValue:toRawValue:", nil];
  }
}

#if ! __has_feature(objc_arc)
- (void)dealloc {
  [class_ release];
  [super dealloc];
}
#endif

@end
