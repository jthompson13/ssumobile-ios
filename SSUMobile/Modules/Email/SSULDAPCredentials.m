//
//  SSULDAPController.m
//  SSUMobile
//
//  Created by Eric Amorde on 2/7/15.
//  Copyright (c) 2015 Sonoma State University Department of Computer Science. All rights reserved.
//

#import "SSULDAPCredentials.h"
#import "SSUMobile-Swift.h"
#import <SimpleKeychain/SimpleKeychain.h>

static NSString * kUsernameKey = @"SSUEmailUsername";
static NSString * kPasswordKey = @"SSUEmailPassword";
static NSString * kHasCredentialsKey = @"SSUEmailContainsLogin";
static NSString * kRemeberLoginKey = @"SSUEmailRememberLogin";

static NSString * kKeychainPasswordKey = @"edu.sonoma.ssumobile.ldap.password";
static NSString * kKeychainUsernameKey = @"edu.sonoma.ssumobile.ldap.username";

@interface SSULDAPCredentials()

@property A0SimpleKeychain * keychain;

@end

@implementation SSULDAPCredentials

static SSULDAPCredentials * sharedInstance;
+ (instancetype) sharedInstance {
    if (sharedInstance) {
        return sharedInstance;
    }
    sharedInstance = [[self alloc] init];
    return sharedInstance;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        sharedInstance = self;
        self.keychain = [A0SimpleKeychain keychain];
    }
    return self;
}

- (NSString *) username {
    return [self getSecureString:kKeychainUsernameKey];
}

- (NSString *) password {
    return [self getSecureString:kKeychainPasswordKey];
}

- (void) setUsername:(NSString *)username {
    [self setSecureString:username forKey:kKeychainUsernameKey];
}

- (void) setPassword:(NSString *)password {
    [self setSecureString:password forKey:kKeychainPasswordKey];
}

- (BOOL) rememberLogin {
    return [[SSUConfiguration sharedInstance] boolForKey:kRemeberLoginKey];
}

- (BOOL) hasCredentials {
    return [[SSUConfiguration sharedInstance] boolForKey:kHasCredentialsKey];
}

- (void) setRememberLogin:(BOOL)rememberLogin {
    [[SSUConfiguration sharedInstance] setBool:rememberLogin forKey:kRemeberLoginKey];
}

- (void) setHasCredentials:(BOOL)hasCredentials {
    [[SSUConfiguration sharedInstance] setBool:hasCredentials forKey:kHasCredentialsKey];
}

- (void) clearCredentials {
    [self deleteKey:kKeychainUsernameKey];
    [self deleteKey:kKeychainPasswordKey];
    [self setRememberLogin:NO];
    [self setHasCredentials:NO];
    [self save];
}

- (void) save {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) deleteKey:(NSString *)key {
    [self.keychain deleteEntryForKey:key];
}

- (NSString *) getSecureString:(NSString *)key {
    return [self.keychain stringForKey:key promptMessage:@"Allow SSUMobile to access your stored email credentials"];
}

- (void) setSecureString:(NSString *)value forKey:(NSString *)key {
    [self.keychain setString:value forKey:key promptMessage:@"Allow SSUMobile to store your credentials in your device's KeyChain"];
}

@end
