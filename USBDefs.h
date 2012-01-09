/*
 * USBDefs.h
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


/** Definitions from the USB Video Class (UVC) 1.1 spec **/

/** USB VideoClass_1.1.pdf Section A.8. Video Class-Specific Request Codes. **/
#define UVC_RC_UNDEFINED 0x00

#define UVC_SET_CUR 0x01			// Modify Current setting
#define UVC_GET_CUR 0x81			// Current setting attribute
#define UVC_GET_MIN 0x82			// Minimum setting attribute
#define UVC_GET_MAX 0x83			// Maximum setting attribute
#define UVC_GET_RES 0x84			// Resolution attribute
#define UVC_GET_LEN 0x85			// Data length attribute
#define UVC_GET_INFO 0x86			// Information attribute
#define UVC_GET_DEF 0x87			// Default setting attribute

/** USB VideoClass_1.1.pdf Section A.1. Video Interface Class code. **/
// See also http://www.usb.org/developers/devclass_docs/ (Video Class)

#define UVC_CC_VIDEO 0x0E

/** USB VideoClass_1.1.pdf Section A.2. Video Interface Subclass codes. **/
#define UVC_SC_UNDEFINED 0x00
#define UVC_SC_VIDEOCONTROL 0x01
#define UVC_SC_VIDEOSTREAMING 0x02
#define UVC_SC_VIDEO_INTERFACE_COLLECTION 0x03

/** USB VideoClass_1.1.pdf Section A.4. VC Interface Descriptor Types. **/
#define UVC_CS_UNDEFINED 0x20
#define UVC_CS_DEVICE 0x21
#define UVC_CS_CONFIGURATION 0x22
#define UVC_CS_STRING 0x23
#define UVC_CS_INTERFACE 0x24
#define UVC_CS_ENDPOINT 0x25

/** USB VideoClass_1.1.pdf Section A.5. VC Interface Descriptor Subtypes. **/
#define UVC_VC_DESCRIPTOR_UNDEFINED 0x00
#define UVC_VC_HEADER 0x01
#define UVC_VC_INPUT_TERMINAL 0x02
#define UVC_VC_OUTPUT_TERMINAL 0x03
#define UVC_VC_SELECTOR_UNIT 0x04
#define UVC_VC_PROCESSING_UNIT 0x05
#define UVC_VC_EXTENSION_UNIT 0x06

/** USB VideoClass_1.1.pdf Section A.9.4. Camera Terminal Control Selectors. **/
/** TODO: add when needed, not sure what works on the iSight camera **/

/** USB VideoClass_1.1.pdf Section A.9.5. Processing Unit Control Selectors. **/
#define UVC_PU_CONTROL_UNDEFINED 0x00
#define UVC_PU_BACKLIGHT_COMPENSATION_CONTROL 0x01
#define UVC_PU_BRIGHTNESS_CONTROL 0x02
#define UVC_PU_CONTRAST_CONTROL 0x03
#define UVC_PU_GAIN_CONTROL 0x04
#define UVC_PU_POWER_LINE_FREQUENCY_CONTROL 0x05
#define UVC_PU_HUE_CONTROL 0x06
#define UVC_PU_SATURATION_CONTROL 0x07
#define UVC_PU_SHARPNESS_CONTROL 0x08
#define UVC_PU_GAMMA_CONTROL 0x09
#define UVC_PU_WHITE_BALANCE_TEMPERATURE_CONTROL 0x0A
#define UVC_PU_WHITE_BALANCE_TEMPERATURE_AUTO_CONTROL 0x0B
#define UVC_PU_WHITE_BALANCE_COMPONENT_CONTROL 0x0C
#define UVC_PU_WHITE_BALANCE_COMPONENT_AUTO_CONTROL 0x0D
#define UVC_PU_DIGITAL_MULTIPLIER_CONTROL 0x0E
#define UVC_PU_DIGITAL_MULTIPLIER_LIMIT_CONTROL 0x0F
#define UVC_PU_HUE_AUTO_CONTROL 0x10
#define UVC_PU_ANALOG_VIDEO_STANDARD_CONTROL 0x11

/** USB VideoClass 1.1.pdf Section 3.1. Descriptor Layout. **/
typedef struct UVC_VCHeaderDescriptor UVC_VCHeaderDescriptor_t;
typedef struct UVC_InterfaceDescriptorHdr UVC_InterfaceDescriptorHdr_t;
typedef struct UVC_CameraTerminalDescriptor UVC_CameraTerminalDescriptor_t;
typedef struct UVC_ProcessingUnitDescriptor UVC_ProcessingUnitDescriptor_t;

struct UVC_InterfaceDescriptorHdr {
	UInt8 bLength;
	UInt8 bDescriptorType;
	UInt8 bDescriptorSubType;
};

#pragma pack(1)    /* needed here because otherwise there would be a gap of
1 byte added before bcdUV. */
struct UVC_VCHeaderDescriptor {
	UInt8  bLength;
	UInt8  bDescriptorType;
	UInt8  bDescriptorSubType;
	UInt16 bcdUVC;
	UInt16 wTotalLength;
	UInt32 dwClockFrequency;
	UInt8  bInCollection;
	UInt8  baInterface;    /* TODO: array, but we're not using this. */
};
#pragma pack(pop)

struct UVC_CameraTerminalDescriptor {
	UInt8  bLength;
	UInt8  bDescriptorType;
	UInt8  bDescriptorSubType;
	UInt8  bTerminalID;
	UInt16 wTerminalType;
	UInt8  bAssocTerminal;
	UInt8  iTerminal;
	UInt16 wObjectiveFocalLengthMin;
	UInt16 wObjectiveFocalLengthMax;
	UInt16 wOcularFocalLength;
	UInt8  bControlSize;
	UInt8  bmControls;    /* TODO: array, but we're not using this (yet). */
};

#pragma pack(1)
struct UVC_ProcessingUnitDescriptor {
	UInt8  bLength;
	UInt8  bDescriptorType;
	UInt8  bDescriptorSubType;
	UInt8  bUnitID;
	UInt8  bSourceID;
	UInt16 wMaxMultiplier;
	UInt8  bControlSize;
	UInt8  bmControls;    /* TODO: array, but we're not using this (yet). */
	/* TODO: iProcessing and bmVideoStandards */
};
#pragma pack(pop)

/** End of USB VideoClass spec definitions. **/
