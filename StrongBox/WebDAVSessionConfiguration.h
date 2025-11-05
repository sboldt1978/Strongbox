//
//  WebDAVSessionConfiguration.h
//  Strongbox
//
//  Created by Mark on 11/12/2018.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebDAVSessionConfigurationCredential.h"

NS_ASSUME_NONNULL_BEGIN

@interface WebDAVSessionConfiguration : NSObject

@property NSString* identifier;

@property (readonly) NSArray<WebDAVSessionConfigurationCredential*>* credentials;
@property (nonatomic, nullable) NSString* selectedCredentialIdentifier;

@property NSURL* host;
@property (nullable) NSString* name;
@property NSString* username;
@property NSString* password;
@property BOOL allowUntrustedCertificate;

- (NSDictionary*)serializationDictionary;
+ (instancetype _Nullable)fromSerializationDictionary:(NSDictionary*)dictionary;

-(NSString*)getKeyChainKey:(NSString*)propertyName;

- (void)clearKeychainItems;

- (BOOL)isTheSameConnection:(WebDAVSessionConfiguration*)other;
- (BOOL)isNetworkingFieldsAreSame:(WebDAVSessionConfiguration *)other;

- (WebDAVSessionConfigurationCredential* _Nullable)selectedCredential;
- (WebDAVSessionConfigurationCredential* _Nullable)credentialWithIdentifier:(NSString*)identifier;
- (void)upsertCredential:(WebDAVSessionConfigurationCredential*)credential setAsSelected:(BOOL)setAsSelected;
- (void)removeCredentialByIdentifier:(NSString*)identifier;

@end

NS_ASSUME_NONNULL_END
