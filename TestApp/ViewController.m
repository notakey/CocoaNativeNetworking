//
//  ViewController.m
//  TestApp
//
//  Created by Janis Kirsteins on 11.08.16.
//  Copyright © 2016. g. Notakey Latvia. All rights reserved.
//

#import "ViewController.h"
@import CocoaNativeNetworking;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CocoaUdpClient *c = [CocoaUdpClient new];
    NSError *err = nil;
    
    if (![c setupSocket:&err]) {
        [NSException raise:@"setupSocket" format:@"Failed: %@", err.localizedDescription];
    }
    
    const char testData[] = {
        172, 239, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 9, 95, 110, 111, 116, 97, 107, 101, 121, 50, 4, 95, 116, 99, 112, 7, 110, 111, 116, 97, 107, 101, 121, 7, 101, 120, 97, 109, 112, 108, 101, 3, 99, 111, 109, 0, 0, 12, 0, 1
    };
    NSData *data = [NSData dataWithBytes:testData length:52];
    
    NSString *ipv6dns = @"2a03:7900:6:0:98a:d9c7:a92:2519";
    
    
    if (![c connectToHost:ipv6dns port:53 error:&err]) {
        [NSException raise:@"connectToHost" format:@"Failed: %@", err.localizedDescription];
    }
    
    
    [c sendData:data timeout:10];
//    NSData* received = [c receive:@"2001:4860:4860::8888" port:53 timeout:10];
    
    NSString *receivedHost = [NSString alloc];
    UInt16 receivedPort;
    
    NSData* received = [c receive:&receivedHost port:&receivedPort timeout:10 error:&err];
    if (err != nil && received == nil) {
        [NSException raise:@"receiveOnce" format:@"Failed: %@", err.localizedDescription];
    }
    
    NSLog(@"Done. Received from %@:%d: %@", receivedHost, receivedPort, received);
    
    [c close];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
