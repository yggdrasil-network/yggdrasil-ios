# Yggdrasil for iOS

Requires an Apple Developer account for the App Groups and Network Extension entitlements.

You will need to provision an app group and update bundle IDs throughout the Xcode project as appropriate. You can find them all by asking `git`:

```
git grep "eu.neilalexander.yggdrasil"
```

To build, install Go 1.13 or later, and then install `gomobile`:

```
go get golang.org/x/mobile/cmd/gomobile
gomobile init
```

Clone the main Yggdrasil repository and build the `Yggdrasil.framework`:

```
git clone https://github.com/yggdrasil-network/yggdrasil-go
cd yggdrasil-go
./build -i
```

Then copy `Yggdrasil.framework` into the top-level folder of this repository and then build using Xcode.
