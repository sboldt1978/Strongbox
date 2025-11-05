#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebDAVSessionConfigurationCredential : NSObject

@property NSString* identifier;
@property NSString* username;
@property NSString* password;
@property (readonly) NSString* keyChainUuid;

- (instancetype)init;
- (instancetype)initWithKeyChainUuid:(NSString*)keyChainUuid;

- (NSDictionary*)serializationDictionary;
+ (instancetype _Nullable)fromSerializationDictionary:(NSDictionary*)dictionary;

- (void)clearKeychainItems;

@end

NS_ASSUME_NONNULL_END
