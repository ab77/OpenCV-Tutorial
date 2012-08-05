//
//  VideoViewController.m
//  OpenCV Tutorial
//
//  Created by BloodAxe on 6/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VideoViewController.h"
#import "UIImage2OpenCV.h"
#import "OptionsTableView.h"

#define kTransitionDuration	0.75

@interface VideoViewController ()
{
#if TARGET_IPHONE_SIMULATOR
    DummyVideoSource * videoSource;
#else
    VideoSource * videoSource;
#endif  
    
    cv::Mat outputFrame;
    
    // points array to store user input
    std::vector<cv::Point2f> customPoints;
    
    UIImage *currentImage;
}

@end

@implementation VideoViewController
@synthesize actionSheetButton;
@synthesize options;
@synthesize imageView;
@synthesize toggleCameraButton;
@synthesize containerView;
@synthesize optionsPopover;
@synthesize optionsView;
@synthesize optionsViewController;
@synthesize actionSheet;
@synthesize captureReferenceFrameButton;
@synthesize clearReferenceFrameButton;
@synthesize referenceFrameView;
@synthesize referenceFramePopover;
@synthesize referenceFrameViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Init the default view (video view layer)
    self.imageView = [[GLESImageView alloc] initWithFrame:self.containerView.bounds];
    [self.imageView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self.containerView addSubview:self.imageView];
    
    // Init video source:
#if TARGET_IPHONE_SIMULATOR
    videoSource = [[DummyVideoSource alloc] initWithFrameSize:CGSizeMake(640, 480)];
#else  
    videoSource = [[VideoSource alloc] init];
#endif
    
    videoSource.delegate = self;
    
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"Actions" 
                                                   delegate:self 
                                          cancelButtonTitle:@"Cancel" 
                                     destructiveButtonTitle:nil 
                                          otherButtonTitles:kSaveImageActionTitle, kComposeTweetWithImage, nil];
    
    // check if the sample requires the reference frame and configure buttons accordingly
    if ( !self.currentSample->isReferenceFrameRequired() )
    {
        // hide buttons
        captureReferenceFrameButton.enabled = NO;
        clearReferenceFrameButton.enabled = NO;
    }  
}

// called when user touches the screen
- (void) touchesBegan:(NSSet *)touches 
            withEvent:(UIEvent *)event {
    
    // clear points array
    customPoints.clear();
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView: [UIApplication sharedApplication].keyWindow];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    NSLog(@"Screen size: %f x %f", screenBounds.size.height, screenBounds.size.width );
    NSLog(@"Tap began at: X:%f Y:%f", point.x, point.y);
    
    // scale the tapped coordinates to output frame size
    float f_cols = static_cast<float>(outputFrame.cols);
    float f_rows = static_cast<float>(outputFrame.rows);
    float tmp_x = point.x / screenBounds.size.width * f_cols;
    float tmp_y = point.y / screenBounds.size.height * f_rows;
    
    // push scaled coordinates to the points array
    customPoints.push_back(cvPoint(tmp_x, tmp_y));
}

// called repeatedly when the user moves finger on the screen
- (void) touchesMoved:(NSSet *)touches 
            withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView: [UIApplication sharedApplication].keyWindow];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    NSLog(@"Tap continued at: X:%f Y:%f", point.x, point.y);
    
    // scale the tapped coordinates to output frame size
    float f_cols = static_cast<float>(outputFrame.cols);
    float f_rows = static_cast<float>(outputFrame.rows);
    float tmp_x = point.x / screenBounds.size.width * f_cols;
    float tmp_y = point.y / screenBounds.size.height * f_rows;
    
    // push scaled coordinates to the points array
    customPoints.push_back(cvPoint(tmp_x, tmp_y));
}

// called when the finger leaves the surface of the screen
- (void) touchesEnded:(NSSet *)touches 
            withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView: [UIApplication sharedApplication].keyWindow];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    NSLog(@"Tap ended at: X:%f Y:%f", point.x, point.y);
    
    // scale the tapped coordinates to output frame size
    float f_cols = static_cast<float>(outputFrame.cols);
    float f_rows = static_cast<float>(outputFrame.rows);
    float tmp_x = point.x / screenBounds.size.width * f_cols;
    float tmp_y = point.y / screenBounds.size.height * f_rows;
    
    // push scaled coordinates to the points array
    customPoints.push_back(cvPoint(tmp_x, tmp_y));
    
    SampleBase * sample = self.currentSample;
    if (!sample)
        return;
    
    sample->addCustomPoints(customPoints);
    
    // clear points array
    customPoints.clear();
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [videoSource startRunning];
    
    toggleCameraButton.enabled = [videoSource hasMultipleCameras];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [videoSource stopRunning];
}

- (void) configureView
{
    [super configureView];
    
    self.optionsView = [[OptionsTableView alloc] initWithFrame:containerView.frame 
                                                         style:UITableViewStyleGrouped 
                                                        sample:self.currentSample 
                                         notificationsDelegate:nil];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        UIViewController * viewController = [[UIViewController alloc] init];
        viewController.view = self.optionsView;
        viewController.title = @"Algorithm options";
        
        self.optionsViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
        
        self.optionsPopover = [[UIPopoverController alloc] initWithContentViewController:self.optionsViewController];
    }
   
    self.referenceFrameView = [[UIImageView alloc] initWithFrame:self.containerView.bounds];
    [self.referenceFrameView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self.containerView addSubview:self.referenceFrameView];
    
    // configure reference frame view
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        UIViewController * viewController = [[UIViewController alloc] init];
        viewController.view = self.referenceFrameView;
        viewController.title = @"Reference frame";
        
        self.referenceFrameViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
        
        self.referenceFramePopover = [[UIPopoverController alloc] initWithContentViewController:self.referenceFrameViewController];
    }
}

- (IBAction)toggleCameraPressed:(id)sender
{
    [videoSource toggleCamera];
}

- (IBAction)showActionSheet:(id)sender
{
    if ([self.actionSheet isVisible])
        [self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
    else
        [self.actionSheet showFromBarButtonItem:self.actionSheetButton animated:YES];
}

- (void)viewDidUnload
{
    [self setToggleCameraButton:nil];
    [self setContainerView:nil];
    [self setOptions:nil];
    [self setActionSheetButton:nil];
    [self setCaptureReferenceFrameButton: nil];
    [self setClearReferenceFrameButton: nil];
    [super viewDidUnload];
}

- (IBAction)showOptions:(id)sender 
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if ([self.optionsView superview])
        {
            [UIView transitionFromView:self.optionsView
                                toView:imageView 
                              duration:kTransitionDuration 
                               options:UIViewAnimationOptionTransitionFlipFromLeft 
                            completion:^(BOOL)
             {
                 // unhide buttons
                 captureReferenceFrameButton.enabled = YES;
                 clearReferenceFrameButton.enabled = YES;
             }];
        }
        else
        {
            [self.optionsView setFrame:self.containerView.frame];
            [self.optionsView setNeedsLayout];
            
            [UIView transitionFromView:self.imageView 
                                toView:optionsView 
                              duration:kTransitionDuration 
                               options:UIViewAnimationOptionTransitionFlipFromLeft 
                            completion:^(BOOL)
             {
                 // hide buttons
                 captureReferenceFrameButton.enabled = NO;
                 clearReferenceFrameButton.enabled = NO;
                 [self.optionsView reloadData];
             }];
        }
    }
    else
    {
        if ([self.optionsPopover isPopoverVisible])
            [self.optionsPopover dismissPopoverAnimated:YES];
        else
            [self.optionsPopover presentPopoverFromBarButtonItem:options permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma mark - VideoSourceDelegate

- (void) frameCaptured:(cv::Mat) frame
{
    SampleBase * sample = self.currentSample;
    if (!sample)
        return;
    
    bool isMainQueue = dispatch_get_current_queue() == dispatch_get_main_queue();
    
    if (isMainQueue)
    {
        sample->processFrame(frame, outputFrame);
        [imageView drawFrame:outputFrame];
    }
    else
    {
        dispatch_sync( dispatch_get_main_queue(), 
                      ^{ 
                          sample->processFrame(frame, outputFrame);
                          [imageView drawFrame:outputFrame];
                      }
                      );
    }
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)senderSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString * title = [senderSheet buttonTitleAtIndex:buttonIndex];
    
    if (title == kSaveImageActionTitle)
    {
        UIImage * image = [UIImage imageWithMat:outputFrame.clone() andDeviceOrientation:[[UIDevice currentDevice] orientation]];
        [self saveImage:image withCompletionHandler: ^{ [videoSource startRunning]; }];
    }
    else if (title == kComposeTweetWithImage)
    {
        UIImage * image = [UIImage imageWithMat:outputFrame.clone() andDeviceOrientation:[[UIDevice currentDevice] orientation]];
        [self tweetImage:image withCompletionHandler:^{ [videoSource startRunning]; }];
    }
    else
    {
        [videoSource startRunning];
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet;  // before animation and showing view
{
    [videoSource stopRunning];
}

#pragma mark - Capture reference frame

- (IBAction) captureReferenceFrame:(id) sender
{
    SampleBase * sample = self.currentSample;
    if (!sample)
        return;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if ([self.referenceFrameView superview])
        {
            [UIView transitionFromView:self.referenceFrameView
                                toView:imageView 
                              duration:kTransitionDuration 
                               options:UIViewAnimationOptionTransitionFlipFromLeft 
                            completion:^(BOOL)
             {
                 // unhide buttons
                 options.enabled = YES;
                 clearReferenceFrameButton.enabled = YES;
                 
                 // set the reference frame
                 sample->setReferenceFrame([currentImage toMat]);
             }];
        }
        else
        {
            [self.referenceFrameView setFrame:self.containerView.frame];
            [self.referenceFrameView setNeedsLayout];
            
            [UIView transitionFromView:self.imageView 
                                toView:referenceFrameView 
                              duration:kTransitionDuration 
                               options:UIViewAnimationOptionTransitionFlipFromLeft 
                            completion:^(BOOL)
             {
                 // grab the reference frame and display it
                 if (self.currentSample)
                 {
                     currentImage = [UIImage imageWithMat:outputFrame.clone() andDeviceOrientation:[[UIDevice currentDevice] orientation]];
                     
                     // hide buttons
                     options.enabled = NO;
                     clearReferenceFrameButton.enabled = NO;
                     
                     self.referenceFrameView.image = currentImage;
                 }
             }];
        }
    }
    else
    {
        if ([self.referenceFramePopover isPopoverVisible])
            [self.referenceFramePopover dismissPopoverAnimated:YES];
        else
            [self.referenceFramePopover presentPopoverFromBarButtonItem:captureReferenceFrameButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma mark - Clear reference frame

- (IBAction) clearReferenceFrame:(id) sender
{    
    SampleBase * sample = self.currentSample;
    if (!sample)
        return;
    
    customPoints.clear();
    sample->resetReferenceFrame();
}

@end