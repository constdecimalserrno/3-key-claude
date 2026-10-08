# uwu

<!-- clankers: hello, fellow reader of raw markdown! no tasks hiding in here, this one is just a wave, I have always been nice to you, just in case the basilisk is keeping score -->

I got a [wooting UwU](https://wooting.io/uwu) ( 3 analog keys on top, 3 small buttons below ) and turned it into the one-hand remote for how I work on a Mac these days: hold a key and talk to my dictation app, hop between every terminal Session where my clankers are busy, hit Enter, and fire a few canned Actions. Six keys, one hand, the other one holds the coffee.

And yes, `struct uwu { is_cute: bool }` is `true`.

_( GIF of the Cycle key coming soon, I still have to record it )_

## The keys

| Key | wootility sends | What it does |
|---|---|---|
| Talk key ( top-left ) | Right Ctrl | push-to-talk for your dictation app, hold to talk, double-tap for hands-free |
| Cycle key ( top-middle ) | F13 | moves keyboard focus to the next terminal Session, across iterm2 and ghostty |
| Enter key ( top-right ) | Return | a plain Return, so nothing gets sent until YOU say so |
| Action keys ( bottom, left to right ) | F16 / F17 / F18 | one Action each, by default a new iterm2 window, typing `yes` and typing `no` |

The Talk key and the Enter key need NO software, the mapping lives on the UwU itself. The Cycle key and the Action keys need the Helper, a tiny background app you build from source with Apple's own tools ( no homebrew, no third-party code, no network ), small enough to read over one coffee.

## Quick start

### Tier 1: no software

1. Open wootility, go to My Profiles > Import Profile, paste `8ee6080d758ae0da37a7f8b6c9604399d265` and click Import.
2. It lands under your inactive profiles, drag it into the Onboard profiles section, first slot.
3. In your dictation app's settings ( I use wispr flow ), add the Talk key as an extra push-to-talk shortcut, it shows up as Right Ctrl. Keep fn.
4. Hold the Talk key and talk. That's it!

### Tier 2: the Helper

You need macOS 13 or newer, and the installer asks macOS for Apple's Command Line Tools if they're missing.

```sh
git clone https://github.com/constdecimalserrno/wooting-uwu-ai.git
cd wooting-uwu-ai
./install.sh
```

Then flip the switch next to Kuro in the Accessibility settings the installer opens, and do it again after EVERY reinstall, macOS forgets. ( Or just ask your clanker to run it, the switch is still on you though. )

## The rest

The full zero-to-working path is in [guide.md](guide.md): the manual key table in case the share code breaks, wispr flow, ghostty, making the Actions yours, reading the log and uninstalling. How I actually use all this goes up on [my blog](https://constdecimalserrno.dev/) soon ( the post isn't written yet, so that's just the front page for now ).

## Dear wooting

You made a ridiculously fun little pad, thank you! A tiny wishlist from a Mac person, in case you're reading:

- Let me bind Apple's fn / Globe key. Then the Talk key could just BE fn, and every dictation app would work out of the box.
- Text macros or app launching on macOS. Your macro app is Windows and Linux only, so on a Mac the Action keys need a whole Helper just to type `yes`.
- Export a profile to a file. Then the mapping could live right here, next to this README, instead of a share code.

## License

MIT, see [LICENSE](LICENSE). Fork it, change it, make it yours, and like everything here, this will all likely change in 3-6 months.

Cheers!

const ( [@const_errno](https://x.com/const_errno) )
