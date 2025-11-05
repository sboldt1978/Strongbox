//
//  WebDAVSessionConfiguration.m
//  Strongbox
//
//  Created by Mark on 11/12/2018.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import "WebDAVSessionConfiguration.h"
#import "SecretStore.h"
#import "NSString+Extensions.h"
#import "SBLog.h"

@interface WebDAVSessionConfiguration ()

@property NSMutableArray<WebDAVSessionConfigurationCredential*>* mutableCredentials;

@end

@implementation WebDAVSessionConfiguration

- (instancetype)init {
    return [self initWithKeyChainUuid:[[NSUUID UUID] UUIDString]];
}

- (instancetype)initWithKeyChainUuid:(NSString*)keyChainUuid {
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    self.identifier = NSUUID.UUID.UUIDString;
    self.mutableCredentials = [NSMutableArray array];
}

- (NSArray<WebDAVSessionConfigurationCredential*>*)credentials {
    return [self.mutableCredentials copy];
}

- (void)setSelectedCredentialIdentifier:(NSString *)selectedCredentialIdentifier {
    _selectedCredentialIdentifier = selectedCredentialIdentifier;
    [self normalizeSelectedCredentialIdentifier];
}

- (NSDictionary *)serializationDictionary {
    NSMutableDictionary* ret = [NSMutableDictionary dictionary];
    
    [ret setValue:self.identifier forKey:@"identifier"];
    if (self.name) [ret setValue:self.name forKey:@"name"];
    
    if (self.host) [ret setValue:self.host.absoluteString forKey:@"host"];
    
    if (self.selectedCredential) [ret setValue:self.selectedCredential.keyChainUuid forKey:@"keyChainUuid"];
    if (self.selectedCredentialIdentifier) [ret setValue:self.selectedCredentialIdentifier forKey:@"selectedCredentialIdentifier"];
    
    [ret setValue:@(self.allowUntrustedCertificate) forKey:@"allowUntrustedCertificate"];
    
    if(self.mutableCredentials.count > 0) {
        NSMutableArray<NSDictionary*>* serializedCredentials = [NSMutableArray arrayWithCapacity:self.mutableCredentials.count];
        for (WebDAVSessionConfigurationCredential* credential in self.mutableCredentials) {
            NSDictionary* serialized = [credential serializationDictionary];
            if (serialized.count > 0) {
                [serializedCredentials addObject:serialized];
            }
        }
        if(serializedCredentials.count > 0) {
            [ret setValue:serializedCredentials forKey:@"credentials"];
        }
    }
    
    return ret;
}

+ (instancetype)fromSerializationDictionary:(NSDictionary *)dictionary {
    WebDAVSessionConfiguration *ret = [[WebDAVSessionConfiguration alloc] init];
    
    if ( dictionary[@"identifier"] ) ret.identifier = dictionary[@"identifier"];
    if ( dictionary[@"name"] ) ret.name = dictionary[@"name"];
    
    NSString* host = [dictionary objectForKey:@"host"];
    
    ret.host = host.urlExtendedParse;
    
    NSNumber* num = [dictionary objectForKey:@"allowUntrustedCertificate"];
    if(num != nil) {
        ret.allowUntrustedCertificate = num.boolValue;
    }
    
    NSArray* serializedCredentials = dictionary[@"credentials"];
    if ([serializedCredentials isKindOfClass:NSArray.class] && serializedCredentials.count > 0) {
        NSMutableArray<WebDAVSessionConfigurationCredential*>* loadedCredentials = [NSMutableArray arrayWithCapacity:serializedCredentials.count];
        for (NSDictionary* serialized in serializedCredentials) {
            if (![serialized isKindOfClass:NSDictionary.class]) {
                continue;
            }
            WebDAVSessionConfigurationCredential* credential = [WebDAVSessionConfigurationCredential fromSerializationDictionary:serialized];
            if (credential) {
                [loadedCredentials addObject:credential];
            }
        }
        
        if (loadedCredentials.count > 0) {
            ret.mutableCredentials = loadedCredentials;
        }
    }
    
    if (ret.mutableCredentials.count == 0) {
        NSString* keyChainUuid = dictionary[@"keyChainUuid"];
        WebDAVSessionConfigurationCredential* fallbackCredential = nil;
        if (keyChainUuid) {
            fallbackCredential = [[WebDAVSessionConfigurationCredential alloc] initWithKeyChainUuid:keyChainUuid];
        }
        else {
            fallbackCredential = [[WebDAVSessionConfigurationCredential alloc] init];
        }
        fallbackCredential.username = [dictionary objectForKey:@"username"];
        ret.mutableCredentials = [NSMutableArray arrayWithObject:fallbackCredential];
    } else {
        NSString* legacyUsername = dictionary[@"username"];
        if (legacyUsername.length > 0 && !ret.selectedCredential.username) {
            ret.selectedCredential.username = legacyUsername;
        }
    }
    
    NSString* selectedIdentifier = dictionary[@"selectedCredentialIdentifier"];
    if (selectedIdentifier) {
        ret.selectedCredentialIdentifier = selectedIdentifier;
    } else {
        NSString* keyChainUuid = dictionary[@"keyChainUuid"];
        if (keyChainUuid) {
            WebDAVSessionConfigurationCredential* credential = [ret credentialMatchingKeyChainUuid:keyChainUuid];
            if (credential) {
                ret.selectedCredentialIdentifier = credential.identifier;
            }
        }
    }
    
    [ret normalizeSelectedCredentialIdentifier];
    
    return ret;
}

-(NSString*)getKeyChainKey:(NSString*)propertyName {
    WebDAVSessionConfigurationCredential* credential = [self selectedCredential];
    if (!credential) {
        return nil;
    }
    return [NSString stringWithFormat:@"Strongbox-WebDAV-%@-%@", credential.keyChainUuid, propertyName];
}

-(NSString *)username {
    return self.selectedCredential.username;
}

- (void)setUsername:(NSString *)username {
    WebDAVSessionConfigurationCredential* credential = [self ensureSelectedCredential];
    credential.username = username;
}

-(NSString *)password {
    return self.selectedCredential.password;
}

- (void)setPassword:(NSString *)password {
    WebDAVSessionConfigurationCredential* credential = [self ensureSelectedCredential];
    credential.password = password;
}

- (void)clearKeychainItems {
    for (WebDAVSessionConfigurationCredential* credential in self.mutableCredentials) {
        [credential clearKeychainItems];
    }
}

- (BOOL)isTheSameConnection:(WebDAVSessionConfiguration *)other {
    return [self isTheSameConnection:other checkNetworkingFieldsOnly:NO];
}

- (BOOL)isNetworkingFieldsAreSame:(WebDAVSessionConfiguration *)other {
    return [self isTheSameConnection:other checkNetworkingFieldsOnly:YES];
}

- (BOOL)isTheSameConnection:(WebDAVSessionConfiguration*)other checkNetworkingFieldsOnly:(BOOL)checkNetworkingFieldsOnly {
    if (other == self) {
        return YES;
    }
    
    BOOL nameChanged = !checkNetworkingFieldsOnly && ![self.name isEqualToString:other.name];
    
    BOOL hostChanged = ![self.host.absoluteString isEqualToString:other.host.absoluteString];
    BOOL certChanged = self.allowUntrustedCertificate != other.allowUntrustedCertificate;
    
    BOOL credentialsChanged = ![self credentialsAreEquivalentTo:other includePasswords:YES];
    BOOL selectedUsernameChanged = ![[self username] isEqualToString:[other username]];
    BOOL selectedPasswordChanged = self.password != nil ? ![self.password isEqualToString:other.password] : YES;
    
    slog(@"🐞 isTheSameConnection: %hhd, %hhd, %hhd, %hhd, %hhd, %hhd", nameChanged, hostChanged, selectedUsernameChanged, selectedPasswordChanged, certChanged, credentialsChanged);

    return !(nameChanged || hostChanged || selectedUsernameChanged || selectedPasswordChanged || certChanged || credentialsChanged);
}

- (WebDAVSessionConfigurationCredential *)selectedCredential {
    [self normalizeSelectedCredentialIdentifier];
    if (!self.selectedCredentialIdentifier) {
        return nil;
    }
    return [self credentialWithIdentifier:self.selectedCredentialIdentifier];
}

- (WebDAVSessionConfigurationCredential *)credentialWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return nil;
    }
    for (WebDAVSessionConfigurationCredential* credential in self.mutableCredentials) {
        if ([credential.identifier isEqualToString:identifier]) {
            return credential;
        }
    }
    return nil;
}

- (void)upsertCredential:(WebDAVSessionConfigurationCredential *)credential setAsSelected:(BOOL)setAsSelected {
    if (!credential) {
        return;
    }
    NSUInteger existingIndex = [self.mutableCredentials indexOfObjectPassingTest:^BOOL(WebDAVSessionConfigurationCredential * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.identifier isEqualToString:credential.identifier];
    }];
    if (existingIndex != NSNotFound) {
        WebDAVSessionConfigurationCredential* existing = self.mutableCredentials[existingIndex];
        if (![existing.keyChainUuid isEqualToString:credential.keyChainUuid]) {
            [existing clearKeychainItems];
        }
        [self.mutableCredentials replaceObjectAtIndex:existingIndex withObject:credential];
    }
    else {
        [self.mutableCredentials addObject:credential];
    }

    if (setAsSelected) {
        _selectedCredentialIdentifier = credential.identifier;
    }
    
    [self normalizeSelectedCredentialIdentifier];
}

- (void)removeCredentialByIdentifier:(NSString *)identifier {
    if (!identifier) {
        return;
    }
    NSUInteger index = [self.mutableCredentials indexOfObjectPassingTest:^BOOL(WebDAVSessionConfigurationCredential * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.identifier isEqualToString:identifier];
    }];
    if (index == NSNotFound) {
        return;
    }
    WebDAVSessionConfigurationCredential* credential = self.mutableCredentials[index];
    [credential clearKeychainItems];
    [self.mutableCredentials removeObjectAtIndex:index];
    if ([self.selectedCredentialIdentifier isEqualToString:identifier]) {
        _selectedCredentialIdentifier = nil;
    }
    [self normalizeSelectedCredentialIdentifier];
}

#pragma mark - Helpers

- (void)normalizeSelectedCredentialIdentifier {
    if (self.mutableCredentials.count == 0) {
        _selectedCredentialIdentifier = nil;
        return;
    }
    if (!_selectedCredentialIdentifier || ![self credentialWithIdentifier:_selectedCredentialIdentifier]) {
        _selectedCredentialIdentifier = self.mutableCredentials.firstObject.identifier;
    }
}

- (WebDAVSessionConfigurationCredential*)ensureSelectedCredential {
    WebDAVSessionConfigurationCredential* credential = [self selectedCredential];
    if (!credential) {
        credential = [[WebDAVSessionConfigurationCredential alloc] init];
        [self.mutableCredentials addObject:credential];
        _selectedCredentialIdentifier = credential.identifier;
    }
    return credential;
}

- (WebDAVSessionConfigurationCredential*)credentialMatchingKeyChainUuid:(NSString*)keyChainUuid {
    if (!keyChainUuid) {
        return nil;
    }
    for (WebDAVSessionConfigurationCredential* credential in self.mutableCredentials) {
        if ([credential.keyChainUuid isEqualToString:keyChainUuid]) {
            return credential;
        }
    }
    return nil;
}

- (BOOL)credentialsAreEquivalentTo:(WebDAVSessionConfiguration*)other includePasswords:(BOOL)includePasswords {
    if (self.mutableCredentials.count != other.mutableCredentials.count) {
        return NO;
    }
    for (WebDAVSessionConfigurationCredential* credential in self.mutableCredentials) {
        WebDAVSessionConfigurationCredential* otherCredential = [other credentialWithIdentifier:credential.identifier];
        if (!otherCredential) {
            return NO;
        }
        BOOL usernameEqual = (!credential.username && !otherCredential.username) || [credential.username isEqualToString:otherCredential.username];
        if (!usernameEqual) {
            return NO;
        }
        if (includePasswords) {
            NSString* password = credential.password;
            NSString* otherPassword = otherCredential.password;
            BOOL passwordEqual = (!password && !otherPassword) || [password isEqualToString:otherPassword];
            if (!passwordEqual) {
                return NO;
            }
        }
    }
    WebDAVSessionConfigurationCredential* selected = [self selectedCredential];
    WebDAVSessionConfigurationCredential* otherSelected = [other selectedCredential];
    NSString* selectedIdentifier = selected.identifier;
    NSString* otherSelectedIdentifier = otherSelected.identifier;
    BOOL selectedEqual = (!selectedIdentifier && !otherSelectedIdentifier) || [selectedIdentifier isEqualToString:otherSelectedIdentifier];
    return selectedEqual;
}

@end
