#!/bin/bash
# DOSBox Slip Setter - 2017 Mike Ladouceur
# Fork of Naszvadi Peter's "dosbox slip setter"

# Changes:
# - Downloads entire mTCP suite from Michael Brutman
# - Does not auto-launch IRCjr
# - Does not give you a random IRCjr username
# - Does not auto-exit
# - Does not delete everything once it's done
# - Fully usable DOSBox conf file (built into script!)

flushipt() {
  for i in $( iptables -t nat -n --line-numbers -L | awk '/^Chain POSTROUTING/,/^$/{print $0}' \
            | grep '^[0-9]' | grep '192\.168\.7\.' | awk '{ print $1 }' | tac )
  do
    iptables -t nat -D POSTROUTING "$i"
  done

  for i in $( iptables -t nat -n --line-numbers -L | awk '/^Chain PREROUTING/,/^$/{print $0}' \
            | grep ^[0-9] | grep '192\.168\.7\.' | awk '{ print $1 }' | tac )
  do
    iptables -t nat -D PREROUTING "$i"
  done
}

if [ ! -d "./mnt/net" ]; then
    mkdir -p ./mnt/net
fi

if id -u | grep -q '^0'; then
    :
else
    echo 'DOSBox Slip Setter'
    echo 'Author: Naszvadi Peter (fork by Mike Ladouceur)'
    echo
    echo "Please run $0 as root!"
    echo
    exit 1
fi

if ! which socat; then
    echo
    echo 'Install socat! It is required.'
    echo
    echo 'e.g. sudo apt-get install socat'
    echo
    exit 1
fi

if ! which slattach; then
    echo
    echo 'Install slattach! It is required.'
    echo
    exit 1
fi

if ! which dosbox; then
    echo
    echo 'Install dosbox! It is required.'
    echo
    exit 1
fi

Uid="$(find "$0" -printf '%U' -quit)"

if [ -z "$(find . -iname ethersl.com)" ]; then
    if ! which unzip; then
        echo
        echo 'Install unzip! It is required.'
        echo
        exit 1
    fi
    if ! which wget; then
        echo
        echo 'Install wget! It is required.'
        echo
        exit 1
    fi
    sudo -u "#$Uid" bash -c 'wget -q http://crynwr.com/drivers/pktd11.zip \
    && unzip -Cj pktd11.zip ethersl.com -d ./mnt/net'
fi

if [ -z "$(find . -iname ircjr.exe)" ]; then
    if ! which unzip; then
        echo
        echo 'Install unzip! It is required.'
        echo
        exit 1
    fi
    if ! which wget; then
        echo
        echo 'Install wget! It is required.'
        echo
        exit 1
    fi

    sudo -u "#$Uid" bash -c 'wget -q -O mtcp.zip http://www.brutman.com/mTCP/mTCP_2013-05-23.zip \
    && unzip -Cj mtcp.zip -d ./mnt/net'
fi

# Flushing...
flushipt

Dev_Pts='/tmp/slip'"$RANDOM"
Slip_Port=8040

if ! [ -e dosslip.cnf ]; then
sudo -u "#$Uid" bash -c 'cat <<END > dosslip.cnf
# This is the configurationfile for DOSBox.
# Lines starting with a # are commentlines and are ignored by DOSBox.
# They are used to (briefly) document the effect of each option.

[sdl]
#       fullscreen: Start dosbox directly in fullscreen. (Press ALT-Enter to go back)
#       fulldouble: Use double buffering in fullscreen. It can reduce screen flickering, but it can also result in a slow DOSBox.
#   fullresolution: What resolution to use for fullscreen: original or fixed size (e.g. 1024x768).
#                     Using your monitor's native resolution with aspect=true might give the best results.
#                     If you end up with small window on a large screen, try an output different from surface.
# windowresolution: Scale the window to this size IF the output device supports hardware scaling.
#                     (output=surface does not!)
#           output: What video system to use for output.
#                   Possible values: surface, overlay, opengl, openglnb.
#         autolock: Mouse will automatically lock, if you click on the screen. (Press CTRL-F10 to unlock)
#      sensitivity: Mouse sensitivity.
#      waitonerror: Wait before closing the console if dosbox has an error.
#         priority: Priority levels for dosbox. Second entry behind the comma is for when dosbox is not focused/minimized.
#                     pause is only valid for the second entry.
#                   Possible values: lowest, lower, normal, higher, highest, pause.
#       mapperfile: File used to load/save the key/event mappings from. Resetmapper only works with the defaul value.
#     usescancodes: Avoid usage of symkeys, might not work on all operating systems.

fullscreen=false
fulldouble=false
fullresolution=original
windowresolution=original
output=surface
autolock=true
sensitivity=100
waitonerror=true
priority=higher,normal
mapperfile=mapper-SVN.map
usescancodes=true

[dosbox]
# language: Select another language file.
#  machine: The type of machine DOSBox tries to emulate.
#           Possible values: hercules, cga, tandy, pcjr, ega, vgaonly, svga_s3, svga_et3000, svga_et4000, svga_paradise, vesa_nolfb, vesa_oldvbe.
# captures: Directory where things like wave, midi, screenshot get captured.
#  memsize: Amount of memory DOSBox has in megabytes.
#             This value is best left at its default to avoid problems with some games,
#             though few games might require a higher value.
#             There is generally no speed advantage when raising this value.

language=
machine=svga_s3
captures=capture
memsize=16

[render]
# frameskip: How many frames DOSBox skips before drawing one.
#    aspect: Do aspect correction, if your output method doesn't support scaling this can slow things down!.
#    scaler: Scaler used to enlarge/enhance low resolution modes. If 'forced' is appended,
#            then the scaler will be used even if the result might not be desired.
#            Possible values: none, normal2x, normal3x, advmame2x, advmame3x, advinterp2x, advinterp3x, hq2x, hq3x, 2xsai, super2xsai, supereagle, tv2x, tv3x, rgb2x, rgb3x, scan2x, scan3x.

frameskip=0
aspect=false
scaler=normal2x

[cpu]
#      core: CPU Core used in emulation. auto will switch to dynamic if available and
#            appropriate.
#            Possible values: auto, dynamic, normal, simple.
#   cputype: CPU Type used in emulation. auto is the fastest choice.
#            Possible values: auto, 386, 386_slow, 486_slow, pentium_slow, 386_prefetch.
#    cycles: Amount of instructions DOSBox tries to emulate each millisecond.
#            Setting this value too high results in sound dropouts and lags.
#            Cycles can be set in 3 ways:
#              'auto'          tries to guess what a game needs.
#                              It usually works, but can fail for certain games.
#              'fixed #number' will set a fixed amount of cycles. This is what you usually
#                              need if 'auto' fails (Example: fixed 4000).
#              'max'           will allocate as much cycles as your computer is able to
#                              handle.
#            Possible values: auto, fixed, max.
#   cycleup: Amount of cycles to decrease/increase with keycombos.(CTRL-F11/CTRL-F12)
# cycledown: Setting it lower than 100 will be a percentage.

core=auto
cputype=auto
cycles=auto
cycleup=10
cycledown=20

[mixer]
#   nosound: Enable silent mode, sound is still emulated though.
#      rate: Mixer sample rate, setting any device's rate higher than this will probably lower their sound quality.
#            Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
# blocksize: Mixer block size, larger blocks might help sound stuttering but sound will also be more lagged.
#            Possible values: 1024, 2048, 4096, 8192, 512, 256.
# prebuffer: How many milliseconds of data to keep on top of the blocksize.

nosound=false
rate=44100
blocksize=1024
prebuffer=20

[midi]
#     mpu401: Type of MPU-401 to emulate.
#             Possible values: intelligent, uart, none.
# mididevice: Device that will receive the MIDI data from MPU-401.
#             Possible values: default, win32, alsa, oss, coreaudio, coremidi, none.
# midiconfig: Special configuration options for the device driver. This is usually the id of the device you want to use.
#               or in the case of coreaudio, you can specify a soundfont here.
#               When using a Roland MT-32 rev. 0 as midi output device, some games may require a delay in order to prevent 'buffer overflow' issues.
#               In that case, add 'delaysysex', for example: midiconfig=2 delaysysex
#               See the README/Manual for more details.

mpu401=intelligent
mididevice=default
midiconfig=

[sblaster]
#  sbtype: Type of Soundblaster to emulate. gb is Gameblaster.
#          Possible values: sb1, sb2, sbpro1, sbpro2, sb16, gb, none.
#  sbbase: The IO address of the soundblaster.
#          Possible values: 220, 240, 260, 280, 2a0, 2c0, 2e0, 300.
#     irq: The IRQ number of the soundblaster.
#          Possible values: 7, 5, 3, 9, 10, 11, 12.
#     dma: The DMA number of the soundblaster.
#          Possible values: 1, 5, 0, 3, 6, 7.
#    hdma: The High DMA number of the soundblaster.
#          Possible values: 1, 5, 0, 3, 6, 7.
# sbmixer: Allow the soundblaster mixer to modify the DOSBox mixer.
# oplmode: Type of OPL emulation. On 'auto' the mode is determined by sblaster type. All OPL modes are Adlib-compatible, except for 'cms'.
#          Possible values: auto, cms, opl2, dualopl2, opl3, none.
#  oplemu: Provider for the OPL emulation. compat might provide better quality (see oplrate as well).
#          Possible values: default, compat, fast.
# oplrate: Sample rate of OPL music emulation. Use 49716 for highest quality (set the mixer rate accordingly).
#          Possible values: 44100, 49716, 48000, 32000, 22050, 16000, 11025, 8000.

sbtype=sb16
sbbase=220
irq=7
dma=1
hdma=5
sbmixer=true
oplmode=auto
oplemu=default
oplrate=44100

[gus]
#      gus: Enable the Gravis Ultrasound emulation.
#  gusrate: Sample rate of Ultrasound emulation.
#           Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
#  gusbase: The IO base address of the Gravis Ultrasound.
#           Possible values: 240, 220, 260, 280, 2a0, 2c0, 2e0, 300.
#   gusirq: The IRQ number of the Gravis Ultrasound.
#           Possible values: 5, 3, 7, 9, 10, 11, 12.
#   gusdma: The DMA channel of the Gravis Ultrasound.
#           Possible values: 3, 0, 1, 5, 6, 7.
# ultradir: Path to Ultrasound directory. In this directory
#           there should be a MIDI directory that contains
#           the patch files for GUS playback. Patch sets used
#           with Timidity should work fine.

gus=false
gusrate=44100
gusbase=240
gusirq=5
gusdma=3
ultradir=C:\ULTRASND

[speaker]
# pcspeaker: Enable PC-Speaker emulation.
#    pcrate: Sample rate of the PC-Speaker sound generation.
#            Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
#     tandy: Enable Tandy Sound System emulation. For 'auto', emulation is present only if machine is set to 'tandy'.
#            Possible values: auto, on, off.
# tandyrate: Sample rate of the Tandy 3-Voice generation.
#            Possible values: 44100, 48000, 32000, 22050, 16000, 11025, 8000, 49716.
#    disney: Enable Disney Sound Source emulation. (Covox Voice Master and Speech Thing compatible).

pcspeaker=true
pcrate=44100
tandy=auto
tandyrate=44100
disney=true

[joystick]
# joysticktype: Type of joystick to emulate: auto (default), none,
#               2axis (supports two joysticks),
#               4axis (supports one joystick, first joystick used),
#               4axis_2 (supports one joystick, second joystick used),
#               fcs (Thrustmaster), ch (CH Flightstick).
#               none disables joystick emulation.
#               auto chooses emulation depending on real joystick(s).
#               (Remember to reset dosbox's mapperfile if you saved it earlier)
#               Possible values: auto, 2axis, 4axis, 4axis_2, fcs, ch, none.
#        timed: enable timed intervals for axis. Experiment with this option, if your joystick drifts (away).
#     autofire: continuously fires as long as you keep the button pressed.
#       swap34: swap the 3rd and the 4th axis. can be useful for certain joysticks.
#   buttonwrap: enable button wrapping at the number of emulated buttons.

joysticktype=auto
timed=true
autofire=false
swap34=false
buttonwrap=false

[serial]
# serial1: set type of device connected to com port.
#          Can be disabled, dummy, modem, nullmodem, directserial.
#          Additional parameters must be in the same line in the form of
#          parameter:value. Parameter for all types is irq (optional).
#          for directserial: realport (required), rxdelay (optional).
#                           (realport:COM1 realport:ttyS0).
#          for modem: listenport (optional).
#          for nullmodem: server, rxdelay, txdelay, telnet, usedtr,
#                         transparent, port, inhsocket (all optional).
#          Example: serial1=modem listenport:5000
#          Possible values: dummy, disabled, modem, nullmodem, directserial.
# serial2: see serial1
#          Possible values: dummy, disabled, modem, nullmodem, directserial.
# serial3: see serial1
#          Possible values: dummy, disabled, modem, nullmodem, directserial.
# serial4: see serial1
#          Possible values: dummy, disabled, modem, nullmodem, directserial.

serial1=nullmodem server:localhost port:'"$Slip_Port"' transparent:1
serial2=disabled
serial3=disabled
serial4=disabled

[dos]
#            xms: Enable XMS support.
#            ems: Enable EMS support. The default (=true) provides the best
#                 compatibility but certain applications may run better with
#                 other choices, or require EMS support to be disabled (=false)
#                 to work at all.
#                 Possible values: true, emsboard, emm386, false.
#            umb: Enable UMB support.
# keyboardlayout: Language code of the keyboard layout (or none).

xms=true
ems=true
umb=true
keyboardlayout=auto

[ipx]
# ipx: Enable ipx over UDP/IP emulation.

ipx=false

[autoexec]
# Lines in this section will be run at startup.
# You can put your MOUNT lines here BEFORE END'.
@echo off
mount c ./mnt
C:
C:\net\ethersl 0x60 4 0x3f8 9600
SET MTCPSLIP=true
SET MTCPCFG=C:\net\TCP.CFG
END'
fi

if [ -z "$(find . -iname ethersl.com)" ]; then
sudo -u "#$Uid" bash -c 'cat <<END > ./mnt/net/tcp.cfg
DHCPVER DHCP Client version Jul 29 2011
TIMESTAMP Mon May 21 13:14:59 2012
packetint 0x60
hostname dosslip
ftpsrv_password_file NUL
ftpsrv_log_file NUL
IPADDR 192.168.7.2
NETMASK 255.255.255.252
GATEWAY 192.168.7.1
NAMESERVER 8.8.8.8
LEASE_TIME 600
END'
fi

socat PTY,link="$Dev_Pts",raw,echo=0 TCP-LISTEN:"$Slip_Port" &
Pid_Saved_3="$!"
sleep 1

sudo -u "#$Uid" dosbox -conf dosslip.cnf &
Pid_Saved="$!"

# setting linux ipv4 forwarding
grep -q 1 /proc/sys/net/ipv4/ip_forward || ( echo 1 1>/proc/sys/net/ipv4/ip_forward )

slattach -d -s 9600 -p adaptive "$Dev_Pts" 1>/dev/null 2>/dev/null &
Pid_Saved_2="$!"

sleep 3

ifconfig sl0 192.168.7.1 dstaddr 192.168.7.2 netmask 255.255.255.252 mtu 576 up 1>/dev/null 2>/dev/null
set -x
iptables -t nat -A POSTROUTING -s 192.168.7.0/30 -j MASQUERADE 1>/dev/null 2>/dev/null

set +x
while ps "$Pid_Saved" 1>/dev/null 2>/dev/null; do
    sleep 5
done 1>/dev/null 2>/dev/null

2>&-
kill -9 "$Pid_Saved_2" "$Pid_Saved_3" 1>/dev/null 2>/dev/null

# Flushing...
flushipt

rm dosslip.cnf
exit 0