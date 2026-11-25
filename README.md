# Homebrew tap for p3

[p3](https://github.com/MrLuis/p3) is a Pascal compiler built on LLVM
(ISO 7185, Turbo/Free Pascal and Object Pascal dialects).

```sh
brew install mrluis/p3/p3
```

or `brew tap mrluis/p3`, then `brew install p3`.

The formula builds p3 against Homebrew's LLVM 23 and installs the compiler,
its runtime and its unit library. Programs are linked with the system's C
compiler (the Command Line Tools on macOS).

Bottles are built by this repository's CI (`brew test-bot`) for the macOS
versions and Linux listed in `.github/workflows/tests.yml`; elsewhere the
formula builds from source.

## Updating the formula

For a new p3 release, open a pull request that changes `url` and `sha256`
in `Formula/p3.rb` (`brew bump-formula-pr --url=... mrluis/p3/p3`). When
its checks pass, run the `brew pr-pull` workflow with the pull request's
number: it uploads the bottles and merges.
