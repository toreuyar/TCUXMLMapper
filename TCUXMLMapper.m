//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Töre Çağrı Uyar
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  TCUXMLMapper.m
//  TCUXMLMapper
//
//  Created by Töre Çağrı Uyar on 01/12/14.
//  E-mail: mail@toreuyar.net
//  Copyright (c) 2014 Töre Çağrı Uyar. All rights reserved.
//

#import "TCUXMLMapper.h"
#import "TCUPropertyAttributes.h"

@interface TCUXMLMapper()

@property (nonatomic, strong) id currentObject;
@property (nonatomic, strong) NSDictionary *propertyAttributes;
@property (nonatomic, weak) TCUXMLMapper *rootMapper;
@property (nonatomic, strong) TCUXMLMapper *childMapper;
@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSString *currentElementName;
@property (nonatomic, strong) NSMutableString *currentElementValue;
@property (nonatomic) NSInteger rootDepthLimit;
@property (nonatomic) NSInteger depth;
@property (nonatomic) NSInteger currentElementDepth;
@property (nonatomic, strong) TCUPropertyAttributes *currentPropertyAttributes;
@property (nonatomic, strong) NSString *currentPropertyName;
@property (nonatomic, strong) NSMutableDictionary *currentObjectAssociatedObjects;
@property (nonatomic, strong) NSDictionary *classMappings;

+ (NSArray *)specialClasses;

- (void)setValue:(id)value forKey:(NSString *)key onOject:(id)subjectObject forElement:(NSString *)element toProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;
- (void)addObject:(id)value toArray:(NSMutableArray *)array onOject:(id)subjectObject forElement:(NSString *)element toProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;

@end

@implementation TCUXMLMapper

+ (NSArray *)specialClasses {
    __strong static NSArray *_specialClasses = nil;
    static dispatch_once_t specialClassesDispatchOnceToken;
    dispatch_once(&specialClassesDispatchOnceToken, ^{
        _specialClasses = @[@"NSString", @"NSNumber", @"NSArray", @"NSMutableArray", @"NSDate", @"NS"];
    });
    return _specialClasses;
}

- (NSMutableDictionary *)currentObjectAssociatedObjects {
    if (!_currentObjectAssociatedObjects) {
        [self willChangeValueForKey:@"currentObjectAssociatedObjects"];
        _currentObjectAssociatedObjects = [NSMutableDictionary dictionary];
        [self didChangeValueForKey:@"currentObjectAssociatedObjects"];
    }
    return _currentObjectAssociatedObjects;
}

- (NSMutableString *)currentElementValue {
    if (!_currentElementValue) {
        [self willChangeValueForKey:@"currentElementValue"];
        _currentElementValue = [NSMutableString string];
        [self didChangeValueForKey:@"currentElementValue"];
    }
    return _currentElementValue;
}

- (instancetype)initWithXMLParser:(NSXMLParser *)xmlParser
                    classMappings:(NSDictionary *)classMappings {
    self = [super init];
    if (self) {
        self.xmlParser = xmlParser;
        xmlParser.delegate = self;
        xmlParser.shouldProcessNamespaces = NO;
        xmlParser.shouldReportNamespacePrefixes = NO;
        xmlParser.shouldResolveExternalEntities = NO;
        if (classMappings) {
            self.classMappings = classMappings;
        }
    }
    return self;
}

- (BOOL)parse {
    return [self.xmlParser parse];
}

- (instancetype)initWithXMLParser:(NSXMLParser *)xmlParser
                       rootMapper:(TCUXMLMapper *)rootMapper
                    currentObject:(id)currentObject
                   rootDepthLimit:(NSInteger)rootDepthLimit {
    self = [super init];
    if (self) {
        self.xmlParser = xmlParser;
        self.rootMapper = rootMapper;
        self.currentObject = currentObject;
        self.rootDepthLimit = rootDepthLimit;
        self.depth = rootDepthLimit;
    }
    return self;
}

- (NSMutableArray *)mappedObjects {
    if (!_mappedObjects) {
        [self willChangeValueForKey:@"mappedObjects"];
        _mappedObjects = [NSMutableArray array];
        [self didChangeValueForKey:@"mappedObjects"];
    }
    return _mappedObjects;
}

- (NSDictionary *)propertyAttributes {
    if (!_propertyAttributes) {
        [self willChangeValueForKey:@"properyAttributes"];
        _propertyAttributes = @{};
        [self didChangeValueForKey:@"properyAttributes"];
    }
    return _propertyAttributes;
}

- (void)setCurrentObject:(id)currentObject {
    _currentObject = currentObject;
    NSDictionary *nextPropertyAttributes = @{};
    if (currentObject) {
        nextPropertyAttributes = [[currentObject class] propertyDictionary];
    }
    self.propertyAttributes = nextPropertyAttributes;
}

- (void)setValue:(id)value
          forKey:(NSString *)key
         onOject:(id)object
      forElement:(NSString *)element
      toProperty:(NSString *)propertyName
       fromValue:(NSString *)textValue
        toObject:(id)mappedObject {
    if ([object conformsToProtocol:@protocol(TCUXMLMappedObject)]) {
        if ([object respondsToSelector:@selector(mapper:shouldMapElement:toProperty:fromValue:toObject:)]) {
            if (![object mapper:self shouldMapElement:element toProperty:propertyName fromValue:value toObject:mappedObject]) {
                return;
            }
        }
        if ([object respondsToSelector:@selector(mapper:willMapElement:toProperty:fromValue:toObject:)]) {
            [object mapper:self willMapElement:element toProperty:propertyName fromValue:textValue toObject:mappedObject];
        }
        if ([object respondsToSelector:@selector(mapper:mapElement:toProperty:fromValue:toObject:)]) {
            if (![object mapper:self mapElement:element toProperty:propertyName fromValue:textValue toObject:mappedObject]) {
                [object setValue:value forKey:key];
            }
        } else {
            [object setValue:value forKey:key];
        }
        if ([object respondsToSelector:@selector(mapper:didMapElement:toProperty:fromValue:toObject:)]) {
            [object mapper:self didMapElement:element toProperty:propertyName fromValue:textValue toObject:mappedObject];
        }
    } else {
        [object setValue:value forKey:key];
    }
}

- (void)addObject:(id)value
          toArray:(NSMutableArray *)array
          onOject:(id)subjectObject
       forElement:(NSString *)element
       toProperty:(NSString *)propertyName
        fromValue:(NSString *)textValue
         toObject:(id)mappedObject {
    if ([subjectObject conformsToProtocol:@protocol(TCUXMLMappedObject)]) {
        if ([subjectObject respondsToSelector:@selector(mapper:shouldAddElement:toArray:ofProperty:fromValue:toObject:)]) {
            if (![subjectObject mapper:self shouldAddElement:element toArray:array ofProperty:propertyName fromValue:textValue toObject:mappedObject]) {
                return;
            }
        }
        if ([subjectObject respondsToSelector:@selector(mapper:willAddElement:toArray:ofProperty:fromValue:toObject:)]) {
            [subjectObject mapper:self willAddElement:element toArray:array ofProperty:propertyName fromValue:textValue toObject:mappedObject];
        }
        if ([subjectObject respondsToSelector:@selector(mapper:addElement:toArray:ofProperty:fromValue:toObject:)]) {
            if (![subjectObject mapper:self addElement:element toArray:array ofProperty:propertyName fromValue:textValue toObject:mappedObject]) {
                [array addObject:value];
            }
        } else {
            [array addObject:value];
        }
        if ([subjectObject respondsToSelector:@selector(mapper:didAddElement:toArray:ofProperty:fromValue:toObject:)]) {
            [subjectObject mapper:self didAddElement:element toArray:array ofProperty:propertyName fromValue:textValue toObject:mappedObject];
        }
    } else {
        [array addObject:value];
    }
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    NSLog(@"finished document");
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError {

}

- (void)parser:(NSXMLParser *)parser foundElementDeclarationWithName:(NSString *)elementName model:(NSString *)model {

}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    self.depth++;
    if (!self.currentElementName) {
        if (!self.currentObject) {
            Class subjectClass = nil;
            NSString *className = nil;
            if (self.classMappings) {
                className = [self.classMappings objectForKey:@"elementName"];
            }
            if (!className) {
                className = elementName;
            }
            subjectClass = NSClassFromString(className);
            if (subjectClass) {
                id subjectObject = [subjectClass new];
                self.childMapper = [[TCUXMLMapper alloc] initWithXMLParser:parser
                                                                rootMapper:self
                                                             currentObject:subjectObject
                                                            rootDepthLimit:self.depth];
                if ([subjectObject conformsToProtocol:@protocol(TCUXMLMappedObject)]) {
                    if ([subjectObject respondsToSelector:@selector(willBeMappedBy:)]) {
                        [subjectObject willBeMappedBy:self.childMapper];
                    }
                }
                parser.delegate = self.childMapper;
            }
        } else {
            NSString *mappedPropertyName = nil;
            if ([self.currentObject conformsToProtocol:@protocol(TCUXMLMappedObject)]) {
                if ([self.currentObject respondsToSelector:@selector(propertyForXMLTag:)]) {
                    mappedPropertyName = [((id<TCUXMLMappedObject>)self.currentObject) propertyForXMLTag:elementName];
                }
            }
            if (!mappedPropertyName) {
                mappedPropertyName = elementName;
            }
            TCUPropertyAttributes *propertyAttributes = [self.propertyAttributes objectForKey:mappedPropertyName];
            if (propertyAttributes) {
                self.currentPropertyAttributes = propertyAttributes;
                self.currentPropertyName = mappedPropertyName;
                self.currentElementName = elementName;
                self.currentElementDepth = self.depth;
                if (propertyAttributes.typeAttribute & TCUTypeAttributeObject) {
                    Class subjectClass = nil;
                    if (propertyAttributes.type == TCUTypeClass) {
                        subjectClass = NSClassFromString(propertyAttributes.name);
                    }
                    NSString *classPrefix = nil;
                    if (propertyAttributes.name.length > 2) {
                        classPrefix = [propertyAttributes.name substringWithRange:NSMakeRange(0, 2)];
                    } else {
                        classPrefix = @"";
                    }
                    
                    id subjectObject = (subjectClass ? [subjectClass new] : nil);
                    if (!([[TCUXMLMapper specialClasses] containsObject:propertyAttributes.name] ||
                          [[TCUXMLMapper specialClasses] containsObject:classPrefix])) {
                        self.childMapper = [[TCUXMLMapper alloc] initWithXMLParser:parser
                                                                        rootMapper:self
                                                                     currentObject:subjectObject
                                                                    rootDepthLimit:self.depth];
                        if ([subjectObject conformsToProtocol:@protocol(TCUXMLMappedObject)]) {
                            if ([subjectObject respondsToSelector:@selector(willBeMappedBy:)]) {
                                [subjectObject willBeMappedBy:self.childMapper];
                            }
                        }
                        parser.delegate = self.childMapper;
                    } else if ([propertyAttributes.name isEqualToString:@"NSArray"] ||
                               [propertyAttributes.name isEqualToString:@"NSMutableArray"]) {
                        if ([self.currentObject conformsToProtocol:@protocol(TCUXMLMappedObject)]) {
                            if ([self.currentObject respondsToSelector:@selector(classForProperty:)]) {
                                Class arrayObjectClass = [((id<TCUXMLMappedObject>)self.currentObject) classForProperty:self.currentPropertyName];
                                if (arrayObjectClass) {
                                    self.childMapper = [[TCUXMLMapper alloc] initWithXMLParser:parser
                                                                                    rootMapper:self
                                                                                 currentObject:[arrayObjectClass new]
                                                                                rootDepthLimit:self.depth];
                                    parser.delegate = self.childMapper;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (self.currentElementName) {
        [self.currentElementValue appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if (self.rootMapper) {
        if (self.depth <= self.rootDepthLimit) {
            if (self.currentObject) {
                if (_currentObjectAssociatedObjects) {
                    [self.currentObjectAssociatedObjects enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id key, id obj, BOOL *stop) {
                        [self setValue:obj forKey:key onOject:self.currentObject forElement:nil toProperty:key fromValue:nil toObject:obj];
                    }];
                }
            }
            if ([self.currentObject conformsToProtocol:@protocol(TCUXMLMappedObject)]) {
                if ([self.currentObject respondsToSelector:@selector(didMappedBy:)]) {
                    [self.currentObject didMappedBy:self];
                }
            }
            parser.delegate = self.rootMapper;
            [self.rootMapper parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
            return;
        }
    }
    if (self.currentElementName) {
        if (self.depth < self.currentElementDepth) {
            self.currentElementName = nil;
            self.currentElementValue = nil;
            self.currentPropertyName = nil;
            self.currentPropertyAttributes = nil;
            self.currentElementDepth = 0;
            self.childMapper = nil;
        } else if (self.depth == self.currentElementDepth) {
            if ([self.currentElementName isEqualToString:elementName]) {
                if (self.currentPropertyAttributes.typeAttribute & TCUTypeAttributeObject) {
                    if (self.currentPropertyAttributes.type == TCUTypeClass) {
                        if ([[TCUXMLMapper specialClasses] containsObject:self.currentPropertyAttributes.name]) {
                            if ([self.currentPropertyAttributes.name isEqualToString:@"NSString"]) {
                                [self setValue:self.currentElementValue
                                        forKey:self.currentPropertyName
                                       onOject:self.currentObject
                                    forElement:self.currentElementName
                                    toProperty:self.currentPropertyName
                                     fromValue:self.currentElementValue
                                      toObject:self.currentElementValue];
                            } else if ([self.currentPropertyAttributes.name isEqualToString:@"NSNumber"]) {
                                NSNumber *mappedNumber = [NSNumber numberWithDouble:self.currentElementValue.doubleValue];
                                [self setValue:mappedNumber
                                        forKey:self.currentPropertyName
                                       onOject:self.currentObject
                                    forElement:self.currentElementName
                                    toProperty:self.currentPropertyName
                                     fromValue:self.currentElementValue
                                      toObject:mappedNumber];
                            } else if ([self.currentPropertyAttributes.name isEqualToString:@"NSDate"]) {
                                if ([self.currentObject conformsToProtocol:@protocol(TCUXMLMappedObject)]) {
                                    if ([self.currentObject respondsToSelector:@selector(dateForProperty:fromValue:)]) {
                                        NSDate *date = [self.currentObject dateForProperty:self.currentPropertyName fromValue:self.currentElementValue];
                                        [self setValue:date
                                                forKey:self.currentPropertyName
                                               onOject:self.currentObject
                                            forElement:self.currentElementName
                                            toProperty:self.currentPropertyName
                                             fromValue:self.currentElementValue
                                              toObject:date];
                                    } else if ([self.currentObject respondsToSelector:@selector(dateFormatterForProperty:)]) {
                                        NSDateFormatter *dateFormatter = [self.currentObject dateFormatterForProperty:self.currentPropertyName];
                                        if ([dateFormatter isKindOfClass:[NSDateFormatter class]]) {
                                            NSDate *date = [dateFormatter dateFromString:self.currentElementValue];
                                            [self setValue:date
                                                    forKey:self.currentPropertyName
                                                   onOject:self.currentObject
                                                forElement:self.currentElementName
                                                toProperty:self.currentPropertyName
                                                 fromValue:self.currentElementValue
                                                  toObject:date];
                                        }
                                    }
                                }
                            } else if ([self.currentPropertyAttributes.name isEqualToString:@"NSArray"]) {
                                if (self.childMapper) {
                                    NSMutableArray *subjectArray = [self.currentObjectAssociatedObjects valueForKey:self.currentPropertyName];
                                    if (!subjectArray) {
                                        subjectArray = [NSMutableArray array];
                                        [self.currentObjectAssociatedObjects setObject:subjectArray forKey:self.currentPropertyName];
                                    }
                                    if (self.childMapper.currentObject) {
                                        [subjectArray addObject:self.childMapper.currentObject];
                                    }
                                }
                            } else if ([self.currentPropertyAttributes.name isEqualToString:@"NSMutableArray"]) {
                                if (self.childMapper) {
                                    NSMutableArray *subjectArray = [self.currentObject valueForKey:self.currentPropertyName];
                                    if (subjectArray) {
                                        if (self.childMapper.currentObject) {
                                            [self addObject:self.childMapper.currentObject
                                                    toArray:subjectArray
                                                    onOject:self.currentObject
                                                 forElement:self.currentElementName
                                                 toProperty:self.currentPropertyName
                                                  fromValue:nil
                                                   toObject:self.childMapper.currentObject];
                                        }
                                    } else {
                                        subjectArray = [NSMutableArray array];
                                        if (self.childMapper.currentObject) {
                                            [self addObject:self.childMapper.currentObject
                                                    toArray:subjectArray
                                                    onOject:self.currentObject
                                                 forElement:self.currentElementName
                                                 toProperty:self.currentPropertyName
                                                  fromValue:nil
                                                   toObject:self.childMapper.currentObject];
                                            [self setValue:subjectArray
                                                    forKey:self.currentPropertyName
                                                   onOject:self.currentObject
                                                forElement:nil
                                                toProperty:self.currentPropertyName
                                                 fromValue:nil
                                                  toObject:subjectArray];
                                        }
                                    }
                                }
                            }
                        } else if (self.childMapper) {
                            [self setValue:self.childMapper.currentObject
                                    forKey:self.currentPropertyName
                                   onOject:self.currentObject
                                forElement:self.currentElementName
                                toProperty:self.currentPropertyName
                                 fromValue:nil
                                  toObject:self.childMapper.currentObject];
                        }
                    }
                } else if (self.currentPropertyAttributes.typeAttribute & TCUTypeAttributePrimitive) {
                    [self setValue:self.currentElementValue
                            forKey:self.currentPropertyName
                           onOject:self.currentObject
                        forElement:self.currentElementName
                        toProperty:self.currentPropertyName
                         fromValue:self.currentElementValue
                          toObject:nil];
                }
            }
            self.currentElementName = nil;
            self.currentElementValue = nil;
            self.currentPropertyName = nil;
            self.currentPropertyAttributes = nil;
            self.currentElementDepth = 0;
            self.childMapper = nil;
        }
    } else {
        if ((self.rootDepthLimit == 0) && (self.childMapper.currentObject)) {
            [self.mappedObjects addObject:self.childMapper.currentObject];
            self.currentElementName = nil;
            self.currentElementValue = nil;
            self.currentPropertyName = nil;
            self.currentPropertyAttributes = nil;
            self.currentElementDepth = 0;
            self.childMapper = nil;
        }
    }
    self.depth--;
}

@end
