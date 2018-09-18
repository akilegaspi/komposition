# FastCut

**High-Productivity Video and Audio Editing**

## Motivation

Commercial video editing software is ill-suited to my desired
screencast editing workflow. I'm not interested in all the low-level
control it gives -- I want something that supports my workflow, and
nothing more. *FastCut* is that program (or will be!)

TODO: proper motivation text.

## Concepts

### Timeline Structure

A FastCut *project* has a *timeline*, where you place your video and
audio parts you want to render to a video file. The timeline is a
tree structure of *compositions*, and FastCut enforces what kinds of
compositions can occur within other compositions:

* A timeline contains one or more child *sequences*.
* A sequence contains one or more child *parallels*, where each child
  is played sequentially in order.
* A parallel contains a video track and an audio track, where the
  video and audio tracks are played in parallel (simultaneously). The
  longest track defines the length of the parallel.

Sequences and parallels are used to structure logical groups of video
and audio parts into cohesive units, and to synchronize the start of
video and audio. For example, if you want video clip *v1* to start at
exactly the same time as audio clip *a1*, put them both in a parallel.

### Navigation

The *focus* is where you are currently focusing within in the
timeline, and is the basis for all commands related to the
timeline. If you *delete*, you will delete whatever composition, video
part, or audio part, that is currently focused, given that the
operation is allowed.

The focus is moved by using
<kbd>h</kbd>/<kbd>j</kbd>/<kbd>k</kbd>/<kbd>l</kbd> keys, familiar to
Vim users. Many other commands are also bound to keys. Press
<kbd>?</kbd> in FastCut to see what commands are available in the
current mode.

### Importing

TODO

### Rendering

TODO

## Build Instructions

This project can be built using Nix or Stack.

TODO: instructions.

## Roadmap

* 0.1.0
    - [X] Timeline UI
    - [X] Basic library view
    - [ ] Timeline auto-scroll
    - [X] Consistent single theme
    - [X] Video import without auto-splitting
    - [X] Audio import without auto-splitting
    - [X] Import and auto-split video
    - [ ] Import and auto-split audio
    - [X] Sequence and parallel structure of limited depth
    - [X] Support for key and widget events
    - [X] Preview for video clips
    - [X] Help windows showing key bindings
    - [ ] Rescale video clips when rendering
    - Commands
        - [X] Insert (append, prepend)
        - [X] Split sequence
        - [X] Delete
        - [X] Insert into empty parallel
        - [ ] Insert composition (sequence, parallel)
    - [X] Offline video rendering, including hold-frame
    - [X] Offline rendering including audio
* 0.2.0
    - [ ] Image (still frame) import
    - [ ] Save/open project
    - [ ] Script/subtitle split
    - [ ] Subtitle editing
    - [ ] Command fuzzy completion
    - [ ] Undo
    - [ ] Yank/paste
    - [ ] Preview for video gaps
    - [ ] Preview for audio clips
    - [ ] Preview for audio gaps

## License

Copyright 2018 Oskar Wickström
