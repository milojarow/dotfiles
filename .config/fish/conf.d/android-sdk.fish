# Android SDK environment (installed via android-sdk-cmdline-tools-latest AUR pkg)
set -gx ANDROID_HOME /opt/android-sdk
set -gx ANDROID_SDK_ROOT /opt/android-sdk
fish_add_path -g /opt/android-sdk/cmdline-tools/latest/bin /opt/android-sdk/platform-tools /opt/android-sdk/emulator
