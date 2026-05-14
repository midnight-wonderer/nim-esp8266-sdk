# config.nims
import os, strutils

# Include the centralized library configuration
# When using as a dependency:
# const sdkPath = gorge("nimble path esp8266_sdk").strip()
# if sdkPath != "":
#   include sdkPath / "src/config_helper.nims"

# For local examples in this repo:
include "../../src/config_helper.nims"
