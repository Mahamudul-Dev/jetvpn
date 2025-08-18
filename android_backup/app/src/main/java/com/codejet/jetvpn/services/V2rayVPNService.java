package com.codejet.jetvpn.services;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

public class V2rayVPNService extends Service {
    public V2rayVPNService() {
    }

    @Override
    public IBinder onBind(Intent intent) {
        // TODO: Return the communication channel to the service.
        throw new UnsupportedOperationException("Not yet implemented");
    }
}