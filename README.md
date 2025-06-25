# HeyStack-NRF5X: OpenHaystack Compatible Low Power Firmware

This repository provides an alternative OpenHaystack firmware, utilizing the SoftDevice from Nordic Semiconductor for improved power efficiency. Estimates suggest this firmware can extend battery life up to three years on a CR2032 battery ([more details here](https://github.com/seemoo-lab/openhaystack/issues/57#issuecomment-841642356)). It builds on [acalatrava's firmware](https://raw.githubusercontent.com/acalatrava/openhaystack-firmware/main/README.md), with additional fixes and support for newer nRF5x devices and SDKs.

## Supported Devices

- **nRF52805**: Not tested.
- **nRF52810**: Tested on an original Tile Tag.
- **nRF51822**: Tested on an AliExpress tag.
- **nRF52832**: Tested with the YJ-17024 board (see details below).

Other nRF devices may also be compatible.

## Compatible Tags from AliExpress

These tags have been tested to work with different versions of the firmware:

### nRF52810 Firmware

- [Holyiot NRF52810](https://s.click.aliexpress.com/e/_DdDyDp9)

### nRF51822 Firmware

- [NRF51822 Tag 1](https://s.click.aliexpress.com/e/_De2JHyL)
- [NRF51822 Tag 2](https://s.click.aliexpress.com/e/_DdkWkyJ)
- [NRF51822 Tag 3](https://s.click.aliexpress.com/e/_DBp4icn)

### nRF52832 Firmware

- [HolyIOT YJ-17024-NRF52832 Amplified Module](https://s.click.aliexpress.com/e/_DlpmE0n): [Manufacturer's documentation](http://www.holyiot.com/eacp_view.asp?id=299).
- [HolyIOT YJ-17095-NRF52832](https://s.click.aliexpress.com/e/_DCkw8LV)

> **Note**: These are affiliate links. If you make a purchase using these links, it helps support ongoing development.

## Building and Flashing Firmware

### Setup Instructions for Building Firmware

To begin, download the necessary SDKs and patch them with updates from the nrfx repository by running:

```bash
make sdk
```

Then install pip, create a venv, activate it and install IntelHex.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install IntelHex
```

### Available Makefile Targets

The following Makefile targets are available for compiling the firmware:

- **nrf52805/armgcc**: `nrf52805_xxaa`, `nrf52805_xxaa-dcdc`
- **nrf51822/armgcc**: `nrf51822_xxac`, `nrf51822_xxac-dcdc`
- **nrf52810/armgcc**: `nrf52810_xxaa`, `nrf52810_xxaa-dcdc`
- **nrf52832/armgcc**: `nrf52832_xxaa`, `nrf52832_xxaa-dcdc`, `nrf52832_yj17024`

### Compiling the Firmware
To compile firmware for all supported devices and place the binaries in the release folder:

```bash
$ make all
$ ls release
 nrf51822_xxac-dcdc_s130.bin    nrf51822_xxac-dcdc.txt
 nrf51822_xxac_s130.bin         nrf51822_xxac.txt
 nrf52805_xxaa-dcdc_s112.bin    nrf52805_xxaa-dcdc.txt
 nrf52805_xxaa_s112.bin         nrf52805_xxaa.txt
 nrf52810_xxaa-dcdc_s112.bin    nrf52810_xxaa-dcdc.txt
 nrf52810_xxaa_s112.bin         nrf52810_xxaa.txt
 nrf52832_xxaa-dcdc_s132.bin    nrf52832_xxaa-dcdc.txt
 nrf52832_xxaa_s132.bin         nrf52832_xxaa.txt
 nrf52832_yj17024_s132.bin      nrf52832_yj17024.txt
```

## Flashing the Firmware

### Flashing using STLink V2 Programmer

You can flash the firmware using an STLink V2 programmer by connecting it to the SWD pins on the device. Run the following command:

```bash
cd nrf51822/armgcc
make clean
make stflash-nrf51822_xxac-patched ADV_KEYS_FILE=./50_NRF_keyfile
```

To flash the nRF52832 with the YJ-17024 configuration:

```bash
cd nrf52832/armgcc
make clean
make stflash-nrf52832_yj17024-patched ADV_KEYS_FILE=./50_NRF_keyfile
```

### Flashing using Raspberry Pi

If you are using a Raspberry Pi for flashing, update the OpenOCD configuration file to use the GPIO pins instead of the STLink V2. Modify the `openocd.cfg` file as follows:

Replace the line:

```bash
source [find interface/stlink.cfg]
```

With:

```bash
# source [find interface/stlink.cfg]
source [find interface/raspberrypi2-native.cfg]
```

### Flashing using Black Magic Probe

To flash the firmware using a Black Magic Probe:

```bash
cd nrf52832/armgcc
make clean
make bmpflash-nrf52832_yj17024-patched ADV_KEYS_FILE=./50_NRF_keyfile
```

## Customizing Firmware with Makefile Variables

You can customize the firmware by adjusting the following Makefile variables:

- **HAS\_DEBUG**: Enable (`1`) or disable (`0`, default) debug logging.
- **MAX\_KEYS**: Set the maximum number of keys to support.
- **HAS\_BATTERY**: Enable (`1`) or disable (`0`, default) battery level reporting.
- **HAS\_DCDC**: Enable (`1`) or let the system select (`0`, default) DCDC mode.
- **KEY\_ROTATION\_INTERVAL**: Set the key rotation interval in seconds (default is 3600 \* 3 seconds).
- **ADVERTISING\_INTERVAL**: Adjust the Bluetooth advertising interval (`0` for default of 1000ms, down to 20ms).
- **BOARD**: Specify the custom board configuration. Defaults to `custom_board` (see `custom_board.h`), but can be set to match specific boards like `yj17024` for nRF52832.
- **ADV\_KEYS\_FILE**: Specify the key file to be flashed to the device.
- **GNU\_INSTALL\_ROOT**: Path to the GNU toolchain (e.g., `../../nrf-sdk/gcc-arm-none-eabi-6-2017-q2-update/bin/`).

## Debugging the Firmware

### Debugging using `strtt` for Logs

The firmware supports using [`strtt`](https://github.com/phryniszak/strtt) to view debug logs. To enable debug logging, set `HAS_DEBUG=1` when compiling:

```bash
cd nrf51822/armgcc
make clean
make stflash-nrf51822_xxac-patched MAX_KEYS=500 HAS_DEBUG=1 ADV_KEYS_FILE=./50_NRF_keyfile
```

You can then use `strtt` to view the logs.

### Debugging using RTT Monitor

The RTT monitor can be used to collect debug logs. Flash the firmware with the following command:

```bash
make bmpflash-monitor
```

To monitor the logs, use `minicom` in a separate terminal (use the command displayed `make bmpflash-monitor` in another terminal):

```bash
$ minicom -c on -D /dev/serial/by-id/usb-Black_Magic_Debug_Black_Magic_Probe__ST-Link_v2__v1.10.0-1151-g3fe0bc5a-XXXXXXXX-if02
<info> app: last_filled_index: 249
<info> app: Starting advertising
<info> app: ble_set_mac_address: DE:AD:BE:EF:CA:FE
<info> app: ble_set_max_tx_power: 8 dB failed
<info> app: ble_set_max_tx_power: 7 dBm failed
<info> app: ble_set_max_tx_power: 6 dBm failed
<info> app: ble_set_max_tx_power: 5 dBm failed
<info> app: ble_set_max_tx_power: 4 dBm
<info> app: Rotating key: 59
<info> app: last_filled_index: 249
[0.000] <info> app: Starting advertising
[0.000] <info> app: ble_set_mac_address: XX:XX:XX:XX:XX:XX
```

## Generating Keys using `tools/generate_keys.py`

Before patching and flashing the firmware, you need to generate the advertising keys. Use the `generate_keys.py` script to create the key file.

### Example

To generate 50 keys and save them with the prefix `SmallTag1`:

```bash
pip install cryptography
python generate_keys.py -n 50 -p SmallTag1
```

This command will create a key file that can be used in the next steps.

## Patching and Flashing using `tools/nrf-patch-log.py`

The `tools/nrf-patch-log.py` script is used to patch a binary file with advertising keys and optionally flash the patched binary to a device. The script provides various options for flashing and monitoring.

### Usage

The script can be run with the following arguments:

- **input\_bin**: Path to the input binary file to be patched.
- **keys\_bin**: Path to the advertising keys binary file.
- **output\_bin**: Path to the output patched binary file (will also create an output ELF file).
- **--flash**: Flash the device after patching.
- **--monitor**: Monitor the device using GDB.
- **--flash-method**: Method to use for flashing the device (`openocd` or `bmp`, default is `openocd`).
- **--openocd-config**: Path to the OpenOCD configuration file (e.g., `openocd.cfg`).
- **--gdb**: Path to the GDB executable (default is `arm-none-eabi-gdb`).
- **--bmp-port**: Serial port of the Black Magic Probe GDB server. If not specified, the script will try to find it automatically.

### Example

To patch a binary and flash it to the device using the Black Magic Probe, run:

```bash
pip install pyserial
python3 nrf-patch-log.py ../release/nrf51822_xxac_s130.bin output-SmallTag1/SmallTag1_keyfile ../release/nrf51822_xxac_s130_SmallTag1.bin --flash --flash-method bmp
```

## Displaying MAC Addresses from a Key File using `tools/showmac.py`

The `showmac.py` script can be used to display the MAC addresses associated with a key file. Below is an example of how to use this script:

To display the MAC addresses from a key file:

```bash
python showmac.py output-SmallTag1/SmallTag1_keyfile
EL:GO:SA:YS:CA:FE
FU:NN:YF:AC:E1:DE
EE:LE:ET:ME:IN:04
CO:01:A3:DE:88:78
FA:CE:CA:FE:DE:AD
FB:AE:58:F7:FE:ED
FB:3E:BA:AD:91:5A
CF:EE:7D:0D:95:B6
```
