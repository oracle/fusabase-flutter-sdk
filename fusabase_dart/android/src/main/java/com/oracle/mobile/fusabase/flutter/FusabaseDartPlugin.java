// Copyright (c) 2015, 2025, Oracle and/or its affiliates.

//-----------------------------------------------------------------------------
//
// This software is dual-licensed to you under the Universal Permissive License
// (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
// 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
// either license.
//
// If you elect to accept the software under the Apache License, Version 2.0,
// the following applies:
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//-----------------------------------------------------------------------------

package com.oracle.mobile.fusabase.flutter;

import java.util.Map;
import java.util.HashMap;
import androidx.annotation.NonNull;
import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.net.Uri;

import androidx.browser.customtabs.CustomTabsIntent;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


import static android.content.Context.MODE_PRIVATE;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.NonNull;

import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;

public class FusabaseDartPlugin implements FlutterPlugin, MethodCallHandler {
 
  private MethodChannel channel;
  private Context context;
  public static HashMap<String, Result> callbacks = new HashMap<>();
  private SharedPreferences prefs;
  private static final String PREF_NAME = "secure_kv_store";
  private static final String KEY_ALIAS = "secure_kv_aes_key";
  private static final String ANDROID_KEYSTORE = "AndroidKeyStore";
  //private lateinit var sharedPrefs: EncryptedSharedPreferences;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "fusabase_dart_auth");
    channel.setMethodCallHandler(this);
    prefs = context.getSharedPreferences(PREF_NAME, MODE_PRIVATE);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call,@NonNull Result result) {
    if (call.method.equals("fusabaseauthenticate")) {
      Uri url = Uri.parse(call.argument("url"));
      String callbackUrlScheme = call.argument("callbackUrlScheme");
      Boolean preferEphemeral = true;
      callbacks.put(callbackUrlScheme,result);

      CustomTabsIntent intent = new CustomTabsIntent.Builder().build();
      Intent keepAliveIntent = new Intent(context, FusabaseKeepAliveService.class);

      intent.intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
      intent.intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

      if (preferEphemeral) {
          intent.intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
      }
      intent.intent.putExtra("android.support.customtabs.extra.KEEP_ALIVE", keepAliveIntent);

      intent.launchUrl(context, url);
    }
    if (call.method.equals("fusabasecleanUpDanglingCalls")) {
      callbacks.forEach( (temp, danglingResultCallback) -> {
      danglingResultCallback.error("CANCELED", "User canceled login", null);
      }
      );
    callbacks.clear();
    
    }
    if (call.method.equals("pkceredirectgenerate")) {

      String codeVerifier = "";
      String codeChallenge = "";

      codeVerifier = PKCEHelper.generateCodeVerifier();
      try {
        codeChallenge = PKCEHelper.generateCodeChallenge(codeVerifier);
      } catch(Exception e) {
        result.error("599", "Failed to generate code challenge", null); 
      }

      Map<String, String> response = new HashMap<>();
      response.put("codeVerifier", codeVerifier);
      response.put("codeChallenge", codeChallenge);

      result.success(response);
    }
    if (call.method.equals("getValue")) {
      try {
        result.success(getValue(call.argument("key")));
      } catch (Exception e) {
        result.success(null);
      } 
    }
    if (call.method.equals("setValue")) {
      try {
        result.success(setValue(call.argument("key"), call.argument("value")));
      } catch (Exception e) {
        result.success(false);
      } 
    }
    if (call.method.equals("removeValue")) {
      try {
        result.success(removeValue(call.argument("key")));
      } catch (Exception e) {
        result.success(false);
      } 
    }
    else {
      
    }
  }

  private static void openCustomTab(@NonNull Activity activity,
                                      @NonNull String authUrl) {
        CustomTabsIntent.Builder builder = new CustomTabsIntent.Builder();
        CustomTabsIntent customTabsIntent = builder.build();
        customTabsIntent.intent.setFlags(
                Intent.FLAG_ACTIVITY_SINGLE_TOP |
                        Intent.FLAG_ACTIVITY_CLEAR_TOP |
                        Intent.FLAG_ACTIVITY_NO_HISTORY |
                        Intent.FLAG_ACTIVITY_NEW_TASK
        );
        customTabsIntent.launchUrl(activity, Uri.parse(authUrl));

    }
  
  private boolean setValue(String key, String value) throws Exception {
        SecretKey secretKey = getOrCreateKey();
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, secretKey);

        byte[] iv = cipher.getIV();
        byte[] encrypted = cipher.doFinal(value.getBytes(StandardCharsets.UTF_8));

        String payload = Base64.getEncoder().encodeToString(iv) + ":" +
                Base64.getEncoder().encodeToString(encrypted);
        prefs.edit().putString(key, payload).apply();
        return true;
    }

    private String getValue(String key) throws Exception {
        String payload = prefs.getString(key, null);
        if (payload == null) return null;

        String[] parts = payload.split(":");
        byte[] iv = Base64.getDecoder().decode(parts[0]);
        byte[] encrypted = Base64.getDecoder().decode(parts[1]);

        SecretKey secretKey = getOrCreateKey();
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(128, iv));

        byte[] decrypted = cipher.doFinal(encrypted);
        return new String(decrypted, StandardCharsets.UTF_8);
    }

    private boolean removeValue(String key) {
        prefs.edit().remove(key).apply();
        return true;
    }

    private SecretKey getOrCreateKey() throws Exception {
        KeyStore keyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
        keyStore.load(null);

        if (!keyStore.containsAlias(KEY_ALIAS)) {
            KeyGenerator keyGenerator =
                    KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE);

            keyGenerator.init(
                    new KeyGenParameterSpec.Builder(
                            KEY_ALIAS,
                            KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                            .setKeySize(256)
                            .build()
            );
            keyGenerator.generateKey();
        }

        return ((KeyStore.SecretKeyEntry) keyStore.getEntry(KEY_ALIAS, null)).getSecretKey();
    }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
