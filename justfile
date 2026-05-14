# justfile for esp8266_sdk maintenance

set shell := ["bash", "-c"]
tmp_dir := "vendor_update_tmp"
sdk_branch := "release/v3.4"

# Update all vendored dependencies to a stable release
update-all:
    @echo "Updating to stable SDK branch: {{sdk_branch}}..."
    rm -rf {{tmp_dir}}
    # Clone the SDK with the specific stable branch and all submodules at their tested commits
    git clone --depth 1 --recursive --branch {{sdk_branch}} https://github.com/espressif/ESP8266_RTOS_SDK.git {{tmp_dir}}
    # Sync the files into vendor/ folder, excluding .git metadata
    rsync -av --delete --exclude='.git/' {{tmp_dir}}/ vendor/
    rm -rf {{tmp_dir}}
    @echo "Update complete. Please verify compilation of test_app."

# Clean up any update artifacts
clean:
    rm -rf {{tmp_dir}}
