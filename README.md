# AlohaGIF

[Website](http://www.alohagif.com)

![GIF with quick demo](Resources/demo.gif)

Funny moments? Want to share it as a GIF, but you are worried that you will lose speech from video? Aloha will scan sound and attach spoken words as subtitles that you can change color, font and style. Have fun!

## Background of the app

I played with the [Clips](https://itunes.apple.com/us/app/clips/id1212699939?mt=8) app for a while and wanted to import my recorded videos, but there was no such function. So, hey, it might be interesting challenge to mess around with Siri and AVFoundation.

## Features

* Speech detection in recorded video
* Subtitles overlay with one word after another or revealing whole sentence
* Adjusting subtitles position, font and color
* Importing recorded videos for speech detection
* Crop and compress videos from camera roll
* Export to GIF
* Share via iOS or on Messenger

Keep in mind that most features are far from perfection - text often does not fit, speech detection works only on crystal clear voice, etc.

## Code

I've written this app just for fun, so the code is kinda messy - few globals here and there, magic numbers, and so on. But overall - is okay-ish, hence it might be useful for someone.

## Lovely libraries that I used

* [Promise](https://github.com/khanlou/Promise)
* [Regift](https://github.com/matthewpalmer/Regift)
* [ImagePicker](https://github.com/hyperoslo/ImagePicker/)
* [FBSDKMessengerShareKit](https://github.com/facebook/facebook-ios-sdk/tree/master/FBSDKMessengerShareKit)
* [ALLoadingView](https://github.com/ALoginov/ALLoadingView)
* [Some sample from Apple](https://developer.apple.com/library/content/samplecode/AVCam/Introduction/Intro.html#//apple_ref/doc/uid/DTS40010112)
* [SwiftyOnboard](https://github.com/juanpablofernandez/SwiftyOnboard)
* [CHIPageControl](https://github.com/ChiliLabs/CHIPageControl)


## Tokens

I'm using SwiftyBeaver and FB Messenger - you can set your own credentials in ```SwiftyBeaverTokens.plist``` and in ```Info.plist``` for FacebookAppID.

## Contributing

I'm not expecting any contributions, but if you have some interesting idea in mind or just want to point out the bug(there are _plenty_) - just send a pull request.

## License

Copyright 2017 Michal Pyrka.

MIT License. See [LICENSE](LICENSE).
