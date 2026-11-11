#!/bin/bash

gource -1600x1200 --title "Quick Admit" \
       --max-user-speed 500 \
       --hide progress \
       --seconds-per-day 0.05 \
       --elasticity 0.02 \
       --bloom-intensity 0.04 \
       --multi-sampling \
       --hide filenames .
