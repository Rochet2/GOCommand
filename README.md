# GOCommand
This is a **pure addon** version of GOMove. It also has new functionality to rotate objects by pitch and roll in addition to orientation.
It does not require any server modification, so you can use it basically on any TC 3.3.5 server.

# installation
- Download the dependencies and add the `Lib*` folders to your client `AddOns` folder: https://github.com/TrinityCore/LibTrinityCore-1.0
- Download GOCommand and add the `GOCommand` folder to your client `AddOns` folder
- Log in and enable all of the addons installed before entering world.

# Background
I never finished the addon, so the UI is shit and so. It does have new features compared to the old GOMove.
I had this code just on my disk for the last 2-3 years collecting dust, so since it was asked multiple times I decided to just fix it up to a working condition and cut the non working parts.
The addon is made for 3.3.5 TrinityCore.
It requires the server to support the addon protocol: https://github.com/TrinityCore/TrinityCore/pull/20074 so it will not work on other cores than TC unless they port that.

# Features
- Move objects with **scrollwheel** instead of clicking buttons. You will need to hold cursor on top of an input and roll your scrollwheel.
- Pressing shift, ctrl or alt while scrolling will affect the speed of moving, so you do not need to constantly change the moving speed.
- See tooltips by hovering over buttons and inputs.
- Rotate objects in all axes.
- Copy/cut groups of objects and paste them in same form elsewhere.
- Load object dimensions. You can now move EXACTLY by an object's DBC dimensions.
- Move objects up, down, left, right.
- Moving can now be chosen to be relative to player orientation, the object itself or compass.
- You can now rotate multiple objects around the player or around their center of mass.
- Delete groups of objects.
- Floor or ground groups of objects.
- Use player x, y, z or orientation coordinate.
- Move objects to player location.
- Duplicate objects.
- Select closest object, select by name part, select by range, select by entry, select by guid.
- Teleport to object.
- You can select entries in the selection list by hovering over the rows and pressing CTRL+SHIFT to unselect and CTRL+SHIFT+ALT to select rows.

# Media
![Image of UI](https://i.imgur.com/VenjE0x.png "UI in full glory")
[![Video of moving multiple objects](http://img.youtube.com/vi/ty8qzmuG1cQ/0.jpg)](http://www.youtube.com/watch?v=ty8qzmuG1cQ)
[![Video of rotating an object in different axes](http://img.youtube.com/vi/phd5xtFyCao/0.jpg)](http://www.youtube.com/watch?v=phd5xtFyCao)
