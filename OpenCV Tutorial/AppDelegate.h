//
//  AppDelegate.h
//  OpenCV Tutorial
//
//  Created by BloodAxe on 6/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SampleBase.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
@public
  std::vector<SampleBase*> allSamples;
}
@property (strong, nonatomic) UIWindow *window;

@end
