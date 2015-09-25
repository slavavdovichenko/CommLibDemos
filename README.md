CommLibDemos
===============

Communication Library for iOS provides the classes and protocols for communication via rtmp/rtmps.
It allows the iOS devices to interact with the media servers: Adobe FMS, Wowza MS, Red5, crtmp, rtmpd.
WeborbClient is used for communication via http/https. See Communication Library for iOS User Guide.

Requirements
The library imposes the following requirements on the iOS applications utilizing it:
1. iOS Deployment Target - 7.1 or above;
2. The following frameworks and libraries must be added to the list of libraries linked to the binary:
CoreData.framework, SystemConfiguration.framework, libsqlite3.tbd, libz.tbd;

Add the Libraries and Frameworks to the project

1. Choose the project target, go to Build Phases->Link Binary With Libraries, push “+”, check the following iOS frameworks and libraries: CoreData.framework, SystemConfiguration.framework, libsqlite3.tbd, libz.tbd. Push “Add” button.
2. Add CommLibiOS (CommLibOSX) folder to the your project folder.
3. Mark the project and choose File- > ”Add Files to …” menu item. In window choose the “lib” folder in the project folder. Make sure that the “Add to targets” checkbox must be checked. Push “Add” button.
4. Add the following option to the Build Settings -> Search Paths -> Library Search Paths line:

$(inherited) $(PROJECT_DIR)/lib/CommLibiOS

