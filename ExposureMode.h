//
//  ExposureMode.h
//  isight
//
//  Created by Lieven Govaerts on 11/01/12.
//  Copyright 2012 Lieven Govaerts. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CameraController.h"


@interface ExposureMode : NSObject {
	CameraAutoExposureMode_t mode;
    NSString* modeName;
}

- (ExposureMode*) set:(CameraAutoExposureMode_t)mode modeName:(NSString*)theName;

- (CameraAutoExposureMode_t)mode;
- (void)setMode:(CameraAutoExposureMode_t)theMode;

- (NSString*)modeName;
- (void)setModeName:(NSString*)name;

@end
