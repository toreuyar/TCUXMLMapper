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
//  TCUXMLMapper.h
//  TCUXMLMapper
//
//  Created by Töre Çağrı Uyar on 01/12/14.
//  E-mail: mail@toreuyar.net
//  Copyright (c) 2014 Töre Çağrı Uyar. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCUXMLMapper;

@protocol TCUXMLMappedObject <NSObject>

@optional

- (NSString *)propertyForXMLTag:(NSString *)xmlTag;
- (Class)classForProperty:(NSString *)propertyName;
- (NSDateFormatter *)dateFormatterForProperty:(NSString *)propertyName;
- (NSDate *)dateForProperty:(NSString *)propertyName fromValue:(NSString *)textValue;
- (void)willBeMappedBy:(TCUXMLMapper *)mapper;
- (void)didMappedBy:(TCUXMLMapper *)mapper;
- (BOOL)mapper:(TCUXMLMapper *)mapper shouldMapElement:(NSString *)element toProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;
- (void)mapper:(TCUXMLMapper *)mapper willMapElement:(NSString *)element toProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;
- (BOOL)mapper:(TCUXMLMapper *)mapper mapElement:(NSString *)element toProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;
- (void)mapper:(TCUXMLMapper *)mapper didMapElement:(NSString *)element toProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;
- (BOOL)mapper:(TCUXMLMapper *)mapper shouldAddElement:(NSString *)element toArray:(NSMutableArray *)array ofProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;
- (void)mapper:(TCUXMLMapper *)mapper willAddElement:(NSString *)element toArray:(NSMutableArray *)array ofProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;
- (BOOL)mapper:(TCUXMLMapper *)mapper addElement:(NSString *)element toArray:(NSMutableArray *)array ofProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;
- (void)mapper:(TCUXMLMapper *)mapper didAddElement:(NSString *)element toArray:(NSMutableArray *)array ofProperty:(NSString *)propertyName fromValue:(NSString *)textValue toObject:(id)mappedObject;

@end

@interface TCUXMLMapper : NSObject <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableArray *mappedObjects;

- (instancetype)initWithXMLParser:(NSXMLParser *)xmlParser
                    classMappings:(NSDictionary *)classMappings;
- (BOOL)parse;

@end
