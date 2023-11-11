#!/bin/bash

rclone --cache-dir=/tmp/default -v --stats=10s --vfs-cache-mode writes mount default:/ /mnt/default
