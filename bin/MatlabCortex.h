/*=========================================================
//
// File: Cortex.h  v200
//
// Created by Ned Phipps, Oct-2004
//
// This file defines the interface to Cortex ethernet communication.
//
//----------------------------------------------------------
Modification History:

Date      By          Comment
------------------------------------------------------------
Oct 2004  np          First version
Mar 2011  ba		  Added ability to act as an SDK2 host to this development package.
=============================================================================*/

/*! \file Cortex.h
This file defines the structures and the API for ethernet communication of data
between Cortex and multiple client programs.
*/

#ifndef Cortex_H
#define Cortex_H

#ifdef _WINDOWS
    #define DLL __declspec(dllexport)
#else
    #define DLL
#endif


/** Return codes
*/
typedef enum maReturnCode
{
    RC_Okay=0,             //!< Okay
    RC_GeneralError,       //!< General Error
    RC_ApiError,           //!< Invalid use of the API
    RC_NetworkError,       //!< Network Error
    RC_TimeOut,            //!< No response from Cortex
    RC_MemoryError,        //!< Memory allocation failed
    RC_Unrecognized        //!< Request string not recognized
}
maReturnCode;


/** Verbosity setting for internal messages
*/
typedef enum maVerbosityLevel
{
    VL_None=0,   //!< No Messages
    VL_Error,    //!< Error Message
    VL_Warning,  //!< Warning Message [DEFAULT VALUE]
    VL_Info,     //!< Informational Message
    VL_Debug     //!< Debug Message
}
maVerbosityLevel;


/** Threading priorities for threads used by the SDK2. */
typedef enum maThreadPriority
{
	TP_Default,
	TP_Lowest,
	TP_BelowNormal,
	TP_Normal,
	TP_AboveNormal,
	TP_Highest
}
maThreadPriority;


/** This is how we see what type of data Cortex returned */
typedef enum maSkyReturnType
{
	SKY_VOID,
	SKY_STRING,
	SKY_BOOL,
	SKY_CHAR,
	SKY_SHORT,
	SKY_INT,	
	SKY_LONG,
	SKY_FLOAT,
	SKY_DOUBLE
}
maSkyReturnType;


// Array dimensions

#define MAX_N_BODIES      100


#define XEMPTY 9999999.0f


/** Data for one segment
*/
typedef double tSegmentData[7]; //!<  X,Y,Z, aX,aY,aZ, Length

/** Data for one marker
*/
typedef float  tMarkerData[3];  //!<  X,Y,Z

/** Data for one forceplate
*/
typedef float  tForceData[7];   //!<  X,Y,Z, fX,fY,fZ, mZ

/** Data for one degree of freedom
*/
typedef double tDofData;        //!<  Usually an angle value in degrees




//==================================================================
//==================================================================
//
//   S T R U C T U R E S
//
//==================================================================
//==================================================================


//==================================================================

//! The description of the connection to Cortex.
/*!
This contains information about the host machine, the host program, and the connection status.
*/
typedef struct sHostInfo
{
    int           bFoundHost;              //!< True = have talked to Cortex
    int           LatestConfirmationTime;  //!< Time of last receipt from Cortex
    char          szHostMachineName[128];  //!< Name of machine Cortex is running on
    unsigned char HostMachineAddress[4];   //!< IP Address of that machine 
    char          szHostProgramName[128];  //!< Name of module communicating with
    unsigned char HostProgramVersion[4];   //!< Version number of that module

} sHostInfo;


//==================================================================

//! The rudimentary description of a skeleton's bones and hierarchy.
/*!
This description is defined by szSegmentNames[iSegment], and iParent[iSegment]
*/
typedef struct sHierarchy
{
    int            nSegments;         //!< Number of segments
    char**         szSegmentNames;    //!< Array of segment names
    int*           iParents;          //!< Array of segment parents (defines the hierarchy)

} sHierarchy;


//==================================================================

//! The description of a single tracking object that will have streaming data.
/*!
This description includes the object's name, the marker names, the skeleton hierarchy, and the DOF names.
*/
typedef struct sBodyDef
{
    char*          szName;            //!< Name of the object

    int            nMarkers;          //!< Number of markers
    char**         szMarkerNames;     //!< Array of marker names

    sHierarchy     Hierarchy;         //!< The Skeleton description for HTR data

    int            nDofs;             //!< Number of degrees of freedom
    char**         szDofNames;        //!< Array of degrees of freedom names

} sBodyDef;


//==================================================================

//! The description of all the data that will stream from Cortex.
/*!
This description includes all the body descriptions, the analog channels,
and the number of forceplates.
*/
typedef struct sBodyDefs
{
    int            nBodyDefs;               //!< Number of bodies being tracked
    sBodyDef       BodyDefs[MAX_N_BODIES];  //!< The definition of each body

    int            nAnalogChannels;         //!< The number of active analog channels
    char**         szAnalogChannelNames;    //!< The names given to each channel

    int            nForcePlates;            //!< The number of active forceplates

	//Older versions of Cortex did not provide these values. They will be 0/NULL if not provided by Cortex.
	int            AnalogBitDepth;          //!< The number of bits in an analog sample. 0 is not provided.
	float*         AnalogLoVoltage;         //!< Lo end of voltage range for each analog channel. 
	float*         AnalogHiVoltage;         //!< Hi end of voltage range for each analog channel.

    void*          AllocatedSpace;          //!< Private space (DON'T TOUCH)

} sBodyDefs;


//==================================================================

//! A structure containing ALL the data to drive one markerset.
/*!
This contains the markerset's name, the marker positions, the segment positions relative to each segment's parent, and the DOFs.
*/
typedef struct sBodyData
{
    char           szName[128];          //!< For dynamic matching of objects.

    int            nMarkers;             //!< Number of markers defined
    tMarkerData*   Markers;              //!< [nMarkers][3] array.  Markers[iMarker][0] == XEMPTY means no data.
    float          fAvgMarkerResidual;   //!< Average residual of the marker triangulations

    int            nSegments;            //!< Number of segments
    tSegmentData*  Segments;             //!< [nSegments][7] array

    int            nDofs;                //!< Number of degrees-of-freedom
    tDofData*      Dofs;                 //!< Array of degree-of-freedom angles
    float          fAvgDofResidual;      //!< Average residual from the solve
    int            nIterations;          //!< Number of iterations to solve

    int            ZoomEncoderValue;     //!< Zoom value from the Camera Tracker Encoder
    int            FocusEncoderValue;    //!< Focus value from the Camera Tracker Encoder
    int            IrisEncoderValue;     //!< Iris value from the Cam Track lens Encoder

	//Old versions of Cortex didn't provide these.
	int            nEvents;              //!< The number of events that occured on this frame
	char**         Events;               //!< List of Event names that occured on this frame

} sBodyData;


//==================================================================

//! All the analog data for one frame's worth of time.
/*!
This includes the raw analog samples, processed forces, and also angle encoder values (if available).
*/
typedef struct sAnalogData
{
    int            nAnalogChannels;  //!< Total number of active channels
    int            nAnalogSamples;   //!< The number of samples in the current frame
    short*         AnalogSamples;    //!< The data: nChannels * nSamples of these

    int            nForcePlates;     //!< Total number of active forceplates
    int            nForceSamples;    //!< The number of samples in the current frame
    tForceData*    Forces;           //!< The forces: nForcePlates * nForceSamples of these

    int            nAngleEncoders;      //!< Number of encoders
    int            nAngleEncoderSamples;//!< Number of samples per encoder
    double*        AngleEncoderSamples; //!< The angles: nEncoders*nEncoderSamples of these

} sAnalogData;


//==================================================================

//! The recording status tells us the frame numbers and capture filename.
typedef struct sRecordingStatus
{
    int            bRecording;   //!< 0=Not Recording, anything else=Recording
    int            iFirstFrame;  //!< The frame number of the first data frame to be recorded from Cortex Live Mode
    int            iLastFrame;   //!< The frame number of the last data frame to be recorded from Cortex Live Mode
    char           szFilename[256]; //!< The full capture filename 

} sRecordingStatus;


typedef struct sTimeCode
{
    int            iStandard;   //!< 0=None, 1=SMPTE, 2=FILM, 3=EBU, 4=SystemClock
    int            iHours;
    int            iMinutes;
    int            iSeconds;
    int            iFrames;

} sTimeCode;


//==================================================================

//! ALL the data for one frame streamed from Cortex.
/*!
This include the two items that describe the frame. The first is the frame number.
The second is the time delay measuring the delay between the real world action and the host sending this frame.
The actual data for the frame includes the data for each body, the unidentified markers, and data that is 
associated with the analog captures.
*/
typedef struct sFrameOfData
{
    int            iFrame;                  //!< Cortex's frame number
    float          fDelay;                  //!< Total time (seconds) from Camera to the Host sending the data

    int            nBodies;                 //!< The bodies should match the descriptions
    sBodyData      BodyData[MAX_N_BODIES];  //!< The data for each body

    int            nUnidentifiedMarkers;    //!< Number of unrecognized markers
    tMarkerData*   UnidentifiedMarkers;     //!< The unrecognized markers



    sAnalogData    AnalogData;              //!< The analog data packaged

    sRecordingStatus RecordingStatus;       //!< Info about name and frames being recorded

    sTimeCode      TimeCode;                //!< For system-wide frame alignment

} sFrameOfData;

//==================================================================
/*!
This is how the return value of a Sky Command to Cortex is retrieved. 
*/
typedef struct sSkyReturn
{
	maReturnCode	ReturnCode;			//This is Cortex's response to the command. RC_Okay implies it was executed.
	maSkyReturnType	ReturnType;			//this is the type of data that has been returned
	union
	{
		char	String[2048];
		char	Char;
		//bool	Bool;
		short	Short;
		int		Int;
		long	Long;
		float	Float;
		double	Double;
	} ReturnData;	//this is the returned data.
} sSkyReturn;


#ifdef  __cplusplus
extern "C" {
#endif


//==================================================================

/** This function returns a 4-byte version number.
 *
 * \param Version - An array of four bytes: ModuleID, Major, Minor, Bugfix
 *
 * \return RC_Okay
*/
DLL int Cortex_GetSdkVersion(unsigned char Version[4]);

//==================================================================

/** This function sets the filter level of the LogMessages.
 *
 *  The default verbosity level is VL_Warning.
 *
 * \param iLevel - one of the maVerbosityLevel enum values.
 *
 * \return RC_Okay
*/
DLL int Cortex_SetVerbosityLevel(int iLevel);

//==================================================================

/** This function gets the filter level of the LogMessages.
 *
 *  The default verbosity level is VL_Warning.
 *
 * \return one of the maVerbosityLevel enum values.
*/
DLL int Cortex_GetVerbosityLevel();

//==================================================================

/** This function sets the minimum timeout for responses from the host. 
 * Many internal functions have built in timeouts, but this sets a floor for those.
 * This is needed if there are many steps in the SDK2 data chain.
 *
 *  The default value is 500ms. It is not recommended to go below this.
 *
 * \param msMinTimeout - The minimum timeout in milliseconds.
 *
 * \return RC_Okay
*/
DLL int Cortex_SetMinTimeout(int msTimeout);

//==================================================================

/** This function gets the minimum timeout for responses from the host. 
 *
 * \return the minimum timeout in milliseconds
*/
DLL int Cortex_GetMinTimeout();

//==================================================================

/**   The user supplied function handles text messages posted from within the SDK.
 *
 *    Logging messages is done as a utility to help code and/or run using the SDK.
 *    Various messages get posted for help with error conditions or events that happen.
 *    Each message has a Log-Level assigned to it so the user can.
 *  \sa Cortex_SetVerbosityLevel
 *
 *
 *  \param  MyFunction - This user defined function handles messages from the SDK.
 *
 *  \return maReturnCode - RC_Okay
*/
DLL int Cortex_SetErrorMsgHandlerFunc(void (*MyFunction)(int iLogLevel, char* szLogMessage));

//==================================================================

/**   The user supplied function will be called whenever a frame of data arrives.
 *
 *    The ethernet servicing is done via a thread created
 *    when the connection to Cortex is made.  This function is
 *    called from that thread.  Some tasks are not sharable
 *    directly across threads.  Window redrawing, for example,
 *    should be done via events or messages.
 *
 *  \param MyFunction - This user supply callback function handles the streaming data
 *
 *  \return maReturnCode - RC_Okay
 *
 *    Notes: The data parameter points to "hot" data. That frame of data
 *           will be overwritten with the next call to the callback function.
*/
DLL int Cortex_SetDataHandlerFunc(void (*MyFunction)(sFrameOfData* pFrameOfData));

//==================================================================

/**   This is the function used to send data to the clients. This is not automated,
 *    unlike requests, so that the data can be processed prior to being forwarded.
 *
 *  \return maReturnCode - RC_Okay on success.
 */
DLL int Cortex_SendDataToClients(sFrameOfData* pFrameOfData);

//==================================================================

/**   This sets wether or not communication with SDK2 clients is enabled. The default is false.
 *    This should be set BEFORE calling Cortex_Initialize. Communication with clients requires
 *    additional socket and threading resources.
 *
 *  \param bEnabled - true enables client communications, false disables them
 */
DLL void Cortex_SetClientCommunicationEnabled(int bEnabled);

//==================================================================

/**   Get the status of the flag set in Cortex_SetClientCommunicationEnabled.
 *
 *  \return TRUE if client communication is enabled, FALSE otherwise
 */
DLL int  Cortex_IsClientCommunicationEnabled();

//==================================================================

/**   The SDK2 communications use up tp three threads. One for reading data from the host, one for listening for 
 *    responses to requests from the host, and one for listening for clients. This function allows the thread priority
 *    for these threads to be changed. Pass one of the maThreadPriority values. This must be called BEFORE Cortex_Initialize.
 *
 *  \param ListenForHost - The thread priority for the thread that listens for communications from the host.
 *  \param ListenForData - The thread priority for the thread that listens for data multicasts from the host.
 *  \param ListenForClients - The thread priority for the thread that listens for communications from the clients.
 *
 *  \return maReturnCode - RC_Okay, RC_ApiError  
 */
DLL void Cortex_SetThreadPriorities(maThreadPriority ListenForHost, maThreadPriority ListenForData, maThreadPriority ListenForClients); 

//==================================================================

/**   This function defines what port numbers are used for communication with the host and clients.
 * This must be called BEFORE Cortex_Initialize. If you don't wish to change
 * a particular port number, just pass -1. Valid port numbers must be in the range [1,65535]. 
 * Some of the port parameters can also take 0, which indicates that any available port number if fine to use.
 *
 *  \param TalkToHostPort - This is the port we send requests FROM when communicating with the SDK2 host.
 *  \param HostPort - This is the port we send requests TO when communicating with the SDK2 host.
 *  \param HostMulticastPort - This is the port that the SDK2 host multicasts data to. We read the data fro this port.
 *  \param TalkToClientsRequestPort - This is the port that we listen to SDK2 client requests on.
 *  \param TalkToClientsMulticastPort - This is the port that we multicast data FROM when sending data to our SDK2 clients.
 *  \param ClientsMulticastPort - This is the port that we multicast data TO when sending data to our SDK2 clients.
 *
 *  \return maReturnCode - RC_Okay, RC_ApiError
 */
DLL int  Cortex_ConfigurePortNumbers(	int TalkToHostPort,                 //0 == find available
										int HostPort, 
										int HostMulticastPort, 
										int TalkToClientsRequestPort, // = 0,   //0 == find available
										int TalkToClientsMulticastPort, // = 0, //0 == find available
										int ClientsMulticastPort); // = -1);

//==================================================================

/**   This function defines the connection routes to talk to the SDK2 host and SDK2 Clients.
 *
 *    Machines can have more than one ethernet interface.  This function
 *    is used to either set the ethernet interfaces to use, or to let
 *    the SDK auto-select the local interface, and/or the host.
 *    This function should only be called once at startup.
 *
 *  \param szTalkToHostNicCardAddress - This is the interface we send requests FROM when communicating with the SDK2 host. "a.b.c.d" or HostName. "" and NULL mean AutoSelect. 
 *  \param szHostNicCardAddress - This is the interface we send requests TO when communicating with the SDK2 host. "a.b.c.d" or HostName.  "" and NULL mean AutoSelect.
 *  \param szHostMulticastAddress - This is the address that the SDK2 host multicasts data to. This is not a physical device address. Must be in the form "a.b.c.d".
 *  \param szTalkToClientsNicCardAddress - This is the interface that we listen to SDK2 client requests on. "a.b.c.d" or HostName.  "" and NULL mean AutoSelect.
 *  \param szClientsMulticastAddress - This is the address that we multicast data TO when sending data to our SDK2 clients. This is not a physical device address. Must be in the form "a.b.c.d".
 *
 *  \return maReturnCode - RC_Okay, RC_ApiError, RC_NetworkError, RC_GeneralError
*/
DLL int Cortex_Initialize(	char* szTalkToHostNicCardAddress, 
							char* szHostNicCardAddress,
							char* szHostMulticastAddress, // = "225.1.1.1",
							char* szTalkToClientsNicCardAddress, // = 0,
							char* szClientsMulticastAddress); // = "225.1.1.2");

//==================================================================

/**   Gets the currently configured port numbers. Pass NULL to skip a particular port. 
 *
 *  \param TalkToHostPort - This is the port we send requests FROM when communicating with the SDK2 host.
 *  \param HostPort - This is the port we send requests TO when communicating with the SDK2 host.
 *  \param HostMulticastPort - This is the port that the SDK2 host multicasts data to. We read the data fro this port.
 *  \param TalkToClientsRequestPort - This is the port that we listen to SDK2 client requests on.
 *  \param TalkToClientsMulticastPort - This is the port that we multicast data FROM when sending data to our SDK2 clients.
 *  \param ClientsMulticastPort - This is the port that we multicast data TO when sending data to our SDK2 clients
 *
 *  \return maReturnCode - RC_Okay
 */
DLL int Cortex_GetPortNumbers(	int *TalkToHostPort,
								int *HostPort, 
								int *HostMulticastPort, 
								int *TalkToClientsRequestPort,
								int *TalkToClientsMulticastPort,
								int *ClientsMulticastPort);

//==================================================================

/** Get the currently configured communication addresses. Pass NULL to skip a particular address. 
 *
 *  \param szTalkToHostNicCardAddress - This is the interface we send requests FROM when communicating with the SDK2 host. "a.b.c.d" or HostName. "" and NULL mean AutoSelect. 
 *  \param szHostNicCardAddress - This is the interface we send requests TO when communicating with the SDK2 host. "a.b.c.d" or HostName.  "" and NULL mean AutoSelect.
 *  \param szHostMulticastAddress - This is the address that the SDK2 host multicasts data to. This is not a physical device address. Must be in the form "a.b.c.d".
 *  \param szTalkToClientsNicCardAddress - This is the interface that we listen to SDK2 client requests on. "a.b.c.d" or HostName.  "" and NULL mean AutoSelect.
 *  \param szClientsMulticastAddress - This is the address that we multicast data TO when sending data to our SDK2 clients. This is not a physical device address. Must be in the form "a.b.c.d".
 *
 *  \return maReturnCode - RC_Okay
 */
DLL int Cortex_GetAddresses(char* szTalkToHostNicCardAddress, 
							char* szHostNicCardAddress,
							char* szHostMulticastAddress,
							char* szTalkToClientsNicCardAddress,
							char* szClientsMulticastAddress);

//==================================================================

/** This function gets information about the connection to Cortex
 *
 *  This function returns IP-Address information and Cortex version information.
 *  The version info can be used to handle incompatible changes in either our code
 *  or your code.
 *
 * \param pHostInfo - Structure containing connection information
 *
 * \return RC_Okay, RC_NetworkError
*/
DLL int Cortex_GetHostInfo(sHostInfo *pHostInfo);

//==================================================================

/** This function stops all activity of the SDK.
 *
 *  This function should be called once before exiting.
*/
DLL int Cortex_Exit();

//==================================================================

/**   This function sends commands to Cortex and returns a response.
 *
 *    This function is an extendable interface between the Client programs
 *    and the Host (Cortex) program.  The commands are sent as readable text strings.
 *    The response is returned unaltered.
 *
 * \param szCommand - The request to send the Cortex
 * \param ppResponse - The reply. Note: This returns a "hot" pointer. The calling function should make use of the pointer before calling this function again.
 * \param pnBytes - The number of bytes in the response
 *
 \verbatim
Example:
    void *pResponse=NULL;
    Cortex_Request("GetContextFrameRate", &pResponse, sizeof(void*));
    fFrameRate = *(float*)pResponse;
\endverbatim 
 *
 * \return RC_Okay, RC_TimeOut, RC_NotRecognized, RC_GeneralError
*/
DLL int Cortex_Request(char* szCommand, void** ppResponse, int *pnBytes);  // Friendly extendable command function.


//==================================================================

/**   This function sends a Sky command to Cortex and returns a response.
 *
 * \param szCommand - The Sky command, including arguments for Cortex to execute.
 * \param msTimeout - The amount if time in milliseconds to wait for a response from Cortex
 *
 \verbatim
Example:
    sSkyReturn *returnValue = Cortex_SkyCommand("swCapture_Load("MyCapture1.cap", True))
	if(returnValue->ReturnCode == RC_Okay)
	{
		//process result
	}
	else
	{
		//process error
	}
\endverbatim 
 *
 * \return The result of the Sky command. The sSkyReturn::ReturnCode member needs to be checked
 * to ensure that the command was executed successfully. This is indicated with a return value of
 * RC_Okay. A value other than RC_Okay indicates failure to execute the command. If the command
 * executes, sSkyCommand::ReturnType and sSkyCommand::ReturnData contain the return value of the command.
 * If the command failes to execute these will contain more information about why the command was not executed.
 * The returned pointer points to memory internal to the Cortex_SDK.dll and should not be deleted.
 */
DLL sSkyReturn *Cortex_SkyCommand(char *szCommand, int msTimeout);

//==================================================================

/**   This function queries Cortex for its set of tracking objects.
 *
 *  \return sBodyDefs* - This is a pointer to the internal storage of
 *                       the results of the latest call to this function.
 *
 *  \sa Cortex_FreeBodyDefs
*/
DLL sBodyDefs*     Cortex_GetBodyDefs();      // The description of what we are tracking.

//==================================================================

/** This function frees the memory allocated by Cortex_GetBodyDefs
 *
 *  The data within the structure is freed and also the structure itself.

 * \param pBodyDefs - The item to free.
 *
 * \return RC_Okay
*/
DLL int Cortex_FreeBodyDefs(sBodyDefs* pBodyDefs);

//==================================================================

/** This function polls Cortex for the current frame
 *
 *  The SDK user has the streaming data available via the callback function.
 *  In addition, this function is available to get a frame directly.
 *
 *  Note: Cortex considers the current frame to be the latest LiveMode frame completed or,
 *        if not in LiveMode, the current frame is the one that is displayed on the screen.
 *
 * \return sFrameOfData
*/
DLL sFrameOfData*  Cortex_GetCurrentFrame();  // Can POLL for the current frame.

//==================================================================

/** This function copies a frame of data.
 *
 *  The Destination frame should start initialized to all zeros.  The CopyFrame
 *  and FreeFrame functions will handle the memory allocations necessary to fill
 *  out the data.
 *
 * \param pSrc - The frame to copy FROM.
 * \param pDst - The frame to copy TO
 *
 * \return RC_Okay, RC_MemoryError
*/
DLL int Cortex_CopyFrame(const sFrameOfData* pSrc, sFrameOfData* pDst);  // Allocates or reallocates pointers

//==================================================================

/** This function frees memory within the structure.
 *
 *  The sFrameOfData structure includes pointers to various pieces of data.
 *  That data is dynamically allocated or reallocated to be consistent with
 *  the data that has arrived from Cortex.  To properly use the sFrameOfData
 *  structure, you should use the utility functions supplied.  It is possible
 *  to reuse sFrameOfData variables without ever freeing them.  The SDK will
 *  reallocate the components for you.
 *
 * \param pFrame - The frame of data to free.
 *
 * \return RC_Okay
*/
DLL int Cortex_FreeFrame(sFrameOfData* pFrame);

//==================================================================

/** This function pushes a skeleton definition to Cortex.
 *
 *  A skeleton, defined in an animation package can be used to start
 *  a skeleton model definition in Cortex.  The hierarchy and starting
 *  pose can come from the animation package.  The rest of the details
 *  of the skeleton get filled out in the Cortex interface.  The parameters
 *  to this function match the parameters defining the HTR data that
 *  normally gets sent through the SDK2.
 *
 * \param pHierarchy - The number of segments, their names and parent child
                       relationships.
 * \param pFrame - One frame of HTR data dimensioned according to the number
 *                 of segments defined in the pHierarchy parameter.
 *
 * \return - RC_Okay, RC_NetworkError
*/
DLL int Cortex_SendHtr(sHierarchy *pHierarchy, tSegmentData *pFrame);    // Push a skeleton definition to Cortex

//DLL int Cortex_SetMetered(bool bActive, float fFixedLatency);

//==================================================================
// Euler angle utility functions
//==================================================================

#define ZYX_ORDER 1
#define XYZ_ORDER 2
#define YXZ_ORDER 3
#define YZX_ORDER 4
#define ZXY_ORDER 5
#define XZY_ORDER 6

// Special rotation orders
#define XYX_ORDER 7
#define XZX_ORDER 8
#define YZY_ORDER 9
#define YXY_ORDER 10
#define ZXZ_ORDER 11
#define ZYZ_ORDER 12


//==================================================================

/** This function constructs a rotation matrix from three Euler angles.
 *
 *  This function and its inverse are utility functions for processing
 *  the HTR rotations we send in each frame of data. We send Euler angles
 *  in ZYX format (some interpretations would call it XYZ). Using these
 *  conversion utilities should protect against any misinterpretations.
 *
 * \param matrix - 3x3 rotation matrix.
 * \param iRotationOrder - one of:
 *
 *        ZYX_ORDER
 *        XYZ_ORDER
 *        YXZ_ORDER
 *        YZX_ORDER
 *        ZXY_ORDER
 *        XZY_ORDER
 *
 * \param angles - the angles in degrees.
 *
 */
DLL void  Cortex_ConstructRotationMatrix(
        double angles[3],
        int iRotationOrder,
        double matrix[3][3]);

//==================================================================

/** This function decodes a rotation matrix into three Euler angles.
 *
 *  This function and its inverse are utility functions for processing
 *  the HTR rotations we send in each frame of data. We send Euler angles
 *  in ZYX format (some interpretations would call it XYZ). Using these
 *  conversion utilities should protect against any misinterpretations.
 *
 * \param matrix - 3x3 rotation matrix.
 * \param iRotationOrder - one of:
 *
 *        ZYX_ORDER
 *        XYZ_ORDER
 *        YXZ_ORDER
 *        YZX_ORDER
 *        ZXY_ORDER
 *        XZY_ORDER
 *
 * \param angles - the angles in degrees.
 *
*/
DLL void  Cortex_ExtractEulerAngles(
        double matrix[3][3],
        int    iRotationOrder,
        double angles[3]);



#ifdef  __cplusplus
}
#endif

#endif
