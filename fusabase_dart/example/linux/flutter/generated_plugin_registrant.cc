//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <fusabase_dart/fusabase_dart_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) fusabase_dart_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FusabaseDartPlugin");
  fusabase_dart_plugin_register_with_registrar(fusabase_dart_registrar);
}
