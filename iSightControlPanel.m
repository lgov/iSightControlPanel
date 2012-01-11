/*
 * iSightControlPanel.m
 *
 * This file is part of iSightControlPanel.
 *
 * iSightControlPanel is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * iSightControlPanel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with iSightControlPanel.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2012 Lieven Govaerts. All rights reserved.
 */

#import "iSightControlPanel.h"
#import "CameraController.h"

@implementation iSightControlPanel

QTCaptureSession           *captureSession;
CameraController *cameraCtrl;
BOOL cameraConfigured = FALSE;

// Setup methods
- (id)init
{
    self = [super init];
    [self initExposureModes];
    return self;
}

/**
 * initSlider: initiate the slider with the Minimum, Maximum and Current value
 *  for the selected control (brightness, contrast...).
 */
- (long) initSlider:(NSSlider *)slider control:(CameraControl_t)control
{
	long value;

	value = [cameraCtrl getValue:control selector:CamPar_Min];
	[slider setMinValue:value];
	value = [cameraCtrl getValue:control selector:CamPar_Max];
	[slider setMaxValue:value];
	value = [cameraCtrl getValue:control selector:CamPar_Current];
	[slider setIntValue:value];

	return value;
}

- (void) initExposureSlider:(NSSlider *)slider control:(CameraControl_t)control
{
	long value;

	value = [cameraCtrl getValue:CamPar_AutoExposureMode selector:CamPar_Current];
	if (value == CamPar_AEAuto)
		[slider setEnabled:FALSE];
	else
	{
		[slider setEnabled:TRUE];
		/* Seems that when switch from Shutter Priority to Manual the GET_CUR
		   value is changed, but the camera itself still uses the original value. */
		long exposure = [self initSlider:slider control:CamPar_ExposureAbs];
		[cameraCtrl setValue:exposure control:CamPar_ExposureAbs];
	}
}

/**
 * initExposureModePopup: select the current exposure mode.
 */
- (void) initExposureModePopup:(NSPopUpButton *)popup
{
	long value;

	value = [cameraCtrl getValue:CamPar_AutoExposureMode selector:CamPar_Current];
	for (ExposureMode *em in exposureModes)
	{
		if ([em mode] == value)
		{
			[self willChangeValueForKey: @"selectedExposureMode"];
			selectedExposureMode = em;
			[self didChangeValueForKey: @"selectedExposureMode"];
			break;
		}
	}
}

/**
 * initExposureModes: initiate the exposure popup with the list of available
 * modes.
 */
- (void) initExposureModes
{
	ExposureMode* mode;

	exposureModes =[[NSMutableArray alloc] init];
	mode = [[ExposureMode alloc] set:CamPar_AEAuto modeName:@"Auto mode"];
	[exposureModes addObject:mode];
	mode = [[ExposureMode alloc] set:CamPar_AEManual modeName:@"Manual mode"];
	[exposureModes addObject:mode];
	mode = [[ExposureMode alloc] set:CamPar_AEShutterPriority modeName:@"Shutter Priority Mode"];
	[exposureModes addObject:mode];

	/* Aperture priority mode not supported by iSight.
	   If support for other camera's is added: the supported modes can be queried
	   with the CamPar_Resolution selector. */
/*
	mode = [[ExposureMode alloc] set:CamPar_AEAperturePriority modeName:@"Aperture Priority Mode"];
	[exposureModes addObject:mode];
 */
}

- (void) awakeFromNib
{
	[lbl setStringValue:@""];

	captureSession = [[QTCaptureSession alloc] init];

	BOOL success = NO;
    NSError *error;

	// Find the device and create the device input. Then add it to the session.
	QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    if (device) {
        success = [device open:&error];
        if (!success) {
            // Handle error
			[lbl setStringValue:@"Error"];
        }
        captureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
        success = [captureSession addInput:captureDeviceInput error:&error];
        if (!success) {
            // Handle error
			[lbl setStringValue:@"Error"];
        }

		[captureView setCaptureSession:captureSession];
    }

	[captureSession startRunning];

	/* Set up USB camera device. */
	cameraCtrl = [CameraController alloc];
	cameraConfigured = [cameraCtrl openUSBCamera:kVendorApple :kProductiSight];
	if (cameraConfigured)
		[lbl setStringValue:@"Camera connected successfully."];
	else {
		[lbl setStringValue:@"Camera failure."];
	}

	/* Initialize ranged controls. */
	[self initSlider:brightnessSlider control:CamPar_Brightness];
	[self initSlider:contrastSlider control:CamPar_Contrast];
	[self initSlider:saturationSlider control:CamPar_Saturation];
	[self initExposureSlider:exposureSlider control:CamPar_ExposureAbs];

	[self initExposureModePopup:exposureModePopup];

	[lbl setStringValue:@"Initialized"];
}

- (IBAction)setBrightness:(id)sender
{
	int brightness = [brightnessSlider intValue];
	[cameraCtrl setValue:brightness
				 control:CamPar_Brightness];
}

- (IBAction)setContrast:(id)sender
{
	int contrast = [contrastSlider intValue];
	[cameraCtrl setValue:contrast
				 control:CamPar_Contrast];
}

- (IBAction)setSaturation:(id)sender
{
	int saturation = [saturationSlider intValue];
	[cameraCtrl setValue:saturation
				 control:CamPar_Saturation];
}

- (IBAction)setExposure:(id)sender
{
	int exposure = [exposureSlider intValue];
	[cameraCtrl setValue:exposure
				 control:CamPar_ExposureAbs];
}

- (IBAction)setExposureMode:(id)sender
{
	CameraAutoExposureMode_t mode = [selectedExposureMode mode];
	[cameraCtrl setValue:mode
				 control:CamPar_AutoExposureMode];
	[self initExposureSlider:exposureSlider control:CamPar_ExposureAbs];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [captureSession stopRunning];
    [[captureDeviceInput device] close];
}

- (void)dealloc
{
    [captureSession release];
    [captureDeviceInput release];

    [super dealloc];
}

@end
