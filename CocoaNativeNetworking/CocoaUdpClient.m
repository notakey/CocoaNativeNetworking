//
//  CocoaUdpClientImpl.m
//  UDPClient
//
//  Created by Janis Kirsteins on 11.08.16.
//  Copyright © 2016. g. Stanislav Sidelnikov. All rights reserved.
//

#import "CocoaUdpClient.h"
@import CocoaAsyncSocket;

typedef void (^ReceiveCallback)(NSData*, NSString *, UInt16);


@interface MyDelegate : NSObject<GCDAsyncUdpSocketDelegate>

@property (nonatomic, copy) ReceiveCallback callback;
@property (nonatomic, strong) NSData *address;
@end

@implementation MyDelegate

-(id)initWithAddress:(NSData*)address callback:(ReceiveCallback)callback {
    if (self == [super init]) {
        self.callback = callback;
        self.address = address;
    }
    return self;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSString *host = [GCDAsyncSocket hostFromAddress:address];
    UInt16 port = [GCDAsyncSocket portFromAddress:address];
    self.callback(data, host, port);
}

@end

@interface CocoaUdpClient() <GCDAsyncUdpSocketDelegate>
@property (strong,nonatomic) GCDAsyncUdpSocket *socket;
@property (strong,nonatomic) id<GCDAsyncUdpSocketDelegate> innerDelegate;
@end

@implementation CocoaUdpClient

- (id)init {
    if (self = [super init]) {
        self.socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        self.innerDelegate = nil;
    }
    return self;
}

-(BOOL)setupSocket:(NSError **)errPtr {

    if (![self.socket bindToPort:0 error:errPtr]) {
        return false;
    }
    
    return true;
}

-(BOOL)connectToHost:(NSString*)host port:(UInt16)port error:(NSError**)error {
    NSLog(@"Connected: %@", nil);
    BOOL result = [self.socket connectToHost:host onPort:port error:error];
    NSLog(@"Connected: %@", self.socket.connectedAddress);
    return result;
}

-(void)sendData:(NSData*)data timeout:(NSTimeInterval)timeout {
    [self.socket sendData:data withTimeout:timeout tag:0];
}

-(NSData*)receive:(NSString**)host port:(UInt16*)port timeout:(NSTimeInterval)timeout error:(NSError**)error {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block NSData* result = nil;
    __block NSString* responderHost = nil;
    __block UInt16 responderPort = 0;
    
    NSAssert(self.socket.connectedAddress != nil, @"Socket not connected");
    
    MyDelegate *deleg = [[MyDelegate alloc] initWithAddress:self.socket.connectedAddress callback:^(NSData *data, NSString *_rHost, UInt16 _rPort) {
        result = data;
        responderHost = _rHost;
        responderPort = _rPort;
        dispatch_semaphore_signal(sema);
    }];
    
    self.innerDelegate = deleg;
    if (![self.socket receiveOnce:error]) {
        return nil;
    }
    
    dispatch_time_t semaTimeout = DISPATCH_TIME_FOREVER;
    if (semaTimeout != 0) {
        semaTimeout = dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC);
    }
    
    dispatch_semaphore_wait(sema, semaTimeout);
    
    (*host) = responderHost;
    (*port) = responderPort;
    
    self.innerDelegate = nil;
    return result;
}

- (void)close {
    [self.socket close];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if (self.innerDelegate != nil) {
        [self.innerDelegate udpSocket:sock didReceiveData:data fromAddress:address withFilterContext:filterContext];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"Sent data");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    [NSException raise:@"didNotConect" format:@"%@", error.localizedDescription];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSLog(@"Did connect");
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    if (error != nil) {
        [NSException raise:@"udpSocketDidClose" format:@"%@", error.localizedDescription];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    [NSException raise:@"udpSocketDidClose" format:@"%@", error.localizedDescription];
}

@end
