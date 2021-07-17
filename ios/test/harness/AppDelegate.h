//
//  AppDelegate.h
//  Apperl
//
//  Created by jose on 30/11/16.
//  Copyright © 2016 jose. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CamelBones/CamelBones.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (retain) NSMutableDictionary* perlDict;
@property (retain) UINavigationController *rootViewController;

@end

