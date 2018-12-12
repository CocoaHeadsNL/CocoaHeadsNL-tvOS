# CocoaHeadsNL-tvOS
Our very own Apple TV App

## About this app

**Why a tvOS app?** We're a community of mostly cocoa developers... so could you imagine we wouldn't? 

**Why open source it?** We are a non-profit organisation and organise our monthly meetup to share ideas, learn from each other and meet other developers. Keeping it closed seemed out of place.

**How do we see this working?** We used an [open source license](LICENSE.md) to promote sharing for non-commercial use and educational purposes.

In case you have any ideas, suggestions or additions, just get in contact so you can see what is happening already. We still got some things on our wishlist.

Our email: [foundation@cocoaheads.nl](mailto:foundation@cocoaheads.nl)

## Project structure

CocoaHeadsNL TV contains two important components:

- The tvOS app implementation
- The TVML code in the `webcontent` direcory.

## Running in Xcode

You can run the project locally on your own machine in Xcode just fine. It will however still load all content from a webserver (at Amazon Web Services). In order to make changes and test them locally you need a local webserver that serves content from the `webcontent` directory in the project. The easiest way to do this is to open a terminal window and change the current directory to the `webcontent` directory of the project on your local disk. Then execute the following command:

```bash
ruby -run -ehttpd . -p9001
```

This will start a simple local HTTP server that serve content from the current directory at `http://localhost:9001`.

In order for the tvOS app to load the content from that location you need to modify the `AppDelegate.swift` file. Please find the following line in the code:

```swift
        //tvContentURL = "http://localhost:9001/"
```

Uncomment the code so that it reads:

```swift
        tvContentURL = "http://localhost:9001/"
```

You can now run the tvOS from Xcode and it will load all content from your local machine. All video files are still loaded from Amazon Web Services.

## Contributions

Please note that we consider all ownership of contributions made to this project to automatically transfer to Stichting CocoaHeadsNL. If you do not agree to this, do not contribute.

Also note, any contributions we receive should be allowed to be transferred to Stichting CocoaHeadsNL. If you make contributions and at a later stage ownership of said contributions are not lawfully transfered to our possesion, you as a contributor are considered liable for this.

The above statement may sound harsh, but basically if you write original code on your own or legally alloted time and use open source components with compatible licenses: You are perfectly fine.

As maintainers of this project we do actively try and guide contributors through these hurdles, we want to work with our community to make this project a great success.

All contributors to this project are listed here: [contributors](https://github.com/CocoaHeadsNL/CocoaHeadsNL-tvOS/graphs/contributors)
