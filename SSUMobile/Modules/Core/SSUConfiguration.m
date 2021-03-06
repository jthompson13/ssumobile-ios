//
//  SSUConfiguration.m
//  SSUMobile
//
//  Created by Eric Amorde on 9/16/15.
//  Copyright (c) 2015 Sonoma State University Department of Computer Science. All rights reserved.
//

#import "SSUConfiguration.h"
#import "SSUCommunicator.h"
#import "SSULogging.h"

static NSString * const kSSUConfigKeyPrefix = @"edu.sonoma";
NSString * const kSSUConfigLastLoadDateKey = @"edu.sonoma.configuration.last_load";

@interface SSUConfiguration()

@property (nonatomic, strong) NSUserDefaults * userDefaults;

@end

@implementation SSUConfiguration

+ (instancetype) sharedInstance {
    static SSUConfiguration * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSUserDefaults *) userDefaults {
    if (_userDefaults) return _userDefaults;
    
    _userDefaults = [NSUserDefaults standardUserDefaults];
    
    return _userDefaults;
}

#pragma mark - Helper

- (void) loadFromURL:(NSURL *)url completion:(void (^)(NSError *))completion {
    NSDate * lastLoadDate = [NSDate date];
    [SSUCommunicator getJSONFromURL:url completion:^(NSURLResponse *response, id json, NSError *error) {
        if (error) {
            SSULogError(@"Error while attempting to load settings from remote url: %@", error);
            if (completion)
                completion(error);
        }
        else if (![json isKindOfClass:[NSDictionary class]]) {
            SSULogError(@"Expected dictionary from JSON, got %@ instead", NSStringFromClass([json class]));
            if (completion)
                completion(nil);
        }
        else {
            [self loadDictionary:json];
            [self setDate:lastLoadDate forKey:kSSUConfigLastLoadDateKey];
            if (completion)
                completion(nil);
        }
    }];
}

- (void) loadDictionary:(NSDictionary *)data {
    [data enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSAssert([key isKindOfClass:[NSString class]], @"All config keys should be strings");
        if (obj == [NSNull null]) {
            [self removeObjectForKey:key];
        }
        else {
            [self setObject:obj forKey:key];
        }
    }];
}

- (void) loadDefaultsFromFilePath:(NSString *)filePath {
    NSData * defaultsData = [NSData dataWithContentsOfFile:filePath];
    NSError * error;
    NSDictionary * defaults = [NSJSONSerialization JSONObjectWithData:defaultsData options:0 error:&error];
    if (error) {
        SSULogError(@"Error while loading JSON for defaults: %@", error);
    }
    else {
        [self registerDefaults:defaults];
    }
}

- (void) registerDefaults:(NSDictionary *)defaults {
    [self.userDefaults registerDefaults:defaults];
}

- (void) save {
    [self.userDefaults synchronize];
}

#pragma mark - Accessors

- (id) objectForKey:(NSString *)key {
    return [self.userDefaults objectForKey:key];
}

- (NSString *) stringForKey:(NSString *)key {
    return [self.userDefaults stringForKey:key];
}

- (NSDate *) dateForKey:(NSString *)key {
    return [self.userDefaults objectForKey:key];
}

- (NSArray *) arrayForKey:(NSString *)key {
    return [self.userDefaults arrayForKey:key];
}

- (NSDictionary *) dictionaryForKey:(NSString *)key {
    return [self.userDefaults dictionaryForKey:key];
}

- (NSData *) dataForKey:(NSString *)key  {
    return [self.userDefaults dataForKey:key];
}

- (NSArray <NSString *> *) stringArrayForKey:(NSString *)key {
    return [self.userDefaults stringArrayForKey:key];
}

- (NSInteger) integerForKey:(NSString *)key {
    return [self.userDefaults integerForKey:key];
}

- (float) floatForKey:(NSString *)key {
    return [self.userDefaults floatForKey:key];
}

- (double) doubleForKey:(NSString *)key {
    return [self.userDefaults doubleForKey:key];
}

- (BOOL) boolForKey:(NSString *)key {
    return [self.userDefaults boolForKey:key];
}

- (NSURL *) URLForKey:(NSString *)key {
    return [self.userDefaults URLForKey:key];
}

- (NSDictionary *) dictionaryRepresentation {
    NSDictionary * fullDictionary = [self.userDefaults dictionaryRepresentation];
    NSMutableDictionary * result = [NSMutableDictionary new];
    [fullDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key rangeOfString:kSSUConfigKeyPrefix].location != NSNotFound) {
            result[key] = obj;
        }
    }];
    return result;
}

#pragma mark - Setters

- (void) setObject:(id)value forKey:(NSString *)key {
    [self.userDefaults setObject:value forKey:key];
}

- (void) setArray:(NSArray *)array forKey:(NSString *)key {
    [self.userDefaults setObject:array forKey:key];
}

- (void) setDate:(NSDate *)date forKey:(NSString *)key {
    [self.userDefaults setObject:date forKey:key];
}

- (void) setStringArray:(NSArray<NSString *> *)stringArray forKey:(NSString *)key {
    [self.userDefaults setObject:stringArray forKey:key];
}

- (void) setString:(NSString *)string forKey:(NSString *)key {
    [self setObject:string forKey:key];
}

- (void) setInteger:(NSInteger)value forKey:(NSString *)key {
    [self.userDefaults setInteger:value forKey:key];
}

- (void) setFloat:(float)value forKey:(NSString *)key {
    [self.userDefaults setFloat:value forKey:key];
}

- (void) setDouble:(double)value forKey:(NSString *)key {
    [self.userDefaults setDouble:value forKey:key];
}

- (void) setBool:(BOOL)value forKey:(NSString *)key {
    [self.userDefaults setBool:value forKey:key];
}

- (void) setURL:(NSURL *)value forKey:(NSString *)key {
    [self.userDefaults setURL:value forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    [self.userDefaults removeObjectForKey:key];
}

@end
