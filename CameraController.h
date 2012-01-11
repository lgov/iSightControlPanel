/*
 * CameraController.h
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


/** iSight supported controls:

	Brightness
	Contrast
	Saturation
	Sharpness
	Gamma
	White Balance Temperature
	White Balance Temperature, Auto
	Backlight Compensation
	Power Line Frequency
	Auto Exposure Mode
	Exposure Time (Absolute)
	Hue	(?)

/** Types used to request and update control values. **/
typedef enum {    /* these values have a meaning, see CameraController.m */
	CamPar_Brightness = 0,
	CamPar_Contrast = 1,
	CamPar_Saturation = 2,
	CamPar_Sharpness = 3,
	CamPar_AutoExposureMode = 4,
	CamPar_ExposureAbs = 5,
} CameraControl_t;

typedef enum {
	CamPar_Min = 256,
	CamPar_Max,
	CamPar_Current,
	CamPar_Default,
	CamPar_Resolution
} CameraSelector_t;

typedef enum {
	CamPar_AEManual = 0x01,
	CamPar_AEAuto = 0x02,
	CamPar_AEShutterPriority = 0x04,
	CamPar_AEAperturePriority = 0x08, /* Not supported by iSight */
} CameraAutoExposureMode_t;
@interface CameraController : NSObject {

}
- (BOOL)openUSBCamera:(SInt32)vendorID :(SInt32)productID;
- (long)getValue:(CameraControl_t)control selector:(CameraSelector_t)selector;
- (long)setValue:(long)value control:(CameraControl_t)control;

@end
