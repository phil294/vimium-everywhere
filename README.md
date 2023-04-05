# Vimium Everywhere

A small experimental AutoHotkey script for system-wide keyboard navigation, compatible with **Linux** (X11) and **Windows** (partially (*edit: windows not supported right now, PR welcome*)). It's a bit like normal [Vimium](https://github.com/philc/vimium), but for any application, not just browsers.

Short demo which shows how you can press <kbd>f</kbd> and then navigate anywhere (the key history at the bottom is just for demonstration purposes):

https://user-images.githubusercontent.com/14108705/207453354-5f47356f-34f6-44c2-bee9-37cd0afd3ea6.mp4

Please note that this tool is still quite unstable and may contain bugs.

Admittedly, it's not much of an actual "Vim mode" yet, just the core feature of selecting interactive elements via keyboard. This is by far the most important thing to have though, so the name may already be justified.

## Installation

This tool was made and runs with AutoHotkey. It's a small script compatible with both [Windows AutoHotkey](https://autohotkey.com/) and [AHK_X11 Linux AutoHotkey](https://github.com/phil294/AHK_X11/).

- Linux
    - Either
        - [download the latest binary](https://github.com/phil294/vimium-everywhere/releases), **or**
        - download and install [AHK_X11](https://github.com/phil294/AHK_X11/). It's recommended you download the `ahk_x11-no-gc` version because this script may crash a lot otherwise. Then also download the file `vimium-everywhere.ahk`.
    - Start the downloaded program via double click or command line. However, this will crash every now and then, especially under heavy usage. Thus, it's recommended to do this instead:
        ```bash
        while true; do ./vimium-everywhere && break; done
        ```
        This will automatically restart the process once it crashed.
    - By default, it probably doesn't work properly, because you also need to:
        - *Important*: Enable the assistive technologies setting for your distribution. There's usually a single checkbox somewhere to be found to enable it. After enabling, you may need to reboot.
        - *Important*: Most applications need some config flag toggled so they cooperate. You'll find details in the table below.
    Once you have followed these steps, it should work great almost anywhere, like shown in the video at the top.
- Windows
    - Limited to native applications only (see table below). But where it does, it should be super fast.
    - Install [AutoHotkey](https://autohotkey.com/), then run `vimium-everywhere.ahk`.
- MacOS: Not compatible. You might want to check out [Scoot](https://github.com/mjrusso/scoot) or the closed-source apps [Shortcat](https://shortcat.app) or [Homerow](https://www.homerow.app) instead which appear to be very powerful.

Once running, it can be quit by right-clicking the icon in task/tray bar.

**Click on the 🢒 arrows instructions for the respective application type:**

Program Type | Linux | Windows
--- | --- | ---
Native Windows Apps | ❌ | ✔
Firefox | ✔ | ❌
Chromium-based browser such as<br>Chrome, Brave | <details><summary>✔</summary>Chrome needs two adjustments: 1. Set environment variable ACCESSIBILITY_ENABLED to value 1. You can e.g. enable this globally by adding another line with content ACCESSIBILITY_ENABLED=1 into the file /etc/environment and then restarting your computer. 2. Add argument --force-renderer-accessibility. You can do so by editing the program's "Desktop file", or starting it from command line and passing it there. Example to start Chrome with full support: `ACCESSIBILITY_ENABLED=1 chrome --force-renderer-accessibility`<br><br>Theoretically, you can instead also enable the accessibility options inside chrome://accessibility but this does not seem to work reliably.</details></div> | ❌
Electron-based application such as<br>VSCode, Slack, Spotify, Discord and [many more](https://www.electronjs.org/apps) | <details><summary>✔</summary>For each of those applications, you need to set the same adjustments like for Chrome (please click cell above). Some may offer a convenience settings flag too.</details> | ❌
Java application | <details><summary>✔</summary>You need to install the ATK bridge: For Debian/Ubuntu-based systems, this is `apt install libatk-wrapper-java`. For Arch Linux based ones, it's `java-atk-wrapper-openjdk8` (depending on the Java version).</details> | ❌
Gtk application | ✔ | ❌
Qt5+ application | ✔ | ❌
Old Qt4 application | <details><summary>✔</summary>In the rare case the window is an exotic, old application built with Qt4, such as some programs that haven't been maintained since 2015, you need to install `qt-at-spi`.</details> | ❌
Other things such as<br>games, Tk Guis, Wine, Steam,<br>anything exotic that doesn't support AtSpi | <details><summary>❌</summary>No chance to get them to work. For some others, according to the internet, these following environment variables may also help: `GNOME_ACCESSIBILITY=1`, `QT_ACCESSIBILITY=1`, `GTK_MODULES=gail:atk-bridge` and `QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1`. This is probably only relevant for outdated programs too, if ever.<br><br>If you're unsure about the state of some program, please open an issue so we can investigate.</details> | ❌

<sub>(this list may not be 100% accurate, please help improving it)</sub>

## Usage

In **normal mode**, the following Hotkeys are active:
Hotkey | Action
--- | ---
<kbd>f</kbd> | Show action links for current window (the main feature). Then, you can press any of the shown key sequences and confirm with <kbd>Space</kbd> or cancel with <kbd>Escape</kbd>. If the action links are somehow outdated, you can cancel and then press any key such as Ctrl to trigger a rebuild, and optionally immediately press <kbd>f</kbd> again.
<kbd>i</kbd> | Start input mode: This disables the other hotkeys and allows you to type normally.
<kbd>Escape</kbd> | End input mode
<kbd>j</kbd> | Scroll down
<kbd>k</kbd> | Scroll up

There is no settings dialog yet, so you are encouraged to adjust the ahk script to your needs, esp. given its small size. If you make substantial changes, then please, in the spirit of this project's GPL license, make your changes public, e.g. by forking this repository. Feature requests and bug reports are also welcome, just create a new issue above.

You can also change the list of exclude windows at the top of the script. For example, you might want to set it to `firefox,Google-chrome` if you are using normal [Vimium](https://github.com/philc/vimium) there, which is a lot more capable in browsers.

You can switch to **simple mode** by setting the environment variable `SIMPLE_MODE` to `1`, e.g. run it like `SIMPLE_MODE=1 ./vimium-everywhere`. Simple mode means: All magic (key press / window change detection) is removed, and only a single hotkey remains (default <kbd>Alt</kbd>+<kbd>f</kbd>) with does both building and link selection one after another. This is slower than normal mode, but is less resource hungry as there is no background activity at all, unless you press the Hotkey.

You can also change the `Hotkey` mappings in the source: For example, in simple mode, `!f` is the hotkey for showing links. `!` stands for <kbd>Alt</kbd> modifier. Other modifiers: `^` = <kbd>Ctrl</kbd>, `+` = <kbd>Shift</kbd>, `#` = <kbd>Super(Win)</kbd>, `<^>!` = <kbd>AltGr</kbd>.

## Caveats

### Linux

#### Broken links

Apart from the required application settings above (also see: [Arch Wiki](https://wiki.archlinux.org/title/Install_Arch_Linux_with_accessibility_options#Troubleshooting)), sometimes an application contains interactive elements but they are not captured by this script. Or sometimes, an action link just doesn't do anything. This can be either because the respective application author didn't do their homework or because of a bug in Vimium Everywhere or in AHK_X11. Please open an issue if you encounter any problems - might need a list of known bugs some day.

#### Speed

The internal querying of control information can be quite slow (somewhere between 0 and 3s). This problem should be eased by the normal mode's ahead of time querying feature. It doesn't seem like it can be improved much more besides that. AtSpi, the assistive interface for programs on Linux systems, simply does not expose powerful enough functions for performant access, so a deep recursive algorithm needs to be run repeatedly (internals of `WinGet,, ControlList`). Still, it works mostly alright even with several hundreds of elements. List-like elements with more than 1,000 children are skipped.

Also, the startup can take multiple seconds, so please stand by while the first `Building...` ToolTip may load. This initialization phase seems to be dependent on the amount of open windows and/or system uptime (??)

#### Required Compositor

You need to have an active window compositor running. On most systems, this is the default, but it can often be deactivated. If you cannot or don't want to use a compositor, then the script could be rewritten with `ToolTip`s instead, but this is 1. considerably slower and 2. breaks compatibility with Windows, where the maximum number of tooltips is 20. But still, it can be done, if you need it. Perhaps consider opening an issue so we can see this through.
