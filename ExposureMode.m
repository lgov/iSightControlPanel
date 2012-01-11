//
//  ExposureMode.m
//  isight
//
//  Created by Lieven Govaerts on 11/01/12.
//  Copyright 2012 Lieven Govaerts. All rights reserved.
//

#import "ExposureMode.h"


@implementation ExposureMode

- (ExposureMode*) set:(CameraAutoExposureMode_t)theMode modeName:(NSString*)theName
{
	self = [super init];
	if(self)
	{
		[self setMode:theMode];
		[self setModeName:theName];
		return self;
	}
	return NULL;
}

- (CameraAutoExposureMode_t)mode
{
	return mode;
}
- (void)setMode:(CameraAutoExposureMode_t)theMode
{
	mode = theMode;
}

- (NSString*)modeName
{
	return modeName;
}

- (void)setModeName:(NSString*)theName
{
	modeName = theName;
}


@end
