//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleViewController.h"
#import "SocketIO.h"
#import "SocketIOPacket.h"
#import "Zone.h"

@interface iCarouselExampleViewController () <UIActionSheetDelegate>

@property (nonatomic, assign) BOOL wrap;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) NSInteger *zoneAddress;
@property (nonatomic, strong) NSMutableDictionary *zonedata;
@property (nonatomic, strong) UILabel *vlabel;
@property (nonatomic, strong) NSMutableArray *inputitems;
@property (nonatomic, strong) SocketIO *socket;

@end


@implementation iCarouselExampleViewController

@synthesize carousel;
@synthesize carousel2;
@synthesize navItem;
@synthesize wrapBarItem;
@synthesize wrap;
@synthesize items;
@synthesize inputitems;
@synthesize zoneAddress;
@synthesize powerButton;
@synthesize muteButton;
@synthesize input;
@synthesize zonedata;
@synthesize vlabel;
@synthesize socket;

- (void)setUp
{
    socket = [[SocketIO alloc] initWithDelegate:self];
    [self connectSocket];
}

- (void) connectSocket {
    //[socket connectToHost:@"10.0.0.52" onPort:3000];
    [socket connectToHost:@"10.0.0.30" onPort:3000];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setUp];
    }
    return self;
}

- (void)dealloc
{
    //it's a good idea to set these to nil here to avoid
    //sending messages to a deallocated viewcontroller
    carousel.delegate = nil;
    carousel.dataSource = nil;
    carousel2.delegate = nil;
    carousel2.dataSource = nil;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //configure carousel
    carousel.type = iCarouselTypeLinear;
    carousel2.type = iCarouselTypeLinear;
    navItem.title = @"Carroll Keypad";
    // And only one sound plays at a time!
	NSString *clicksoundPath = [[NSBundle mainBundle] pathForResource:@"button-50" ofType:@"mp3"];
	NSURL *clicksoundUrl = [NSURL fileURLWithPath:clicksoundPath];
	NSString *selectsoundPath = [[NSBundle mainBundle] pathForResource:@"beep-21" ofType:@"mp3"];
	NSURL *selectsoundUrl = [NSURL fileURLWithPath:selectsoundPath];
	AudioServicesCreateSystemSoundID((__bridge CFURLRef)clicksoundUrl, &_clickSound);
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)selectsoundUrl, &_selectSound);

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.carousel = nil;
    self.carousel2 = nil;
    self.navItem = nil;
    self.wrapBarItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    NSLog(@"Disconnected...");
    socketIsConnected = NO;
}

- (void) socketIODidConnect:(SocketIO *)asocket
{
    NSLog(@"socket.io connected.");
    socketIsConnected = YES;
    if (replay == YES) {
        [self sendSocketEvent:[replayData objectForKey:@"cmd"] withData:[replayData objectForKey:@"data"]];
        replay = false;
        replayData = nil;
    }
}

- (void) socketIO:(SocketIO *)asocket didReceiveEvent:(SocketIOPacket *)packet
{
    NSLog(@"didReceiveEvent() %@", [packet data] );
    NSDictionary *jdata = [packet dataAsJSON];
    NSArray *args = [jdata objectForKey:@"args"];
    NSDictionary *arg = [args objectAtIndex:0];
    
    NSString *name = (NSString *)[jdata objectForKey:@"name"];
    
    if (![name isEqualToString:@"connected"]) {
        if ([name isEqualToString:@"zoneupdate"]) {
            NSNumber *resv = [arg objectForKey:@"reserved"];
            if ([resv integerValue] == 0) {
                NSLog(@"Getting zone address from socket data");
                NSNumber *zind = [arg objectForKey:@"zoneAddress"];
                NSString *zkey = [NSString stringWithFormat:@"zone%@", zind];
            
                Zone* z = [self.zonedata objectForKey:zkey];
            
                NSLog(@"Updating zone data.");
                if (z == nil) {
                    z = [[Zone alloc] initWithData:arg];
                    if ([zind integerValue] != 0) {
                        [self.zonedata setObject:z forKey:zkey];
                    } else {
                        return;
                    }
                } else {
                    [z updateWithData:arg];
                }
                if (z.power == YES) {
                    [powerButton setImage:[UIImage imageNamed:@"powerOn.png"] forState:UIControlStateNormal];
                } else {
                    [powerButton setImage:[UIImage imageNamed:@"powerOff.png"] forState:UIControlStateNormal];
                }
                if (z.mute == YES) {
                    [muteButton setImage:[UIImage imageNamed:@"muteOn.png"] forState:UIControlStateNormal];
                } else {
                    [muteButton setImage:[UIImage imageNamed:@"muteOff.png"] forState:UIControlStateNormal];
                }

                currentStepValue = [z.volume doubleValue];
                UILabel *vLabel = (UILabel *)[[carousel currentItemView] viewWithTag:2];
                vLabel.text = [NSString stringWithFormat:@"%f", currentStepValue];
                [carousel2 setCurrentItemIndex:[z.mediaInput integerValue] - 1];
                [carousel reloadData];
            }
        }
        if ([name isEqualToString:@"settings"]) {
            [self processSettings:arg];
        }
    } else {
        [self sendSocketEvent:@"sendsettings" withData:nil];
        zoneAddress = 1;

    }
}

- (void)sendSocketEvent:(NSString *)cmd withData:(NSMutableDictionary *)args {
    if (socketIsConnected) {
        [socket sendEvent:cmd withData:args];
    } else {
        replay = true;
        replayData = [NSDictionary dictionaryWithObjectsAndKeys:cmd, @"cmd", args, @"data", nil];
        [self connectSocket];
    }
}

- (void)processSettings:(NSDictionary *)settingsData {
    NSMutableDictionary* zones = [settingsData valueForKey:@"zones"];
    NSMutableDictionary* inputs = [settingsData valueForKey:@"inputs"];
    
    //set up data
    self.items = [NSMutableArray array];
    self.zonedata = [[NSMutableDictionary alloc] initWithCapacity:6];
    self.inputitems = [NSMutableArray array];
    
    NSArray* sortedKeys = [zones keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray* sortedInputKeys = [inputs keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSLog(@"zone count: %d", [zones count]);
    
    for (int i=0;i<[sortedKeys count];i++)
    {
        NSString* key = [sortedKeys objectAtIndex:i];
        NSString *z = [zones objectForKey:key];
        //NSLog(@"Adding zone %@", z);
        [items addObject:(z)];
    }
    
    for (int i=0;i<[sortedInputKeys count];i++) {
        NSString* inputd = [sortedInputKeys objectAtIndex:i];
        //NSString* inputtext = [inputs objectForKey:inputd];
        //NSLog(@"Input: %@", inputtext);
        [inputitems addObject:[inputs objectForKey:inputd]];
    }

    NSLog(@"Inputs: %d", [inputitems count]);
    NSLog(@"Zones: %d", [items count]);
    [carousel reloadData];
    [carousel2 reloadData];
    [self queryZone];
}

#pragma mark -
#pragma mark REST version support
/*
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    //NSLog(@"Received response");
    
    //[self.apiReturnXMLData setLength:0];
}
*/
/*
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    NSURLRequest *req = [connection originalRequest];
    NSURL *url = [req URL];
    
    NSDictionary *json1 = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSMutableDictionary *json = (NSMutableDictionary*) CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFPropertyListRef) [json1 objectForKey:@"settings"], kCFPropertyListMutableContainers));

    if ([[url absoluteString] isEqualToString:[NSString stringWithFormat:@"%@/settings", BaseAPIUrl]]) {
        [self processSettings:json];
    } else {
    
    }
    //NSLog(@"Data returned: %@", [json objectForKey:@"status"]);
}
*/
/*
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"URL Connection Failed!");
    currentConnection = nil;
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
 currentConnection = nil;
}
*/

/*- (void)receivedSettingsData:(NSURLConnection *)restConnection didReceiveData:(NSData *)data {
    NSDictionary *json1 = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSMutableDictionary *json = (NSMutableDictionary*) CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFPropertyListRef) json1, kCFPropertyListMutableContainers));
    
    [self processSettings:json];
    zoneAddress = 1;
}*/
/*
- (void)sendSyncRestCallGet:(NSString *)apiUrl {
    NSURL *restUrl = [NSURL URLWithString:apiUrl];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:restUrl];
    [req setHTTPMethod:@"GET"];

    NSURLResponse *response;
    NSError *error;
    //send it synchronous
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];

    NSLog(@"Got sync response data...");
    NSDictionary *json1 = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
    NSMutableDictionary *json = (NSMutableDictionary*) CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFPropertyListRef) [json1 objectForKey:@"settings"], kCFPropertyListMutableContainers));
    
    [self processSettings:json];
    zoneAddress = 1;
}*/
/*
- (void)sendRestCallGet:(NSString *)apiUrl {

    NSURL *restUrl = [NSURL URLWithString:apiUrl];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:restUrl];
    
    [req setHTTPMethod:@"GET"];
    if( currentConnection)
    {
        [currentConnection cancel];
        currentConnection = nil;
    }
    currentConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}*/

/*- (void)sendRestCallPost:(NSString *)apiUrl withData:(NSData *)postdata {
    
    NSURL *restUrl = [NSURL URLWithString:apiUrl];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:restUrl];
    
    [req setHTTPMethod:@"POST"];
    if (postdata != nil) {
        [req setHTTPBody:postdata];
    }
    
    if( currentConnection)
    {
        [currentConnection cancel];
        currentConnection = nil;
    }
    
    currentConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
 
}*/

#pragma mark -
#pragma mark keypad operations
- (void)changeInput:(NSString *)newInput {
    NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
    NSString *zaddr = [NSString stringWithFormat:@"%d", [carousel currentItemIndex] + 1];
    [eventData setObject:zaddr forKey:@"zone"];
    [eventData setObject:newInput forKey:@"cmd"];
    NSLog(@"Sending event over socket from change input");
    [self sendSocketEvent:@"sendcommand" withData:eventData];
}

- (IBAction)togglePower {

    NSString *command;
    NSString *zoneId = [NSString stringWithFormat:@"zone%d", carousel.currentItemIndex + 1];
    
    Zone* theZone = [self.zonedata objectForKey:zoneId];
    if (theZone.power == YES) {
        command = @"poweroff";
    } else {
        command = @"poweron";
    }
    
    NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
    NSString *zaddr = [NSString stringWithFormat:@"%d", (int) zoneAddress];
    [eventData setObject:zaddr forKey:@"zone"];
    [eventData setObject:command forKey:@"cmd"];
    NSLog(@"Sending event over socket from power");
    [self sendSocketEvent:@"sendcommand" withData:eventData];
}

- (IBAction)toggleMute {
     NSString *command;
    
    command = @"togglemute";
    
    NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
    NSString *zaddr = [NSString stringWithFormat:@"%d", (int) zoneAddress];
    [eventData setObject:zaddr forKey:@"zone"];
    [eventData setObject:command forKey:@"cmd"];
    NSLog(@"Sending event over socket from toggle mute");
    [self sendSocketEvent:@"sendcommand" withData:eventData];
}

- (void)queryZone {
    NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
    NSString *zaddr = [NSString stringWithFormat:@"%d", (int) [carousel currentItemIndex] + 1];
    [eventData setObject:zaddr forKey:@"zone"];
    [eventData setObject:@"queryzone" forKey:@"cmd"];
    NSLog(@"Sending event over socket from query");
    [self sendSocketEvent:@"sendcommand" withData:eventData];
}

- (IBAction)volumeUp {
    NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
    NSString *zaddr = [NSString stringWithFormat:@"%d", (int) zoneAddress];
    [eventData setObject:zaddr forKey:@"zone"];
    [eventData setObject:@"volumeup" forKey:@"cmd"];
    NSLog(@"Sending event over socket from volumeup");
    [self sendSocketEvent:@"sendcommand" withData:eventData];
}

- (IBAction)volumeDown {
    NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
    NSString *zaddr = [NSString stringWithFormat:@"%d", (int) zoneAddress];
    [eventData setObject:zaddr forKey:@"zone"];
    [eventData setObject:@"volumedown" forKey:@"cmd"];
    NSLog(@"Sending event over socket from volumeDown");
    [self sendSocketEvent:@"sendcommand" withData:eventData];

}

- (IBAction)switchCarouselType
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Carousel Type"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Linear", @"Rotary", @"Inverted Rotary", @"Cylinder", @"Inverted Cylinder", @"Wheel", @"Inverted Wheel", @"CoverFlow", @"CoverFlow2", @"Time Machine", @"Inverted Time Machine", @"Custom", nil];
    [sheet showInView:self.view];
}

- (IBAction)toggleOrientation
{
    //carousel orientation can be animated
    [UIView beginAnimations:nil context:nil];
    carousel.vertical = !carousel.vertical;
    carousel2.vertical = !carousel2.vertical;
    [UIView commitAnimations];
    
}

- (IBAction)toggleWrap
{
    NSInteger alpha = carousel.alpha;
    NSLog(@"Carousel alpha: %d", alpha);
    NSLog(@"Carousel2 alpha: %.0f", carousel2.alpha);
    if ([carousel isHidden] == YES) {
        NSLog(@"Hiding inputs");
        [wrapBarItem setTitle:@"Sources"];
        [carousel setHidden:NO];
        [carousel setAlpha:1];
        [carousel2 setHidden:YES];
        [carousel2 setAlpha:0];
    } else {
        NSLog(@"Hiding zones");
        [wrapBarItem setTitle:@"Zones"];
        [carousel setAlpha:0];
        [carousel setHidden:YES];
        [carousel2 setAlpha:1];
        [carousel2 setHidden:NO];
    }
}


#pragma mark -
#pragma mark UIActionSheet methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex >= 0)
    {
        //map button index to carousel type
        iCarouselType type = buttonIndex;
        
        //carousel can smoothly animate between types
        [UIView beginAnimations:nil context:nil];
        carousel2.type = type;
        carousel.type = type;
        [UIView commitAnimations];
        
        //update title
        //navItem.title = [actionSheet buttonTitleAtIndex:buttonIndex];
    }
}

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)acarousel
{
    if (acarousel.tag == 5) {
        return [items count];
    } else {
        return [inputitems count];
    }
}

- (UIView *)carousel:(iCarousel *)acarousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    UILabel *label = nil;
    UILabel *volLabel = nil;
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200.0f, 200.0f)];
        if (acarousel.tag == 5) {
            ((UIImageView *)view).image = [UIImage imageNamed:@"keypaddisplay2"];
        } else {
            ((UIImageView *)view).image = [UIImage imageNamed:@"sourcedisplay"];
        }
        view.contentMode = UIViewContentModeCenter;
        label = [[UILabel alloc] initWithFrame:view.bounds];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.center = CGPointMake(99, 70);
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [label.font fontWithSize:20];
        label.tag = 1;
        [view addSubview:label];
        //NSLog(@"Add label to %@", whatCarousel);
        
        if (acarousel.tag == 5) {
            volLabel = [[UILabel alloc] initWithFrame:view.bounds];
            volLabel.backgroundColor = [UIColor clearColor];
            volLabel.textColor = [UIColor whiteColor];
            volLabel.center = CGPointMake(99, 115);
            volLabel.textAlignment = NSTextAlignmentCenter;
            volLabel.font = [label.font fontWithSize:40];
            volLabel.tag = 2;
            volLabel.lineBreakMode = NSLineBreakByWordWrapping;
            volLabel.numberOfLines = 2;
            [view addSubview:volLabel];
        }
    }
    else
    {
        //get a reference to the label in the recycled view
        label = (UILabel *)[view viewWithTag:1];
        if (acarousel.tag == 5) {
            volLabel = (UILabel *)[view viewWithTag:2];
        }
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    if (acarousel.tag == 5) {
        label.text = [items objectAtIndex:index];
        NSString *ind = [NSString stringWithFormat:@"%d", index + 1];
        if ([[self.zonedata allValues] count] > 0) {
            Zone *zdata = [self.zonedata objectForKey:[NSString stringWithFormat:@"zone%@", ind]];
            volLabel.text = [NSString stringWithFormat:@"%d", [zdata.volume intValue]];
        } else {
            volLabel.text = @"0";
        }
    } else {
        label.text = [inputitems objectAtIndex:index];
    }
    return view;
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
    //note: placeholder views are only displayed on some carousels if wrapping is disabled
    return 2;
}

- (UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    UILabel *label = nil;
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        //don't do anything specific to the index within
        //this `if (view == nil) {...}` statement because the view will be
        //recycled and used with other index values later
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 150.0f, 150.0f)];
        ((UIImageView *)view).image = [UIImage imageNamed:@"page.png"];
        view.contentMode = UIViewContentModeCenter;
        
        label = [[UILabel alloc] initWithFrame:view.bounds];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [label.font fontWithSize:50.0f];
        label.tag = 1;
        [view addSubview:label];
    }
    else
    {
        //get a reference to the label in the recycled view
        label = (UILabel *)[view viewWithTag:1];
    }
    
    //set item label
    //remember to always set any properties of your carousel item
    //views outside of the `if (view == nil) {...}` check otherwise
    //you'll get weird issues with carousel item content appearing
    //in the wrong place in the carousel
    label.text = (index == 0)? @"[": @"]";
    
    return view;
}

- (CATransform3D)carousel:(iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    if (_carousel.tag == 5) {
        return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * carousel.itemWidth);
    } else {
        return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * carousel2.itemWidth);
    }
}

- (CGFloat)carousel:(iCarousel *)_carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            //normally you would hard-code this to YES or NO
            return YES;
        }
        case iCarouselOptionSpacing:
        {
            //add a bit of spacing between the item views
            return value * 1.05f;
        }
        case iCarouselOptionFadeMax:
        {
            if (carousel.type == iCarouselTypeCustom)
            {
                //set opacity based on distance from camera
                return 0.0f;
            }
            return value;
        }
        default:
        {
            return value;
        }
    }
}

#pragma mark -
#pragma mark iCarousel taps
- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    NSLog(@"Item changed.");
     AudioServicesPlaySystemSound(_clickSound);
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)acarousel {
    NSLog(@"Did End Scrolling Animation");
    
    if (acarousel.tag == 5) {
        NSString *ind = [NSString stringWithFormat:@"zone%d", [acarousel currentItemIndex] + 1];
        Zone *zone = [self.zonedata objectForKey:ind];
    
        if (zone.power == YES) {
            [powerButton setImage:[UIImage imageNamed:@"powerOn.png"] forState:UIControlStateNormal];
        } else {
            [powerButton setImage:[UIImage imageNamed:@"powerOff.png"] forState:UIControlStateNormal];
        }
    
        if (zone.mute == YES) {
            [muteButton setImage:[UIImage imageNamed:@"muteOn.png"] forState:UIControlStateNormal];
        } else {
            [muteButton setImage:[UIImage imageNamed:@"muteOff.png"] forState:UIControlStateNormal];
        }
        
        currentStepValue = [zone.volume floatValue];
        
        UIView *cview = [acarousel itemViewAtIndex:[acarousel currentItemIndex]];
        vlabel = (UILabel *)[cview viewWithTag:2];
        [carousel2 setCurrentItemIndex:[zone.mediaInput integerValue] - 1];
    } else {
        //NSLog(@"New input for zone %d is %@", (int) zoneAddress, [inputitems objectAtIndex:[acarousel currentItemIndex]]);
        //[self changeInput:[acarousel currentItemIndex] + 1];
        //Zone *zone = [zonedata objectAtIndex:[carousel currentItemIndex]];
        //zone.mediaInput = [NSNumber numberWithInt:[acarousel currentItemIndex] + 1];
    }

    NSLog(@"Done scrolling...%ld", (long)[acarousel currentItemIndex]);
    zoneAddress = [acarousel currentItemIndex] + 1;
}

- (void)carousel:(iCarousel *)acarousel didSelectItemAtIndex:(NSInteger)index
{
    if (acarousel.tag == 5) {
        zoneAddress = index + 1;

        NSNumber *item = (self.items)[index];
        NSLog(@"Tapped view number: %@", item);
        NSMutableDictionary *eventData = [NSMutableDictionary dictionary];
        [eventData setObject:[NSNumber numberWithInt:index] forKey:@"zone"];
        [self toggleWrap];
    } else {
        NSString *inputd = (self.inputitems)[index];
        NSLog(@"Tapped input : %@", inputd);
        NSString *newInput = [NSString stringWithFormat:@"setinput%d", [acarousel currentItemIndex] + 1];
        NSLog(@"New INput %@", newInput);
        //AudioServicesPlaySystemSound(1003);
        AudioServicesPlaySystemSound(_selectSound);
        [self toggleWrap];
        [self changeInput:newInput];
    }
}

@end
