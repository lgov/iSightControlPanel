/*
 * CameraController.m
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

#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>

#import "CameraController.h"
#import "USBDefs.h"

// for mach_error_string
#include <mach/mach_error.h>

@implementation CameraController

UInt8 cameraTerminalID;
UInt8 processingUnitID;
IOUSBInterfaceInterface220 **interface;

typedef enum {
	CamPar_SignedNr = 512,
	CamPar_UnsignedNr,
} CameraValueSign_t;

typedef struct CameraControlDef CameraControlDef_t;
struct CameraControlDef {
	CameraControl_t control;  /* The value of this constant is also used as the
							     index in the cameraControlDefs structure! */
	UInt8 unit;               /* USB Camera unit that controls the specific
								 aspect (brightness...). */
	UInt8 usbCtrlSelector;    /* USB PU/Terminal Control selector. */
	UInt8 length;             /* Length for wLength field in both req/resp. */
	CameraValueSign_t sign;   /* Sign of the values in cur,min,max,def reqs. */
} cameraControlDefs[] = {
    {
		CamPar_Brightness,
		UVC_VC_PROCESSING_UNIT,
		UVC_PU_BRIGHTNESS_CONTROL,
		2,
		CamPar_SignedNr,
	},
    {
		CamPar_Contrast,
		UVC_VC_PROCESSING_UNIT,
		UVC_PU_CONTRAST_CONTROL,
		2,
		CamPar_UnsignedNr,
	},
};

/* Send GET_CUR,GET_MIN;GET_MAX,GET_RES,GET_LEN,GET_INFO or GET_DEF request to
   the VideoControl interface. */
- (long)getValue:(CameraControl_t)control selector:(CameraSelector_t)selector
{
	IOUSBDevRequest req;
	IOReturn res;
	long value = 0l;

	CameraControlDef_t ctrlDef = cameraControlDefs[control];

	UInt8 uvcSelector = (selector==CamPar_Min     ? UVC_GET_MIN:
						 selector==CamPar_Max     ? UVC_GET_MAX:
						 selector==CamPar_Current ? UVC_GET_CUR:
						 selector==CamPar_Default ? UVC_GET_DEF:
						 selector==CamPar_Resolution ? UVC_GET_RES:
						 0); /* Error */
	UInt8 unitID = (ctrlDef.unit == UVC_VC_PROCESSING_UNIT ? processingUnitID :
					(ctrlDef.unit == UVC_VC_INPUT_TERMINAL ? cameraTerminalID :
					 0)); /* Error */

	// Direction: incoming - kUSBIn
	// Type: generic request for this Class of devices - kUSBClass
	// Directed to the VideoControl interface - kUSBInterface
	req.bmRequestType = USBmakebmRequestType(kUSBIn, kUSBClass, kUSBInterface);
	req.bRequest = uvcSelector;
	req.wValue = (ctrlDef.usbCtrlSelector << 8) & 0xFF00; // low byte must be set to 0
	req.wIndex = (unitID << 8) & 0xFF00;    // endpoint 0
	req.wLength = ctrlDef.length;
	req.pData = &value;

	res = (*interface)->ControlRequest(interface, 0, &req);
	if(res != kIOReturnSuccess)
	{
		NSLog(@"CameraController: ControlRequest error: %08x %s\n", res,
			  mach_error_string(res));
		return 0l;
	}

	if (ctrlDef.sign == CamPar_SignedNr)
	{
		value = (ctrlDef.length == 1 ? (SInt8)value:
				 (ctrlDef.length == 2 ? (SInt16)value:
				  value));
	}

	return value;
}

/* Send SET_CUR request to the VideoControl interface. */
- (long)setValue:(long)value control:(CameraControl_t)control;
{
	IOUSBDevRequest req;
	IOReturn res;

	CameraControlDef_t ctrlDef = cameraControlDefs[control];
	UInt8 unitID = (ctrlDef.unit == UVC_VC_PROCESSING_UNIT ? processingUnitID :
					(ctrlDef.unit == UVC_VC_INPUT_TERMINAL ? cameraTerminalID :
					 0)); /* Error */

	// Direction: outgoing - kUSBOut
	// Type: generic request for this Class of devices - kUSBClass
	// Directed to the VideoControl interface - kUSBInterface
	req.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);

	req.bRequest = UVC_SET_CUR;
	req.wValue = (ctrlDef.usbCtrlSelector << 8) & 0xFF00; // low byte must be set to 0
	req.wIndex = (unitID << 8) & 0xFF00;    // endpoint 0
	req.wLength = ctrlDef.length;
	req.pData = &value;

	res = (*interface)->ControlRequest(interface, 0, &req);
	if(res != kIOReturnSuccess)
	{
		NSLog(@"CameraController: ControlRequest error: %08x %s\n", res,
			  mach_error_string(res));
		return 0l;
	}

	return value;
}

-(void)findUnitAndTerminalIds:(IOUSBDeviceInterface **)deviceInterface
{
	/* Find the Terminal and Unit Descriptors.

	 Example bus probe for the iSight camera:
	 VDC (Control) Input Terminal
	 Length (and contents): 18
	 Raw Descriptor (hex) 0000: 12 24 02 01 01 02 00 00 00 0000 00 00 00 03 0A
	 Raw Descriptor (hex) 0010: 00 00
	 bDescriptorType: 0x24
	 bDescriptorSubType: 0x2
	 Terminal ID 1
	 ...
	 VDC (Control) Processing Unit
	 Length (and contents): 11
	 Raw Descriptor (hex) 0000: 0B 24 05 03 01 00 00 02 7F 1500
	 bDescriptorType: 0x24
	 bDescriptorSubType: 0x5
	 Unit ID: 3
	 ...

	 To configure brightness... we need the Unit ID of the Processing unit
	 To configure exposure... we need the Terminal ID of the Input Terminal

	 The actual values for these ID's are not defined in the USB specs, but for
	 the bDescriptorType and bDescriptorSubType they are. (see sections A.4.
	 and A.5.)
	 */
	IOUSBConfigurationDescriptorPtr cfgDesc;
	IOReturn res = (*deviceInterface)->GetConfigurationDescriptorPtr(deviceInterface,
																	 0,
																	 &cfgDesc);
	if (res != kIOReturnSuccess)
		return;

	int remaining = cfgDesc->wTotalLength - cfgDesc->bLength;
	UInt8 *ptr = (UInt8*)cfgDesc+cfgDesc->bLength;

	while(remaining>0)
	{
		UVC_InterfaceDescriptorHdr_t *desclt = (UVC_InterfaceDescriptorHdr_t*)ptr;

		/* Skip the generic USB descriptors, only parse the Video/Control interface. */
		if (desclt->bDescriptorType == kUSBInterfaceDesc)
		{
			IOUSBInterfaceDescriptor *intDesc = (IOUSBInterfaceDescriptor *)ptr;
			if (!(intDesc->bInterfaceClass == UVC_CC_VIDEO &&
				  intDesc->bInterfaceSubClass == UVC_SC_VIDEOCONTROL))
				continue;

			ptr += intDesc->bLength;
			desclt = (UVC_InterfaceDescriptorHdr_t*)ptr;

			if (desclt->bDescriptorType != UVC_CS_INTERFACE)
				break;	/* Parsing Error. */

			UVC_VCHeaderDescriptor_t *intHdrDesc = (UVC_VCHeaderDescriptor_t *)ptr;
			if (intHdrDesc->bDescriptorSubType == UVC_SC_VIDEOCONTROL)
			{
				intHdrDesc->wTotalLength = USBToHostWord(intHdrDesc->wTotalLength);
				intHdrDesc->bcdUVC = USBToHostWord(intHdrDesc->bcdUVC);
				intHdrDesc->dwClockFrequency = USBToHostLong(intHdrDesc->dwClockFrequency);

				int vc_remaining = intHdrDesc->wTotalLength - desclt->bLength;
				ptr += desclt->bLength;
				remaining -= intHdrDesc->wTotalLength;

				while (vc_remaining>0)
				{
					desclt = (UVC_InterfaceDescriptorHdr_t*)ptr;
					if (desclt->bDescriptorType != UVC_CS_INTERFACE)
						break; // problem, should be CS_INTERFACE.

					if (desclt->bDescriptorSubType == UVC_VC_PROCESSING_UNIT)
					{
						processingUnitID =
						((UVC_ProcessingUnitDescriptor_t *)ptr)->bUnitID;
					}
					if (desclt->bDescriptorSubType == UVC_VC_INPUT_TERMINAL)
					{
						cameraTerminalID =
						((UVC_CameraTerminalDescriptor_t*)ptr)->bTerminalID;
					}
					vc_remaining -= desclt->bLength;
					ptr += desclt->bLength;
				}
			}
			else {
				// skip uninteresting data
				remaining -= desclt->bLength;
				ptr += desclt->bLength;
			}

			/* We have what we needed, stop parsing and bail out. */
			break;
		}
		else {
			// skip uninteresting data
			remaining -= desclt->bLength;
			ptr += desclt->bLength;
		}
	}
}

- (IOUSBInterfaceInterface220 **)getControlInterfaceForDevice:(IOUSBDeviceInterface **)deviceInterface
{
	IOReturn res;
	IOUSBInterfaceInterface220 **controlInterface;

	io_iterator_t interfaceIterator;
	HRESULT result;
	io_service_t usbInterface;

	IOUSBFindInterfaceRequest interfaceRequest;
	interfaceRequest.bInterfaceClass = UVC_CC_VIDEO;
	interfaceRequest.bInterfaceSubClass = UVC_SC_VIDEOCONTROL;
	interfaceRequest.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
	interfaceRequest.bAlternateSetting = kIOUSBFindInterfaceDontCare;

	res = (*deviceInterface)->CreateInterfaceIterator(deviceInterface,
													  &interfaceRequest,
													  &interfaceIterator);
	if(res != kIOReturnSuccess)
		return NULL;

	// The control interface is interface #0, so should be first in the list.
	if(usbInterface = IOIteratorNext(interfaceIterator))
	{
		IOCFPlugInInterface **plugin = NULL;

		// Create an intermediate plug-in
		SInt32 score;
		res = IOCreatePlugInInterfaceForService(usbInterface,
												kIOUSBInterfaceUserClientTypeID,
												kIOCFPlugInInterfaceID,
												&plugin,
												&score);
		/* Now that we have the plugin, we don't need the usbInterface object
	       anymore. */
		res = IOObjectRelease(usbInterface);
		if((res != kIOReturnSuccess) || !plugin)
		{
			NSLog(@"CameraController: CreatePluginInterface error: %08x %s\n", res,
				  mach_error_string(res));

			return NULL;
		}

		/* Now create the interface for the control interface. */
		result = (*plugin)->QueryInterface(plugin,
										   CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
										   (LPVOID *) &controlInterface);
		/* Now that we have the control interface, we don't need the plugin
	       object anymore. */
		(*plugin)->Release(plugin);

		if(result || !controlInterface)
		{
			NSLog(@"CameraController: QueryInterface error: %08x %s\n", res,
				  mach_error_string(res));
			return NULL;
		}

		/** DEBUG **/
        //Get interface class and subclass

		UInt8 interfaceClass;
		UInt8 interfaceSubClass;
		UInt8 interfaceNumEndpoints;

        res = (*controlInterface)->GetInterfaceClass(controlInterface,
													 &interfaceClass);
        res = (*controlInterface)->GetInterfaceSubClass(controlInterface,
														&interfaceSubClass);
		res = (*controlInterface)->GetNumEndpoints(controlInterface,
												   &interfaceNumEndpoints);
        NSLog(@"CameraController: Interface class %d, subclass %d\n",
			  interfaceClass, interfaceSubClass);

		return controlInterface;
	}

	return NULL;
}

- (BOOL)openUSBCamera:(SInt32)vendorID :(SInt32)productID
{
	IOReturn res;
	io_service_t usbDevice;

	// Find all video class devices
	CFMutableDictionaryRef  matchingDict;
	//Set up matching dictionary for class IOUSBDevice and its subclasses
    matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if (!matchingDict)
    {
        NSLog(@"CameraController: Couldn’t search for the USB device.\n");
        return FALSE;
    }

	/* Filter on a specific device based on vendor and product ID. */
	CFDictionarySetValue(matchingDict, CFSTR(kUSBVendorID),
						 CFNumberCreate(kCFAllocatorDefault,
										kCFNumberSInt32Type,
										&vendorID));
	CFDictionarySetValue(matchingDict, CFSTR(kUSBProductID),
						 CFNumberCreate(kCFAllocatorDefault,
										kCFNumberSInt32Type,
										&productID));

	if (matchingDict)
	{
		io_iterator_t devices;
		if (KERN_SUCCESS == IOServiceGetMatchingServices(kIOMasterPortDefault,
														 matchingDict,
														 &devices))
		{
			/* It's an exact search, so take the first found device (if any). */
			usbDevice = IOIteratorNext(devices);
			IOObjectRelease(devices);
		}
	}

	/* Get an interface to the control pipe */
	if (usbDevice)
	{
		IOUSBDeviceInterface **deviceInterface = NULL;
		IOCFPlugInInterface	**plugInInterface = NULL;
		SInt32 score;
		res = IOCreatePlugInInterfaceForService(usbDevice,
												kIOUSBDeviceUserClientTypeID,
												kIOCFPlugInInterfaceID,
												&plugInInterface,
												&score);
		if( (kIOReturnSuccess != res) || !plugInInterface)
		{
			NSLog(@"CameraController: IOCreatePlugInInterfaceForService returned 0x%08x.", res);
		}

		res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
												 (LPVOID*) &deviceInterface);
		(*plugInInterface)->Release(plugInInterface);
		if(res || deviceInterface == NULL) {
			NSLog(@"CameraController: QueryInterface returned %d.\n", (int)res);
		}


		/* Find the Video Control interface for this device. */
		interface = [self getControlInterfaceForDevice:deviceInterface];

		/* Find some ID's which we'll need later to modify device properties. */
		[self findUnitAndTerminalIds:deviceInterface];
	}

	return TRUE;
}


@end
