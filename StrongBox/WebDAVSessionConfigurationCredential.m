#import "WebDAVSessionConfigurationCredential.h"
#import "SecretStore.h"
#import "NSString+Extensions.h"
#import "SBLog.h"

@interface WebDAVSessionConfigurationCredential ()

@property NSString* keyChainUuid;

@property (nullable) NSString* pendingPassword;
@property BOOL passwordDirty;

@end

@implementation WebDAVSessionConfigurationCredential

- (instancetype)init {
    return [self initWithKeyChainUuid:[[NSUUID UUID] UUIDString]];
}

- (instancetype)initWithKeyChainUuid:(NSString*)keyChainUuid {
    if(self = [super init]) {
        self.keyChainUuid = keyChainUuid;
        self.identifier = NSUUID.UUID.UUIDString;
    }
    
    return self;
}

- (NSDictionary *)serializationDictionary {
    NSMutableDictionary* ret = [NSMutableDictionary dictionary];

    if (self.identifier) {
        [ret setValue:self.identifier forKey:@"identifier"];
    }

    if (self.username) {
        [ret setValue:self.username forKey:@"username"];
    }

    if (self.keyChainUuid) {
        [ret setValue:self.keyChainUuid forKey:@"keyChainUuid"];
    }

    [self persistPendingPasswordIfNeeded];
    
    return ret;
}

+ (instancetype)fromSerializationDictionary:(NSDictionary *)dictionary {
    NSString* keyChainUuid = dictionary[@"keyChainUuid"];
    if (!keyChainUuid) {
        return nil;
    }

    WebDAVSessionConfigurationCredential *creds = [[WebDAVSessionConfigurationCredential alloc] initWithKeyChainUuid:keyChainUuid];

    NSString* identifier = dictionary[@"identifier"];
    if (identifier) {
        creds.identifier = identifier;
    }

    creds.username = dictionary[@"username"];

    return creds;
}

-(NSString*)getKeyChainKey:(NSString*)propertyName {
    return [NSString stringWithFormat:@"Strongbox-WebDAV-%@-%@", self.keyChainUuid, propertyName];
}

-(NSString *)password {
    if (self.passwordDirty) {
        return self.pendingPassword;
    }
    return [SecretStore.sharedInstance getSecureString:[self getKeyChainKey:@"password"]];
}

- (void)setPassword:(NSString *)password {
    self.pendingPassword = password;
    self.passwordDirty = YES;
}

- (void)clearKeychainItems {
    [SecretStore.sharedInstance deleteSecureItem:[self getKeyChainKey:@"password"]];
    self.pendingPassword = nil;
    self.passwordDirty = NO;
}

- (void)persistPendingPasswordIfNeeded {
    if (!self.passwordDirty) {
        return;
    }

    if (self.pendingPassword) {
        [SecretStore.sharedInstance setSecureString:self.pendingPassword forIdentifier:[self getKeyChainKey:@"password"]];
    } else {
        [SecretStore.sharedInstance deleteSecureItem:[self getKeyChainKey:@"password"]];
    }

    self.passwordDirty = NO;
    self.pendingPassword = nil;
}

@end
