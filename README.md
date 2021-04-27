# [Glacier](http://www.glaciersecurity.com) Voice

[Glacier](http://www.glaciersecurity.com) Voice is a free and open source VoIP softphone based on the SIP protocol, and that is based on [Linphone](http://www.linphone.org/).

## Description

Glacier Voice is free to download and use (thanks to Belledonne Communications and the GPLv3 license). However, the changes made to the Linphone base product were intended to optimize Glacier Voice for use with the full set of Glacier Security services, so Glacier Voice may not be the best choice for those looking for a one size fits all solution. For a more general iOS SIP client, see [Linphone](http://www.linphone.org).

[Glacier Security](http://www.glaciersecurity.com) is a full-service provider of secure, end-to-end encrypted, and anonymous communication solutions for enterprise and government. Our cloud based immutable infrastructure is launched automatically for each customer leveraging concepts of Department of Homeland Security’s Moving Target Defense project. Glacier controls change across multiple system dimensions in order to increase uncertainty for attackers, reduce their window of opportunity, increase the costs of their attack efforts, and keep end user devices anonymous.

Because Glacier services typically run within a private network, numerous assumptions were purposefully made to optimize and simplify usage for this specific scenario. Some of these design choices are not recommended for use outside of a Glacier network.

Note: Glacier Voice is based on the free and open source project Belledonne Communications [Linphone](http://www.linphone.org), however Glacier Security nor any of Glacier Security’s partners, distributors, promoters or service providers are affiliated with Belledonne Communications or their users.


# Building the application

If you don't have CocoaPods already, you can download and install it using :
```
    sudo gem install cocoapods
```

- Install the app's dependencies with cocoapods first:
```
    pod install
```
  It will download the linphone-sdk from our gitlab repository so you don't have to build anything yourself.
- Then open `Voice.xcworkspace` file (**NOT Voice.xcodeproj**) with XCode to build and run the app.


## Additional Build Steps
Next you'll need to fill in your environment-specific data. Open the Voice.xcworkspace file in xCode. Fill in appropriate values in `Secrets.plist` in Settings/InAppSettings.bundle

Glacier currently uses AWS Amplify to facilitate single signon model across the platform of Glacier applications. As part of this, the AWS Cognito and S3 IDs need to be added to the Secrets.plist file. Single signon also makes use of AWS Amplify, and thus to be used in this way would need to setup Amplify and a related backend environment. See AWS Amplify documentation.


## License

Copyright © Glacier Security

Glacier Voice is available under a [GNU/GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) license, for free (open source). Please make sure that you understand and agree with the terms of this license before using it (see LICENSE file for details).


# Enabling crashlythics

We've integrated Crashlythics into Voice, which can automatically send crash reports. It is disabled by default.
To activate it:

- Replace the GoogleService-Info.plist for this project with yours (specific to your crashlytics account).

- Rebuild the project:
```
    USE_CRASHLYTHICS=true pod install
```

- Then open `Voice.xcworkspace` with Xcode to build and run the app.

# Quick UI reference

- The app is contained in a window, which resides in the MainStoryboard file.
- The delegate is set to LinphoneAppDelegate in main.m, in the UIApplicationMain() by passing its class
- Basic layout:

        MainStoryboard
                |
                | (rootViewController)
                |
            PhoneMainView ---> view |--> app background
                |                   |
                |                   |--> statusbar background
                |
                | (mainViewController)
                |
            UICompositeView : TPMultilayout
                        |
                        |---> view  |--> statusBar
                                    |
                                    |--> contentView
                                    |
                                    |--> tabBar


When the application is started, the phoneMainView gets asked to transition to the Dialer view or the Assistant view.
PhoneMainView exposes the -changeCurrentView: method, which will setup its
Any Voice view is actually presented in the UICompositeView, with or without a statusBar and tabBar.

The UICompositeView consists of 3 areas laid out vertically. From top to bottom: StatusBar, Content and TabBar.
The TabBar is usually the UIMainBar, which is used as a navigation controller: clicking on each of the buttons will trigger
a transition to another "view".
