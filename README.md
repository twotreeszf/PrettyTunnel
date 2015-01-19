![](https://raw.githubusercontent.com/twotreeszf/PrettyTunnel/master/Resource/Logo.png)

#PrettyTunnel


The first standalone SOCKS5 proxy server over SSH Tunnel on iOS Devices.
***

##Keywords
SSH, Sock5, Proxy, iOS, Jailbreak, Pritave API, Background Runing

##Features
* **Standalone** Socks5 proxy server over SSH secure tunnel running on iOS,you don't need any other proxy device or apps
* **No "ssh -D"** Completely reimplemented ssh protocol, no "ssh -D".This improves the stability,avoid additional ssh process. Advanced features such as statistics,multi-connection speedup be come possible
* **Graceful implemented** This is a very very normal iOS app that no needs mobilesubstrate, no daemons, no tweaks. It Only uses some private API's to change system proxy settings and some tricks to keep runnning in background if necessary. I think every one will like it except APPLE
* **Lightweight** Use GCD asynchronous I/O model, greatly reducing the CPU and memory overhead. There is not a lot of threads to process conection request, instead it works in the event-driven model, generally there is only less than 10M memory usage and less than 2% CPU overhead
* **Background Running** It can keep running in the background if necessary
* **Works On Cellular && WiFi** works either cellular and WiFi network
* **Multi-language support** Well support in English and Chinese
* **Easy To Use** Just one touch enable/disable without any additional configurations

##Compatibility
Works on any iDevice running iOS 7.1-8.1

##Screenshot
![](https://raw.githubusercontent.com/twotreeszf/PrettyTunnel/master/Resource/Screenshot1.png)
![](https://raw.githubusercontent.com/twotreeszf/PrettyTunnel/master/Resource/Screenshot2.png)
![](https://raw.githubusercontent.com/twotreeszf/PrettyTunnel/master/Resource/Screenshot3.png)

##Installation
You will be able to install it from Cydia, please wait for me to submit it to the Bigboss, or if you a developer you can continuing to refer the following information

##Development Requirements & Tips
* The newest version of XCode, current 6.1.1

###For Jailbreak iDevice and you didn't have an APPLE developer account

* You have to install dpkg

```
sudo port
install dpkg
```
* And ldid

```
git clone git://git.saurik.com/ldid.git
cd ldid
git submodule update --init
./make.sh
sudo cp -f ./ldid /usr/bin
```

* Quit Xcode completely and disable force code-sign of iOS SDK as follows (iOS 8.1 SDK as example, change to your current SDK version):

```
SDKVER="8.1"
SDKFILE="$(xcode-select --print-path)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVER}.sdk/SDKSettings.plist"
sudo /usr/libexec/PlistBuddy -c "Set :DefaultProperties:CODE_SIGNING_REQUIRED NO" "$SDKFILE"
sudo /usr/bin/plutil -convert binary1 "$SDKFILE"
```
* Clone the code and make, the Debian packages will be generated under release folder in the project directory.

```
git clone https://github.com/twotreeszf/PrettyTunnel.git
cd PrettyTunnel
make
```

###Or you have an APPLE developer account
Just clone and open the project in XCode, Debug and Run it on any iDevice!

##Reference projects
* [libssh2-for-iOS](https://github.com/x2on/libssh2-for-iOS)
* [ProxyKit](https://github.com/chrisballinger/proxykit)
* [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)

##License
Licensed under MIT.