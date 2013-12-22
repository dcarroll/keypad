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

@interface iCarouselExampleViewController : UIViewController <iCarouselDataSource, iCarouselDelegate, NSURLConnectionDelegate>
{
    NSURLConnection *currentConnection;
}
@property (nonatomic, strong) IBOutlet iCarousel *carousel;
@property (nonatomic, strong) IBOutlet iCarousel *carousel2;
@property (nonatomic, strong) IBOutlet UINavigationItem *navItem;
@property (nonatomic, strong) IBOutlet UIBarItem *wrapBarItem;
@property (nonatomic, strong) IBOutlet UISwitch *power;
@property (nonatomic, strong) IBOutlet UISwitch *mute;
@property (nonatomic, strong) IBOutlet UISlider *volume;
@property (nonatomic, strong) NSString *input;

- (IBAction)switchCarouselType;
- (IBAction)togglePower;
- (IBAction)toggleMute;
- (IBAction)changeVolume;
- (void)changeInput;
- (void)sendRestCallPost:(NSString *)apiUrl;

@end
