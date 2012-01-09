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

	/* TODO: cleanup after initial tests. */
	long value;
	value = [cameraCtrl getValue:CamPar_Brightness selector:CamPar_Min];
	[brightnessSlider setMinValue:value];
	value = [cameraCtrl getValue:CamPar_Brightness selector:CamPar_Max];
	[brightnessSlider setMaxValue:value];
	value = [cameraCtrl getValue:CamPar_Brightness selector:CamPar_Current];
	[brightnessSlider setIntValue:value];
#if 0
	value = [cameraCtrl getValue:CamPar_Brightness selector:CamPar_Default];
	value = [cameraCtrl getValue:CamPar_Brightness selector:CamPar_Resolution];
#endif

	value = [cameraCtrl getValue:CamPar_Contrast selector:CamPar_Min];
	[contrastSlider setMinValue:value];
	value = [cameraCtrl getValue:CamPar_Contrast selector:CamPar_Max];
	[contrastSlider setMaxValue:value];
	value = [cameraCtrl getValue:CamPar_Contrast selector:CamPar_Current];
	[contrastSlider setIntValue:value];

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
