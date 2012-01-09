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


/** Types used to request and update control values. **/
typedef enum {
	CamPar_Brightness = 0
} CameraControl_t;

typedef enum {
	CamPar_Min = 256,
	CamPar_Max,
	CamPar_Current,
	CamPar_Default,
	CamPar_Resolution
} CameraSelector_t;

@interface CameraController : NSObject {

}
- (BOOL)openUSBCamera:(SInt32)vendorID :(SInt32)productID;
- (long)getValue:(CameraControl_t)control selector:(CameraSelector_t)selector;
- (long)setValue:(long)value control:(CameraControl_t)control;

@end
