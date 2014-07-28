//
//  MMRotationManager.m
//  Loose Leaf
//
//  Created by Adam Wulf on 6/23/12.
//  Copyright (c) 2012 Milestone Made, LLC. All rights reserved.
//

#import "MMRotationManager.h"

@implementation MMRotationManager{
    CGFloat goalTrust;
    CGFloat currentTrust;
    UIDeviceOrientation lastBestOrientation;
    UIDeviceOrientation currentOrientation;
    
    NSDate* startupTime;
}

@synthesize delegate;
@synthesize currentRotationReading;
@synthesize currentRawRotationReading;

static MMRotationManager* _instance = nil;

-(id) init{
    if(_instance) return _instance;
    if((self = [super init])){
        _instance = self;
        // we need to ignore rotation
        startupTime = [NSDate date];
        currentTrust = 0.0;
        goalTrust = 0.0;
        lastBestOrientation = UIDeviceOrientationPortrait;
        [[NSNotificationCenter defaultCenter] addObserver:_instance selector:@selector(didRotate:)   name:UIDeviceOrientationDidChangeNotification object:nil];
        isFirstReading = YES;
        @synchronized(self){
            currentRotationReading = [MMVector vectorWithAngle:-M_PI / 2];
        }
        // add opqueue to sample the accelerometer
        opQueue = [[NSOperationQueue alloc] init];
        [opQueue setMaxConcurrentOperationCount:1];
        motionManager = [[CMMotionManager alloc] init];
        [motionManager setAccelerometerUpdateInterval:0.03];
        [motionManager startAccelerometerUpdatesToQueue:opQueue withHandler:^(CMAccelerometerData* data, NSError* error){
            //
            // if z == -1, x == 0, y == 0
            //   then it's flat up on a table
            // if z == 1, x == 0, y == 0
            //   then it's flat down on a table
            // if z == 0, x == 0, y == -1
            //   then it's up in portrait
            // if z == 0, x == 0, y == 1
            //   then it's upside down in portrait
            // if z == 0, x == 1, y == 0
            //   then it's landscape button left
            // if z == 0, x == -1, y == 0
            //   then it's landscape button right
            accelerationX = data.acceleration.x * kFilteringFactor + accelerationX * (1.0 - kFilteringFactor);
            accelerationY = data.acceleration.y * kFilteringFactor + accelerationY * (1.0 - kFilteringFactor);
            accelerationZ = data.acceleration.z * kFilteringFactor + accelerationZ * (1.0 - kFilteringFactor);
//            CGFloat absZ = accelerationZ < 0 ? -accelerationZ : accelerationZ;
//            debug_NSLog(@"x: %f   y: %f   z: %f   diff: %f", accelerationX, accelerationY, absZ);
            currentTrust += (goalTrust - currentTrust) / 20.0;

            MMVector* actualRawReading = [MMVector vectorWithAngle:atan2(accelerationY, accelerationX)];
            MMVector* orientationRotationReading = [self idealRotationReadingForCurrentOrientation];
            
            @synchronized(self){
                CGFloat diffOrient = [currentRotationReading angleBetween:orientationRotationReading];
                CGFloat diffActual = [currentRotationReading angleBetween:actualRawReading];
                
                CGFloat diffCombined = currentTrust * diffActual + (1-currentTrust)*diffOrient;
                //            NSLog(@"currVec: %@  actualVec: %@  orientVec: %@  trust: %f", currentRotationReading, actualRawReading, orientationRotationReading, currentTrust);
                // now tone it down so that we don't jump around too much, make
                // sure it only changes by max of 5 degrees
                if(ABS(diffCombined) > .05 || isFirstReading){
                    diffCombined = diffCombined > .2 ? .2 : diffCombined < -.2 ? -.2 : diffCombined;
                    currentRotationReading = [currentRotationReading rotateBy:diffCombined];
                    isFirstReading = NO;
                    [self.delegate didUpdateAccelerometerWithReading:currentRotationReading];
                }
                currentRawRotationReading = actualRawReading;
                [self.delegate didUpdateAccelerometerWithRawReading:currentRawRotationReading andX:accelerationX andY:accelerationY andZ:accelerationZ];
            }
            
            if(currentTrust > .75){
                if(currentOrientation == UIDeviceOrientationPortrait ||
                   currentOrientation == UIDeviceOrientationPortraitUpsideDown ||
                   currentOrientation == UIDeviceOrientationLandscapeLeft ||
                   currentOrientation == UIDeviceOrientationLandscapeRight){
                    if(currentOrientation != UIDeviceOrientationFaceUp &&
                       currentOrientation != UIDeviceOrientationFaceDown &&
                       currentOrientation != UIDeviceOrientationUnknown){
                        lastBestOrientation = currentOrientation;
                    }
                }
            }
        }];
    }
    return _instance;
}

-(MMVector*) currentRawRotationReading{
    @synchronized(self){
        return currentRawRotationReading;
    }
}

-(MMVector*) currentRotationReading{
    @synchronized(self){
        return currentRotationReading;
    }
}

+(MMRotationManager*) sharedInstace{
    if(!_instance){
        _instance = [[MMRotationManager alloc]init];
    }
    return _instance;
}

-(UIDeviceOrientation) currentDeviceOrientation{
    return [[UIDevice currentDevice] orientation];
}

-(UIInterfaceOrientation) currentStatusbarOrientation{
    return [[UIApplication sharedApplication] statusBarOrientation];
}

static BOOL ignoredFirstRotateNotification = NO;

- (void)didRotate:(NSNotification *)notification {
    if(!ignoredFirstRotateNotification){
        ignoredFirstRotateNotification = YES;
        return;
    }
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(orientation == UIDeviceOrientationPortrait ||
       orientation == UIDeviceOrientationPortraitUpsideDown ||
       orientation == UIDeviceOrientationLandscapeLeft ||
       orientation == UIDeviceOrientationLandscapeRight){
        goalTrust = 1.0;
    }else{
        goalTrust = 0.0;
    }
    NSLog(@"resetting goal trust to: %f %d", goalTrust, orientation);
    currentOrientation = orientation;
    
    if(orientation == UIDeviceOrientationUnknown ||
       orientation == UIDeviceOrientationFaceDown ||
       orientation == UIDeviceOrientationFaceUp){
        orientation = UIDeviceOrientationPortrait;
    }

    // cast to save a warning
    UIInterfaceOrientation devOrient = (UIInterfaceOrientation) orientation;
    UIInterfaceOrientation currOrient = [self currentStatusbarOrientation];
    [delegate willRotateInterfaceFrom:currOrient to:devOrient];
//    [[UIApplication sharedApplication] setStatusBarOrientation:devOrient animated:NO];
    [delegate didRotateInterfaceFrom:currOrient to:devOrient];
}

-(void) applicationDidBackground{
    ignoredFirstRotateNotification = NO;
}

-(MMVector*) idealRotationReadingForCurrentOrientation{
    if(lastBestOrientation == UIDeviceOrientationPortrait){
        return [MMVector vectorWithAngle:-M_PI / 2];
    }else if(lastBestOrientation == UIDeviceOrientationLandscapeLeft){
        return [MMVector vectorWithAngle:M_PI];
    }else if(lastBestOrientation == UIDeviceOrientationLandscapeRight){
        return [MMVector vectorWithAngle:0];
    }else{
        return [MMVector vectorWithAngle:M_PI / 2];
    }
}


-(void) setDelegate:(NSObject<MMRotationManagerDelegate> *)_delegate{
    delegate = _delegate;
    [delegate didUpdateAccelerometerWithReading:[self currentRotationReading]];
}

-(MMVector*) upVector{
    MMVector* up = [[[MMVector vectorWithAngle:-([currentRotationReading angle])] flip] normal];
    NSLog(@"up vector is: %@", up);
    return up;
}

@end
