//
//  CocoaUdpClientImpl.h
//  UDPClient
//
//  Created by Janis Kirsteins on 11.08.16.
//  Copyright © 2016. g. Stanislav Sidelnikov. All rights reserved.
//

@import Foundation;

@interface CocoaUdpClient : NSObject

- (id)init;
-(BOOL)setupSocket:(NSError**)error;
-(void)close;
-(BOOL)connectToHost:(NSString*)host port:(UInt16)port error:(NSError**)error;
-(void)sendData:(NSData*)data timeout:(NSTimeInterval)timeout;
-(NSData*)receive:(NSString**)host port:(UInt16*)port timeout:(NSTimeInterval)timeout error:(NSError**)error;

@end
