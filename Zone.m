//
//  Zone.m
//  iCarouselExample
//
//  Created by Dave Carroll on 12/22/13.
//
//

#import "Zone.h"

@implementation Zone

@synthesize zoneAddress;
@synthesize command;
@synthesize mediaInput;
@synthesize volume;
@synthesize balance;
@synthesize bass;
@synthesize treble;
@synthesize partyModeInput;
@synthesize partyMode;
@synthesize power;
@synthesize mute;
@synthesize mode;
@synthesize power2;

- (id) initWithData:(NSDictionary *)data {
 
    self = [super init];
    self.zoneAddress = [data objectForKey:@"zoneAddress"];
    self.command = [data objectForKey:@"command"];
    self.mediaInput = [data objectForKey:@"mediaInput"];
    self.volume = [data objectForKey:@"volume"];
    self.balance = [data objectForKey:@"balance"];
    self.treble = [data objectForKey:@"treble"];
    self.bass = [data objectForKey:@"bass"];
    if ([[data valueForKey:@"partyMode"] isEqual: @"1"]) {
        self.partyMode = YES;
    } else {
        self.partyMode = NO;
    }
    self.partyModeInput = (NSString *)[data objectForKey:@"partyModeInput"];
    if ([[data valueForKey:@"power"] isEqualToString:@"1"]) {
        self.power = YES;
    } else {
        self.power = NO;
    }
    if ([[data valueForKey:@"mute"] isEqualToString:@"1"]) {
        self.mute = YES;
    } else {
        self.mute = NO;
    }
    if ([[data valueForKey:@"mode"] isEqualToString:@"1"]) {
        self.mode = YES;
    } else {
        self.mode = NO;
    }
    if ([[data valueForKey:@"power2"] isEqualToString:@"1"]) {
        self.power2 = YES;
    } else {
        self.power2 = NO;
    }

    return self;
}

- (void) updateWithData:(NSDictionary *)data {
 
    self.zoneAddress = [data objectForKey:@"zoneAddress"];
    self.command = [data objectForKey:@"command"];
    self.mediaInput = [data objectForKey:@"mediaInput"];
    self.volume = [data objectForKey:@"volume"];
    self.balance = [data objectForKey:@"balance"];
    self.treble = [data objectForKey:@"treble"];
    self.bass = [data objectForKey:@"bass"];
    if ([[data valueForKey:@"partyMode"] isEqual: @"1"]) {
        self.partyMode = YES;
    } else {
        self.partyMode = NO;
    }
    self.partyModeInput = (NSString *)[data objectForKey:@"partyModeInput"];
    if ([[data valueForKey:@"power"] isEqualToString:@"1"]) {
        self.power = YES;
    } else {
        self.power = NO;
    }
    if ([[data valueForKey:@"mute"] isEqualToString:@"1"]) {
        self.mute = YES;
    } else {
        self.mute = NO;
    }
    if ([[data valueForKey:@"mode"] isEqualToString:@"1"]) {
        self.mode = YES;
    } else {
        self.mode = NO;
    }
    if ([[data valueForKey:@"power2"] isEqualToString:@"1"]) {
        self.power2 = YES;
    } else {
        self.power2 = NO;
    }

}

@end
