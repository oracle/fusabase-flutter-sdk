#ifndef FLUTTER_PLUGIN_OBAAS_DART_PLUGIN_H_
#define FLUTTER_PLUGIN_OBAAS_DART_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace fusabase_dart {

class FusabaseDartPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FusabaseDartPlugin();

  virtual ~FusabaseDartPlugin();

  // Disallow copy and assign.
  FusabaseDartPlugin(const FusabaseDartPlugin&) = delete;
  FusabaseDartPlugin& operator=(const FusabaseDartPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace fusabase_dart

#endif  // FLUTTER_PLUGIN_OBAAS_DART_PLUGIN_H_
