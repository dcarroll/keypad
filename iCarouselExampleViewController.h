//
//  iCarouselExampleViewController.h
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
#import "Constants.h"
#import "SocketIO.h"
#import <AudioToolbox/AudioToolbox.h>

@interface iCarouselExampleViewController : UIViewController <iCarouselDataSource, iCarouselDelegate, NSURLConnectionDelegate, SocketIODelegate>
{
    NSURLConnection *currentConnection;
    double currentStepValue;
    SystemSoundID _clickSound;
    SystemSoundID _selectSound;
    BOOL socketIsConnected;
    BOOL replay;
    NSDictionary *replayData;
}
@property (nonatomic, strong) IBOutlet iCarousel *carousel;
@property (nonatomic, strong) IBOutlet iCarousel *carousel2;
@property (nonatomic, strong) IBOutlet UINavigationItem *navItem;
@property (nonatomic, strong) IBOutlet UIBarItem *wrapBarItem;
@property (nonatomic, strong) IBOutlet UIButton *powerButton;
@property (nonatomic, strong) IBOutlet UIButton *muteButton;
@property (nonatomic, strong) NSString *input;

- (IBAction)switchCarouselType;
- (IBAction)togglePower;
- (IBAction)toggleMute;
- (IBAction)volumeUp;
- (IBAction)volumeDown;

- (void)changeInput;
- (void)sendRestCallPost:(NSString *)apiUrl;
- (void)sendSocketEvent:(NSString *)cmd withData:(NSMutableDictionary *)args;

@end
