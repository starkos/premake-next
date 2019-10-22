<p align="center">
  <a href="https://premake.github.io/" target="blank"><img src="https://premake.github.io/premake-logo.png" height="200" width="200" alt="Premake" /></a>
</p>

# Premake Next

An exploratory take on new ideas and approaches for the [Premake build tool](https://premake.github.io/).

## What’s going on here?

I’m trying out new ideas for Premake (see _[“Why “next”?](#why-next),_ below).

Current status: I’ve ripped out enough of Premake5 to bootstrap and launch system and user scripts, and given it all a good polish. I’m now diving into the truly novel stuff, starting with configuration scripting and storage.

See [Changes Since v5](https://github.com/starkos/premake-next/blob/master/docs/changes-since-v5.md) for a list of the improvements made so far.

## Why “next”?

While working to fix some of Premake’s more fundamental issues I’ve come to the conclusion that it’s configuration system—the heart of the program which stores and queries the scripted project settings—is fatally flawed. It’s still using the same Visual Studio-centric models that I set out in Premake 1.0, and they’ve hit the limits of what they are able to express. In particular:

- It's too inflexible, and can't represent all of the possible formats that it needs to support (Makefile-style projects; anything that supports complex configuration at the workspace level)

- It can't handle toolsets which support multiple platforms in one project, like [Code::Blocks](http://www.codeblocks.org)

- It doesn't scale well to large combinations of platform/architecture/toolset/etc.

- There's no easy way to "roll up" common configuration at the workspace or project level, needed for modern Xcode and Makefile projects

- It does a _terrible_ job handling file level configurations

- The code is excessively complex and difficult to extend and change

- We're hitting the performance limits of the approach, and performance is only so-so at best

I think I know how to fix all of this, but I don’t see how to get there from where we are without breaking…well, pretty much everything. I don’t really want to break everything, and I don’t think you want me to break everything either.

I’m using this space to develop a vertical slice of how I think things should be, so we have something real that other people can see and touch and reason about. When that’s done, either a path will be found to fold this back in Premake5, or (more likely IMHO) we’ll create a `v6.x` branch in [premake-core][pc] and full steam ahead on Premake6.

## I need this, how can I make it go faster?

I hear ya. Boy, do I ever.

Contributions here are welcome and appreciated, especially bug fixes, but please sync up with me to make sure we’re on the same page before tackling anything big.

Otherwise, the best way to speed things up is to [contribute to our OpenCollective][oc]. Every hour I don’t have to spend hunting down client work is an hour I can spend improving Premake.

## Can we talk about this?

The easiest way to start a discussion is to open an issue here. Keep in mind this is a temporary repository so don’t leave anything important lying around; use [premake-core][pc] for that. I can also be reached at [@premakeapp][tw].

## What about toolsets/usages/other issues?

There are definitely other big questions to tackle, but I think this is the most fundamental and, done right, makes solving those other issues easier.

[oc]: https://opencollective.com/premake
[pc]: https://github.com/premake/premake-core
[tw]: https://twitter.com/premakeapp
