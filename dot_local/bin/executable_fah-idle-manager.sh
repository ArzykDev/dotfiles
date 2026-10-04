#!/bin/bash

swayidle -w \
    timeout 300 'busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto org.freedesktop.login1.Session SetIdleHint b true' \
    resume 'busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto org.freedesktop.login1.Session SetIdleHint b false'
