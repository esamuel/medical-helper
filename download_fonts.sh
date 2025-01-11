#!/bin/bash

# Create fonts directory if it doesn't exist
mkdir -p assets/fonts

# Download Roboto fonts
curl -L "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf" -o assets/fonts/Roboto-Regular.ttf
curl -L "https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf" -o assets/fonts/Roboto-Bold.ttf
