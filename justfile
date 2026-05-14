# justfile for esp8266_sdk maintenance

set shell := ["bash", "-c"]
tmp_dir := "vendor_update_tmp"

# Update all vendored dependencies
update-all: update-sdk update-components

# Update the main ESP8266_RTOS_SDK
update-sdk:
    @echo "Updating main SDK..."
    rm -rf {{tmp_dir}}
    git clone --depth 1 https://github.com/espressif/ESP8266_RTOS_SDK.git {{tmp_dir}}
    # Move files, excluding the components that we manage separately as sub-repositories
    rsync -av --exclude='.git/' --exclude='components/lwip/lwip' --exclude='components/mbedtls/mbedtls' --exclude='components/json/cJSON' --exclude='components/mqtt/esp-mqtt' --exclude='components/coap/libcoap' {{tmp_dir}}/ vendor/
    rm -rf {{tmp_dir}}

# Update all sub-components (LwIP, mbedTLS, etc.)
update-components: update-lwip update-mbedtls update-cjson update-mqtt update-coap

update-lwip:
    @echo "Updating LwIP..."
    rm -rf {{tmp_dir}}
    git clone --depth 1 https://github.com/espressif/esp-lwip.git {{tmp_dir}}
    rsync -av --exclude='.git/' {{tmp_dir}}/ vendor/components/lwip/lwip/
    rm -rf {{tmp_dir}}

update-mbedtls:
    @echo "Updating mbedTLS..."
    rm -rf {{tmp_dir}}
    git clone --depth 1 https://github.com/espressif/mbedtls.git {{tmp_dir}}
    rsync -av --exclude='.git/' {{tmp_dir}}/ vendor/components/mbedtls/mbedtls/
    rm -rf {{tmp_dir}}

update-cjson:
    @echo "Updating cJSON..."
    rm -rf {{tmp_dir}}
    git clone --depth 1 https://github.com/DaveGamble/cJSON.git {{tmp_dir}}
    rsync -av --exclude='.git/' {{tmp_dir}}/ vendor/components/json/cJSON/
    rm -rf {{tmp_dir}}

update-mqtt:
    @echo "Updating MQTT..."
    rm -rf {{tmp_dir}}
    git clone --depth 1 https://github.com/espressif/esp-mqtt.git {{tmp_dir}}
    rsync -av --exclude='.git/' {{tmp_dir}}/ vendor/components/mqtt/esp-mqtt/
    rm -rf {{tmp_dir}}

update-coap:
    @echo "Updating libcoap..."
    rm -rf {{tmp_dir}}
    git clone --depth 1 https://jihulab.com/esp-mirror/obgm/libcoap.git {{tmp_dir}}
    rsync -av --exclude='.git/' {{tmp_dir}}/ vendor/components/coap/libcoap/
    rm -rf {{tmp_dir}}

# Clean up any update artifacts
clean:
    rm -rf {{tmp_dir}}
