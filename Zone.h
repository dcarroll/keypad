//
//  Zone.h
//  iCarouselExample
//
//  Created by Dave Carroll on 12/22/13.
//
//

#import <Foundation/Foundation.h>

@interface Zone : NSObject

@property (nonatomic) NSNumber* zoneAddress;
@property (nonatomic) NSNumber* command;
@property (nonatomic) NSNumber* mediaInput;
@property (nonatomic) NSNumber* volume;
@property (nonatomic) NSNumber* balance;
@property (nonatomic) NSNumber* treble;
@property (nonatomic) NSNumber* bass;
@property (nonatomic) BOOL partyMode;
@property (nonatomic) NSString* partyModeInput;
@property (nonatomic) BOOL power;
@property (nonatomic) BOOL mute;
@property (nonatomic) BOOL mode;
@property (nonatomic) BOOL power2;

- (id) initWithData:(NSDictionary *)data;
- (void) updateWithData:(NSDictionary *)data;

@end
