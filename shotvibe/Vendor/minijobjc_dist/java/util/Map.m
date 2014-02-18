//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: src/jre/java/util/Map.java
//
//  Created by raptor on 1/17/14.
//

#include "java/util/Collection.h"
#include "java/util/Map.h"
#include "java/util/Set.h"


@interface JavaUtilMap : NSObject
@end

@implementation JavaUtilMap

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "clear", NULL, "V", 0x401, NULL },
    { "containsKeyWithId:", "containsKey", "Z", 0x401, NULL },
    { "containsValueWithId:", "containsValue", "Z", 0x401, NULL },
    { "entrySet", NULL, "Ljava.util.Set;", 0x401, NULL },
    { "isEqual:", "equals", "Z", 0x401, NULL },
    { "getWithId:", "get", "TV;", 0x401, NULL },
    { "hash", "hashCode", "I", 0x401, NULL },
    { "isEmpty", NULL, "Z", 0x401, NULL },
    { "keySet", NULL, "Ljava.util.Set;", 0x401, NULL },
    { "putWithId:withId:", "put", "TV;", 0x401, NULL },
    { "putAllWithJavaUtilMap:", "putAll", "V", 0x401, NULL },
    { "removeWithId:", "remove", "TV;", 0x401, NULL },
    { "size", NULL, "I", 0x401, NULL },
    { "values", NULL, "Ljava.util.Collection;", 0x401, NULL },
  };
  static J2ObjcClassInfo _JavaUtilMap = { "Map", "java.util", NULL, 0x201, 14, methods, 0, NULL, 0, NULL};
  return &_JavaUtilMap;
}

@end

@interface JavaUtilMap_Entry : NSObject
@end

@implementation JavaUtilMap_Entry

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "getKey", NULL, "TK;", 0x401, NULL },
    { "getValue", NULL, "TV;", 0x401, NULL },
    { "setValueWithId:", "setValue", "TV;", 0x401, NULL },
  };
  static J2ObjcClassInfo _JavaUtilMap_Entry = { "Entry", "java.util", "Map", 0x209, 3, methods, 0, NULL, 0, NULL};
  return &_JavaUtilMap_Entry;
}

@end
