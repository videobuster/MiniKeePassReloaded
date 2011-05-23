//
//  AesStreamTest.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "AesStreamTest.h"
#import "AesOutputStream.h"
#import "AesInputStream.h"
#import "DataOutputStream.h"
#import "DataInputStream.h"
#import "Utils.h"

@implementation AesStreamTest

- (void)setUp {
    password = @"test";
    
    [Utils getRandomBytes:encryptionIv length:16];
    
    kdbPassword = [[KdbPassword alloc] initForEncryption:32];
    key = [kdbPassword createFinalKey32ForPasssword:password encoding:NSUTF8StringEncoding kdbVersion:4];
}

- (void)tearDown {
    [key release];
    [kdbPassword release];
}

- (void)testAesStream {
    // Prepare some data to encrypt
    uint8_t outputBuffer[1024*1024];
    for (int i = 0; i < 1024*1024; i++) {
        outputBuffer[i] = i;
    }
    
    // Create the output stream
    DataOutputStream *dataOutputStream = [[DataOutputStream alloc] init];
    AesOutputStream *aesOutputStream = [[AesOutputStream alloc] initWithOutputStream:dataOutputStream key:key._bytes iv:encryptionIv];
    
    // Write out 1MB of data 1024 bytes at a time
    for (int i = 0; i < 1024*1024; i += 1024) {
        NSUInteger numWritten = [aesOutputStream write:(outputBuffer+i) length:1024];
        STAssertTrue(numWritten == 1024, @"Did not write expected number of bytes (%d)", numWritten);
    }
    
    [aesOutputStream close];
    
    // Create the input stream from the output streams data
    DataInputStream *dataInputStream = [[DataInputStream alloc] initWithData:dataOutputStream.data];
    AesInputStream *aesInputStream = [[AesInputStream alloc] initWithInputStream:dataInputStream key:key._bytes iv:encryptionIv];
    
    // Read in 1MB of data 512 blocks at a time
    uint8_t inputBuffer[1024 * 1024];
    for (int i = 0; i < 1024*1024; i += 512) {
        NSUInteger numRead = [aesInputStream read:(inputBuffer+i) length:512];
        STAssertTrue(numRead == 512, @"Did not read expected number of bytes (%d)", numRead);
    }
    
    [aesInputStream close];
    
    // Check if the streams differ
    BOOL differs = NO;
    for (int i = 0; i < 1024 * 1024 && !differs; i++) {
        differs |= (outputBuffer[i] != inputBuffer[i]);
    }
    
    STAssertFalse(differs, @"Streams do not match");
}

@end