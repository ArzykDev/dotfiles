#!/bin/bash

dbus-monitor --session "type='signal',interface='org.freedesktop.ScreenSaver'" |
  while read x; do
    case "$x" in
      # You can call your desired script in the following line instead of the echo:
      *"boolean false"*) echo unlocked;;
    esac
  done
