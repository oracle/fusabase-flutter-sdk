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

import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.content.Intent;
import io.flutter.plugin.common.MethodChannel.Result;



public class FusabaseCallbackActivity extends Activity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent intent = getIntent();
        Uri url = intent == null ? null : intent.getData();
        if (url == null) {
            finish();
            return;
        }
        String scheme = url.getScheme();
        if (scheme != null) {
            Result temp = FusabaseDartPlugin.callbacks.get(scheme);
            if(temp!=null){
                FusabaseDartPlugin.callbacks.remove(scheme);
                String tt = url.toString();  
                temp.success(tt);
            }
        }

        finish();
    }
}
