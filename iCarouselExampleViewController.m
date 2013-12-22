//
//  iCarouselExampleViewController.m
//  iCarouselExample
//
//  Created by Nick Lockwood on 03/04/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "iCarouselExampleViewController.h"


@interface iCarouselExampleViewController () <UIActionSheetDelegate>

@property (nonatomic, assign) BOOL wrap;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) NSInteger *zoneAddress;
@property (nonatomic, strong) NSMutableArray *zonedata;
@property (nonatomic, strong) UILabel *vlabel;
@property (nonatomic, strong) NSMutableArray *inputitems;

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
@synthesize power;
@synthesize input;
@synthesize mute;
@synthesize volume;
@synthesize zonedata;
@synthesize vlabel;

- (void)setUp
{
    // On line setup
    [self readSettingsFile:@"settings.json" usingAPI:YES];
    // Local setup
    //[self readSettingsFile:@"settings.json" usingAPI:NO];
    zoneAddress = 1;
}

- (void) readSettingsFile:(NSString *)name usingAPI:(BOOL)useAPI {
    if (useAPI == YES) {
        NSString *restendpoint = [NSString stringWithFormat:@"%@/settings", BaseAPIUrl];
        [self sendSyncRestCallGet:restendpoint];
    } else {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSMutableDictionary *json1 = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSMutableDictionary* json = (NSMutableDictionary*) CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFPropertyListRef) [json1 objectForKey:@"settings"], kCFPropertyListMutableContainers));
        [self processSettings:json];
    }
}

- (NSMutableDictionary *) readZoneDataFile:(NSString *)file withIndex:(int)ind usingAPI:(BOOL)useAPI {
    if (useAPI == YES) {
    
    } else {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:file ofType:@"zf"];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSMutableDictionary *json1 = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSMutableDictionary* json = (NSMutableDictionary*) CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFPropertyListRef) json1, kCFPropertyListMutableContainers));

        return json;
    }
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
    navItem.title = @"Linear";
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

- (void)processSettings:(NSMutableDictionary *)settingsData {
    NSMutableDictionary* zones = [settingsData valueForKey:@"zones"];
    NSMutableDictionary* inputs = [settingsData valueForKey:@"inputs"];
    
    //set up data
    self.items = [NSMutableArray array];
    self.zonedata = [NSMutableArray array];
    self.inputitems = [NSMutableArray array];
    
    NSArray* sortedKeys = [zones keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray* sortedInputKeys = [inputs keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)];
    
    //NSLog(@"zone count: %d", [zones count]);
    
    for (int i=0;i<[sortedKeys count];i++)
    {
        NSString *zdFile = [NSString stringWithFormat:@"zonefile%d", i+1];
        NSMutableDictionary *zdata = [self readZoneDataFile:zdFile withIndex:i usingAPI:NO];
        [zonedata addObject:zdata];

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
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    //NSLog(@"Received response");
    
    //[self.apiReturnXMLData setLength:0];
}

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
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"URL Connection Failed!");
    currentConnection = nil;
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
 currentConnection = nil;
}

/*- (void)receivedSettingsData:(NSURLConnection *)restConnection didReceiveData:(NSData *)data {
    NSDictionary *json1 = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSMutableDictionary *json = (NSMutableDictionary*) CFBridgingRelease(CFPropertyListCreateDeepCopy(kCFAllocatorDefault, (CFPropertyListRef) json1, kCFPropertyListMutableContainers));
    
    [self processSettings:json];
    zoneAddress = 1;
}*/

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
    
}

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
}

- (void)sendRestCallPost:(NSString *)apiUrl withData:(NSData *)postdata {
    
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
 
}

- (void)changeInput:(NSInteger)newInput {
    NSString *restCallString = [NSString stringWithFormat:@"%@/zone/%d/changeinput", BaseAPIUrl, (int) zoneAddress];
    NSString *inputdata = [NSString stringWithFormat:@"&input=%d", newInput];
    
    NSData *pData = [inputdata dataUsingEncoding:NSASCIIStringEncoding];

    [self sendRestCallPost:restCallString withData:pData];
}

- (IBAction)togglePower {
    NSString *restCallString;
    if (power.on) {
        restCallString = [NSString stringWithFormat:@"%@/zone/%d/powerOn", BaseAPIUrl, (int) zoneAddress];
    } else {
        restCallString = [NSString stringWithFormat:@"%@/zone/%d/powerOff", BaseAPIUrl, (int) zoneAddress];
    }
    
    
    UIAlertView *   alert;
 
    alert = [[UIAlertView alloc] initWithTitle:@"Current Zone" message:restCallString delegate:nil cancelButtonTitle:@"Go Away" otherButtonTitles:nil, nil];
    
        [alert show];
    
    [self sendRestCallPost:restCallString withData:nil];
    
}

- (IBAction)toggleMute {
    NSLog(@"Change the power for zone: %d", (int) zoneAddress);
    NSString *restCallString;
    
    restCallString = [NSString stringWithFormat:@"%@/zone/%d/toggleMute", BaseAPIUrl, (int) zoneAddress];
    
    [self sendRestCallPost:restCallString withData:nil];
}

- (IBAction)changeVolume {
    NSLog(@"Change the volume for zone: %d to %.0f", (int) zoneAddress, [volume value]);
    NSString *restCallString = [NSString stringWithFormat:@"%@/zone/%d/volumeChange", BaseAPIUrl, (int) zoneAddress];
    NSString *vol = [NSString stringWithFormat:@"&volume=%.0f", [volume value]];
    
    NSData *pData = [vol dataUsingEncoding:NSASCIIStringEncoding];
    
    [self sendRestCallPost:restCallString withData:pData];
    self.vlabel.text = [NSString stringWithFormat:@"%.0f", [volume value]];
    //NSMutableDictionary *z = (NSMutableDictionary *)[self.zonedata objectAtIndex:[carousel currentItemIndex]];
    
    /*[z setValue:[NSNumber numberWithFloat:[volume value]] forKey:@"volume"];*/
    
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
        navItem.title = [actionSheet buttonTitleAtIndex:buttonIndex];
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
    NSString *whatCarousel 	= nil;
    
    if (acarousel.tag == 5) {
        whatCarousel = @"zones";
    } else {
        whatCarousel = @"inputs";
    }
    
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
        NSLog(@"Add label to %@", whatCarousel);
        
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
        NSMutableDictionary *zdata = [self.zonedata objectAtIndex:index];
        volLabel.text = [NSString stringWithFormat:@"%@", [zdata objectForKey:@"volume"]];
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
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100.0f, 100.0f)];
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
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)acarousel {
    
    if (acarousel.tag == 5) {
        NSMutableDictionary *zone = [self.zonedata objectAtIndex:[acarousel currentItemIndex]];
    
        if ([[zone valueForKey:@"power"] isEqual: @"1"]) {
            power.on = true;
        } else {
            power.on = false;
        }
    
        if ([[zone valueForKey:@"mute"] isEqual:@"1"]) {
            mute.on = true;
        } else {
            mute.on = false;
        }
    
        float vol = [[zone valueForKey:@"volume"]floatValue];
    
        volume.value = vol;
        UIView *cview = [acarousel itemViewAtIndex:[acarousel currentItemIndex]];
        vlabel = (UILabel *)[cview viewWithTag:2];
    } else {
        NSLog(@"New input for zone %d is %@", (int) zoneAddress, [inputitems objectAtIndex:[acarousel currentItemIndex]]);
        [self changeInput:[acarousel currentItemIndex] + 1];
        NSMutableDictionary *zone = [zonedata objectAtIndex:[carousel currentItemIndex]];
        NSString *ival = [NSString stringWithFormat:@"%d", [acarousel currentItemIndex]];
        [zone setValue:ival forKey:@"mediaInput"];
    }
    //NSLog(@"Done scrolling...%ld", (long)[acarousel currentItemIndex]);
    zoneAddress = [acarousel currentItemIndex] + 1;
}

- (void)carousel:(iCarousel *)acarousel didSelectItemAtIndex:(NSInteger)index
{
    if (acarousel.tag == 5) {
        zoneAddress = index + 1;
    
        NSNumber *item = (self.items)[index];
        NSLog(@"Tapped view number: %@", item);
    } else {
        NSString *inputd = (self.inputitems)[index];
        NSLog(@"Tapped input : %@", inputd);
    }
}

@end
