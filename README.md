# [Glacier](http://www.glaciersecurity.com) Voice

[Glacier](http://www.glaciersecurity.com) Voice is a free and open source VoIP and video softphone based on the SIP protocol, and that is based on [Linphone](http://www.linphone.org/).

## Description

Glacier Voice is free to download and use (thanks to Belledonne Communications and the GPLv2 license). However, the changes made to the Linphone base product were intended to optimize Glacier Voice for use with the full set of Glacier Security services, so Glacier Voice may not be the best choice for those looking for a one size fits all solution. For a more general iOS SIP client, see [Linphone](http://www.linphone.org).

[Glacier Security](http://www.glaciersecurity.com) is a full-service provider of secure, end-to-end encrypted, and anonymous communication solutions for enterprise and government. Our cloud based immutable infrastructure is launched automatically for each customer leveraging concepts of Department of Homeland Security’s Moving Target Defense project. Glacier controls change across multiple system dimensions in order to increase uncertainty for attackers, reduce their window of opportunity, increase the costs of their attack efforts, and keep end user devices anonymous.

Because Glacier services typically run within a private network, numerous assumptions were purposefully made to optimize and simplify usage for this specific scenario. Some of these design choices are not recommended for use outside of a Glacier network.

Note: Glacier Voice is based on the free and open source project Belledonne Communications [Linphone](http://www.linphone.org), however Glacier Security nor any of Glacier Security’s partners, distributors, promoters or service providers are affiliated with Belledone Communications or their users.


# Building and customizing the SDK

Note: Many of the instructions, directories, and files reference Linphone for iPhone because Glacier Voice is based on [Linphone-iphone](https://github.com/BelledonneCommunications/linphone-iphone).

Glacier Voice depends on liblinphone SDK. This SDK is generated from makefiles and shell scripts.

 Steps to customize the liblinphone SDK options are:

 1. Install [HomeBrew, a package manager for OS X](http://brew.sh) (MacPorts is supported but deprecated). For instance: /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
 2. 'git submodule sync && git submodule update --init --recursive'
 3. Install Linphone dependencies: `./prepare.py`
 4. Reorder your path so that brew tools are used instead of Apple's ones which are obsolete: `export PATH=/usr/local/bin:$PATH`
 5. Build SDK: `./prepare.py -c && ./prepare.py && make`
 6. 'pod repo update'
 7. Install needed CocoaPods: 'pod install'


## Additional Build Steps
Next you'll need to fill in your environment-specific data. Open the Voice.xcworkspace file in xCode. Fill in appropriate values in `Secrets.plist` in Settings/InAppSettings.bundle



## Licensing: GPL third parties versus non GPL third parties

This SDK can be generated in 2 flavors:

* GPL third parties enabled means that liblinphone includes GPL third parties like FFmpeg. If you choose this flavor, your final application **must comply with GPL in any case**. This is the default mode.

* NO GPL third parties means that Glacier Voice will only use non GPL code except for `liblinphone`, `mediastreamer2`, `oRTP` and `belle-sip`. If you choose this flavor, your final application is **still subject to GPL except if you have a [commercial license for the mentioned libraries](http://www.belledonne-communications.com/products.html)**.
 To generate the liblinphone multi arch SDK without GPL third parties, invoke:

        ./prepare.py -DENABLE_GPL_THIRD_PARTIES=NO -DENABLE_FFMPEG=NO [other options] && make



## Upgrading your iOS SDK

Simply re-invoking `make` should update your SDK. If compilation fails, you may need to rebuilding everything by invoking:

        ./prepare.py -c && ./prepare.py [options] && make

# Building the application

After the SDK is built, just open the Voice.xcworkspace project file with Xcode, and press `Run`. Do not open the Voice.xcodeproj file because we are using CocoaPods.

## Note regarding third party components subject to license

 The liblinphone SDK is compiled with third parties code that are subject to patent license, specially: AMR, SILK G729 and H264 codecs.
 Linphone controls the embedding of these codecs by generating dummy libraries when there are not available. You can enable them using `prepare.py`
 script (see `-DENABLE_NON_FREE_CODECS=OFF` option). Before embedding these 4 codecs in the final application, **make sure to have the right to do so**.
