{
  pkgs,
  vars,
  ...
}: {
  ## vrserver raises the priority of its tracking threads with setpriority and
  ## sched_setscheduler. Both fail at the default limits of 0, and rtkit does
  ## not help because SteamVR never asks over D-Bus. Takes effect on next login.
  security.pam.loginLimits = [
    {
      domain = vars.username;
      type = "-";
      item = "nice";
      value = "-20";
    }
    {
      domain = vars.username;
      type = "-";
      item = "rtprio";
      value = "95";
    }
  ];

  environment.systemPackages = [
    ## SteamVR Room Setup needs two fixes on this host. SteamVR starts the tool
    ## through steam-runtime-launch-client and forwards only LD_LIBRARY_PATH,
    ## STEAMVR_APPKEY and the VK_* variables, so a Steam launch option cannot
    ## set SDL_VIDEODRIVER. Start SteamVR first, or the tool finds no devices.
    (pkgs.writeShellScriptBin "steamvr-room-setup" ''
      set -eu

      steam_root="$HOME/.steam/steam"
      steamvr="$steam_root/steamapps/common/SteamVR"
      launch_client="$steam_root/ubuntu12_32/steam-runtime/amd64/usr/bin/steam-runtime-launch-client"
      tool="$steamvr/tools/steamvr_room_setup/linux64/steamvr_room_setup.sh"

      if [ ! -x "$launch_client" ]; then
        echo "steamvr-room-setup: Steam is not installed at $steam_root" >&2
        exit 1
      fi
      if [ ! -x "$tool" ]; then
        echo "steamvr-room-setup: SteamVR is not installed" >&2
        exit 1
      fi

      ## The tool is a Unity 5.6 player. Its Vulkan backend only works on X11,
      ## so it exits at once under the session value wayland.
      env="SDL_VIDEODRIVER=x11 STEAM_RUNTIME=$HOME/.steam/bin/steam-runtime"

      ## Unity never enables the device extensions that vrclient.so uses to
      ## share textures with the compositor. vrclient calls vkGetMemoryFdKHR
      ## and vkWaitSemaphores anyway and jumps to NULL once the render models
      ## load. SteamVR ships a Vulkan layer that appends extensions from the
      ## environment. Turn it on and add the extensions the compositor needs.
      ## Upstream bug: https://github.com/ValveSoftware/SteamVR-for-Linux/issues/924
      env="$env VK_LAYER_PATH=$steamvr/bin/linux64"
      env="$env VK_INSTANCE_LAYERS=VK_LAYER_LUNARG_envextensions_layer"
      env="$env VK_ENVEXTENSIONS_INSTANCE_APPEND=VK_KHR_external_memory_capabilities:VK_KHR_external_semaphore_capabilities:VK_KHR_get_physical_device_properties2"
      env="$env VK_ENVEXTENSIONS_DEVICE_APPEND=VK_KHR_external_memory:VK_KHR_external_memory_fd:VK_KHR_external_semaphore:VK_KHR_external_semaphore_fd:VK_KHR_timeline_semaphore:VK_KHR_dedicated_allocation:VK_KHR_get_memory_requirements2:VK_KHR_image_format_list"

      exec "$launch_client" --alongside-steam -- /bin/sh -c \
        "$env exec '$tool' -popupwindow $*"
    '')
  ];
}
