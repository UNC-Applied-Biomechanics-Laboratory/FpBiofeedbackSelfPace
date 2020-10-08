Documentation for the Matlab SDK for Cortex
Matlab Cortex SDK version 1.0
Created January 2014

The Matlab SDK may be used to communicate with Cortex to obtain data frames
and body definitions in real time.
The SDK consists of the following four functions (mex functions):

1. mCortexInitialize
2. mGetCurrentFrame
3. mgetBodyDefs
4. mCortexExit

Detailed explanations are given below.

It is necessary to always begin with running mCortexInitialize to load the 
libraries and initialize communications. 
This need only be done ONE time. It is not necessary to repeat loading the 
libraries and this will result in unecessary delays in obtaining current 
data frames. 

Data frames may be obtained using mGetCurrentFrame as many times as 
desired.
Body definitions may be obtained using mGetBodyDefs as many times as 
desired.

Following completion, it is extremely important to exit using mCortexExit. 
This will unload the libraries and terminate communication.

---------------------------------------------------------------------------
---------------------------------------------------------------------------

1. mCortexInitialize
--------------------
returnValue = mCortexInitialize(initializationStructure);

This function takes an initialization structure as an argument and returns 
an output code specifying the success of the initialization.
The input structure must contain five fields and be of the form:

initializationStructure.TalkToHostNicCardAddress = '127.0.0.1';
initializationStructure.HostNicCardAddress = '127.0.0.1';
initializationStructure.HostMulticastAddress = '225.1.1.1';
initializationStructure.TalkToClientsNicCardAddress = '0';
initializationStructure.ClientsMulticastAddress = '225.1.1.2';

TalkToHostNicCardAddress - This is the interface we send requests FROM when
 communicating with the SDK2 host. 
HostNicCardAddress - This is the interface we send requests TO when 
communicating with the SDK2 host. 
HostMulticastAddress - This is the address that the SDK2 host multicasts 
data to. This is not a physical device address. 
TalkToClientsNicCardAddress - This is the interface that we listen to SDK2 
client requests on. 
ClientsMulticastAddress - This is the address that we multicast data TO 
when sending data to our SDK2 clients. This is not a physical device 
address. 

The above values are suggested defaults. 
Arguments Must be in the form 'a.b.c.d'

The following possible return values may occur:
0: Okay
1: General Error
2: Invalid use of the API
3: Network Error

2. mGetCurrentFrame
-------------------
frameOfData = mGetCurrentFrame();

This function is used to obtain the current frame of data.
The function takes no input arguments and it returns a frameOfData 
structure. 

frameOfData structure field description:

iFrame:                 Cortex's frame number
fDelay:                 Total time (seconds) from Camera to the Host 
                        sending the data
nBodies:                Number of bodies
BodyData:               An array of data for eac h body. 
                        See below for body data structure
nUnidentifiedMarkers:	Number of unrecognized markers
Unidentifiedmarkers:    An array of the unrecognized markers
AnalogData:             Structure of the analog data packaged. See below.
RecordingStatus:        Info about name and frames being recorded

BodyData structure field description:

szName:             String name of each body
nMarkers:           Number of markers defined
Markers:            2-D array of markers [nMarkers][3] 
fAvgMarkerResidual: Average residual of the marker triangulations
nSegments:          Number of segments
Segments:           2-D array of segments [nSegments][7]
nDofs:              Number of degrees-of-freedom
Dofs:               Array of degree-of-freedom angles
fAvgDofResidual:    Average residual from the solve
nIterations:        Number of iterations to solve
ZoomEncoderValue:   Zoom value from the Camera Tracker Encoder
FocusEncoderValue:  Focus value from the Camera Tracker Encoder
IrisEncoderValue:   Iris value from the Cam Track lens Encoder
nEvents:            The number of events that occured on this frame
Events:             List of Event names that occured on this frame

AnalogData structure field descriptions:
nAnalogChannels:        Total number of active channels
nAnalogSamples:         The number of samples in the current frame
AnalogSamples:          The analog data: nChannels * nSamples of these
nForcePlates:           Total number of active forceplates
nForceSamples:          The number of samples in the current frame
Forces:                 The forces: nForcePlates * nForceSamples of these
nAngleEncoders:         Number of encoders
nAngleEncoderSamples:   Number of samples per encoder
AngleEncoderSamples:    The angles: nEncoders*nEncoderSamples of these


3. mGetBodyDefs
---------------

bodyDefs = mGetBodyDefs();

This function is used to obtain the body definitions.
The function takes no input arguments and it returns a bodyDefs 
structure. 

bodyDefs structure field description:

nBodyDefs:          Number of bodies being tracked
Body:               The definition of each body (array of Body structures
                    described below
nAnalogChannels:    The number of active analog channels
AnalogChannelNames: The names given to each channel
nForcePlates:       The number of active forceplates
AnalogBitDepth:     The number of bits in an analog sample. 0 is not 
                    provided.
AnalogLoVoltage:    Lo end of voltage range for each analog channel.  
AnalogHiVoltage:    Hi end of voltage range for each analog channel.

Body structure field descriptions:
szName:             Name of the Body 
nMarkers:           Number of markers
szMarkerNames:      Array of marker names
nSegments:          Number of segments
szSegmentNames:     Array of segment names
nDofs:              Number of degrees of freedom
szDofNames:         Array of degrees of freedom names

4. mCortexExit
--------------

exitValue = mCortexExit();

This function stops all activity of the SDK.
This function should be called once before exiting.

The following possible return values may occur:
0: Okay
1: General Error
2: Invalid use of the API
3: Network Error

