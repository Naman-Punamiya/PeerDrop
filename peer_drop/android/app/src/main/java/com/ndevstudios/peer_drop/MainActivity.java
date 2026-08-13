package com.ndevstudios.peer_drop;

import android.content.Context;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    private WifiManager.MulticastLock multicastLock;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            WifiManager wifiManager = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wifiManager != null) {
                multicastLock = wifiManager.createMulticastLock("PeerDropMulticastLock");
                multicastLock.setReferenceCounted(true);
                multicastLock.acquire();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onDestroy() {
        if (multicastLock != null && multicastLock.isHeld()) {
            multicastLock.release();
        }
        super.onDestroy();
    }
}

