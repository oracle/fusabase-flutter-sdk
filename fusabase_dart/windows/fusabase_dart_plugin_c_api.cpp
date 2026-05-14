#include "include/fusabase_dart/fusabase_dart_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "fusabase_dart_plugin.h"

void FusabaseDartPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  fusabase_dart::FusabaseDartPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
