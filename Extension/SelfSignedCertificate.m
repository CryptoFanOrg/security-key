//
//  SelfSignedCertificate.m
//  SecurityKey
//
//  Created by Benjamin P Toews on 8/19/16.
//  Copyright © 2016 mastahyeti. All rights reserved.
//

// http://opensource.apple.com/source/OpenSSL/OpenSSL-22/openssl/demos/x509/mkcert.c

#import "SelfSignedCertificate.h"

@implementation SelfSignedCertificate

- (id)init
{
    self = [super init];
    if (self) {
        if ([self generateKeyPair] && [self generateX509]) {
            printf("SelfSignedCertificate initialized\n");
        } else {
            printf("Error initializing SelfSignedCertificate\n");
        }
    }
    return self;
}

- (int)generateX509
{
    self.x509 = X509_new();
    if (self.x509 == NULL) {
        printf("failed to init x509\n");
        return 0;
    }
    
    X509_set_version(self.x509, 2);
    ASN1_INTEGER_set(X509_get_serialNumber(self.x509), 1);
    X509_gmtime_adj(X509_get_notBefore(self.x509), 0);
    X509_gmtime_adj(X509_get_notAfter(self.x509),(long)60*60*24*1);
    X509_set_pubkey(self.x509, self.pkey);
    
    X509_NAME* name = X509_get_subject_name(self.x509);
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC, (const unsigned char*)"mastahyeti", -1, -1, 0);
    
    X509_set_issuer_name(self.x509, name);
    
    if (!X509_sign(self.x509, self.pkey, EVP_sha256())) {
        printf("failed to sign cert\n");
        return 0;
    }

    return 1;
}

- (int)generateKeyPair
{
    self.pkey = EVP_PKEY_new();
    if (self.pkey == NULL) {
        printf("failed to init pkey\n");
        return 0;
    }
    
    EC_KEY* ec = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1);
    if (ec == NULL) {
        printf("failed to init ec by curve name\n");
        return 0;
    }
    
    if (EVP_PKEY_assign_EC_KEY(self.pkey, ec) != 1) {
        printf("failed to assing ec to pkey\n");
        return 0;
    }
    
    if (EC_KEY_generate_key(ec) != 1) {
        printf("couldn't generate ec key\n");
        return 0;
    }

    return 1;
}

- (NSString*)toDer
{
    unsigned char* buf = NULL;
    unsigned int len = i2d_X509(self.x509, &buf);
//    return [NSString stringWithCString:(const char*)buf encoding:NSASCIIStringEncoding];
    return [[NSString alloc] initWithBytes: buf length: len encoding:NSASCIIStringEncoding];
}

- (NSString*)signData:(NSData*)msg
{
    EVP_MD_CTX ctx;
    const unsigned char* cmsg = (const unsigned char*)[msg bytes];
    unsigned char* sig = (unsigned char*)malloc(EVP_PKEY_size(self.pkey));
    unsigned int len;
    
    for(unsigned int i = 0, len = (unsigned int)[msg length]; i < len; i++) {
        printf("%d ", (int)cmsg[i]);
    }
    printf("\n");
    
    if (EVP_SignInit(&ctx, EVP_sha256()) != 1) {
        printf("failed to init signing context\n");
        return nil;
    };
    
    if (EVP_SignUpdate(&ctx, cmsg, (unsigned int)[msg length]) != 1) {
        printf("failed to update digest\n");
        return nil;
    }
    
    if (EVP_SignFinal(&ctx, sig, &len, self.pkey) != 1) {
        printf("failed to finalize digest\n");
        return nil;
    }
    
    return [[NSString alloc] initWithBytes: sig length: len encoding:NSASCIIStringEncoding];
}

- (void)dealloc
{
    X509_free(self.x509); self.x509 = NULL;
    EVP_PKEY_free(self.pkey); self.pkey = NULL;
}

@end