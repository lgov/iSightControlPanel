/*
 * iSightControlPanel.h
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


#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

#import "ExposureMode.h"

#define kVendorApple 0x05ac
#define kProductiSight 0x8507

@interface iSightControlPanel : NSObject {
	IBOutlet NSTextField* lbl;
	IBOutlet QTCaptureView *captureView;

	IBOutlet NSSlider* brightnessSlider;
	IBOutlet NSSlider* contrastSlider;
	IBOutlet NSSlider* saturationSlider;
	IBOutlet NSSlider* sharpnessSlider;
	IBOutlet NSSlider* gammaSlider;
	IBOutlet NSSlider* whiteBalanceTempSlider;
	IBOutlet NSButton* whiteBalanceTempAutoCheckbox;
	IBOutlet NSSlider* exposureSlider;
	IBOutlet NSPopUpButton* exposureModePopup;
	NSMutableArray *exposureModes;
	ExposureMode* selectedExposureMode;

	QTCaptureDeviceInput* captureDeviceInput;
}

- (void) initExposureModes;
- (IBAction)setBrightness:(id)sender;
- (IBAction)setContrast:(id)sender;
- (IBAction)setSaturation:(id)sender;
- (IBAction)setSharpness:(id)sender;
- (IBAction)setExposure:(id)sender;
- (IBAction)setExposureMode:(id)sender;
- (IBAction)setGamma:(id)sender;
- (IBAction)setWhiteBalanceTemp:(id)sender;
- (IBAction)setWhiteBalanceTempAuto:(id)sender;

@end
