//package com.codejet.jetvpn;
//
//import android_backup.app.Notification;
//import android_backup.app.NotificationChannel;
//import android_backup.app.NotificationManager;
//import android_backup.app.PendingIntent;
//import android_backup.app.Service;
//import android_backup.content.Context;
//import android_backup.content.Intent;
//import android_backup.content.SharedPreferences;
//import android_backup.net.VpnService;
//import android_backup.os.Build;
//import android_backup.os.Handler;
//import android_backup.os.IBinder;
//import android_backup.os.ParcelFileDescriptor;
//import android_backup.util.Log;
//
//import androidx.annotation.Nullable;
//import androidx.core.app.NotificationCompat;
//
//import java.io.BufferedReader;
//import java.io.IOException;
//import java.io.InputStream;
//import java.io.InputStreamReader;
//import java.util.concurrent.ExecutorService;
//import java.util.concurrent.Executors;
//
//public class OpenVPNService extends VpnService {
//    public static final String ACTION_CONNECT = "CONNECT";
//    public static final String ACTION_DISCONNECT = "DISCONNECT";
//    private static final String TAG = "OpenVPNService";
//    private static final int NOTIFICATION_ID = 1001;
//    private static final String CHANNEL_ID = "VPN_CHANNEL";
//
//    private ParcelFileDescriptor vpnInterface;
//    private boolean isRunning = false;
//    private String configContent = "";
//    private ExecutorService executor;
//    private Handler mainHandler;
//
//
//    @Override
//    public void onCreate() {
//        super.onCreate();
//        createNotificationChannel();
//        executor = Executors.newSingleThreadExecutor();
//        mainHandler = new Handler(getMainLooper());
//    }
//
//
//    @Override
//    public int onStartCommand(Intent intent, int flags, int startId) {
//        if (intent != null) {
//            String action = intent.getAction();
//            if (ACTION_CONNECT.equals(action)) {
//                String configContent = intent.getStringExtra("config_content");
//                if (configContent == null || configContent.isEmpty()) {
//                    sendError("Config content is empty or null");
//                    return START_NOT_STICKY;
//                }
//                connectVPN(configContent);
//            } else if (ACTION_DISCONNECT.equals(action)) {
//                disconnectVPN();
//            }
//        }
//        return START_STICKY;
//    }
//
//
//    private void connectVPN(String providedConfigContent) {
//        if (isRunning) {
//            return;
//        }
//
//        executor.execute(() -> {
//            try {
//                updateConnectionStatus(false, true, "Connecting...");
//
//                // Use the provided config content directly
//                configContent = providedConfigContent;
//                if (configContent.isEmpty()) {
//                    sendError("Config content is empty");
//                    return;
//                }
//
//                Log.d(TAG, "Config content received, length: " + configContent.length());
//
//                // Parse config and establish VPN connection
//                boolean success = establishVPNConnection();
//                if (success) {
//                    isRunning = true;
//                    saveConnectionState(true);
//                    updateConnectionStatus(true, false, "Connected");
//                    startForegroundNotification("VPN Connected");
//                } else {
//                    sendError("Failed to establish VPN connection");
//                }
//            } catch (Exception e) {
//                Log.e(TAG, "Connection error", e);
//                sendError("Connection error: " + e.getMessage());
//            }
//        });
//    }
//
//
//    private void disconnectVPN() {
//        executor.execute(() -> {
//            try {
//                isRunning = false;
//                if (vpnInterface != null) {
//                    vpnInterface.close();
//                    vpnInterface = null;
//                }
//                saveConnectionState(false);
//                updateConnectionStatus(false, false, "Disconnected");
//                stopForeground(true);
//                stopSelf();
//            } catch (Exception e) {
//                Log.e(TAG, "Disconnection error", e);
//                sendError("Disconnection error: " + e.getMessage());
//            }
//        });
//    }
//
//
//    private boolean establishVPNConnection() {
//        try {
//            // Parse OpenVPN config (simplified version)
//            String[] configLines = configContent.split("\\n");
//            String serverHost = "";
//            int serverPort = 1194;
//
//            for (String line : configLines) {
//                String trimmed = line.trim();
//                if (trimmed.startsWith("remote ")) {
//                    String[] parts = trimmed.split(" ");
//                    if (parts.length >= 3) {
//                        serverHost = parts[1];
//                        try {
//                            serverPort = Integer.parseInt(parts[2]);
//                        } catch (NumberFormatException e) {
//                            serverPort = 1194;
//                        }
//                    }
//                }
//            }
//
//            if (serverHost.isEmpty()) {
//                return false;
//            }
//
//            // Create VPN interface
//            Builder builder = new Builder();
//            builder.setMtu(1500);
//            builder.addAddress("10.8.0.2", 24); // Default VPN IP
//            builder.addDnsServer("8.8.8.8");
//            builder.addDnsServer("8.8.4.4");
//            builder.addRoute("0.0.0.0", 0); // Route all traffic through VPN
//
//            vpnInterface = builder.establish();
//
//            // In a real implementation, you would:
//            // 1. Establish SSL/TLS connection to OpenVPN server
//            // 2. Perform authentication
//            // 3. Handle key exchange
//            // 4. Start packet forwarding
//
//            // For demo purposes, we'll simulate a successful connection
//            try {
//                Thread.sleep(2000); // Simulate connection time
//            } catch (InterruptedException e) {
//                Thread.currentThread().interrupt();
//                return false;
//            }
//
//            return vpnInterface != null;
//        } catch (Exception e) {
//            Log.e(TAG, "Failed to establish VPN connection", e);
//            return false;
//        }
//    }
//
//
//
//    private String readConfigFromAssets(String configFile) {
//        try {
//            InputStream inputStream = getAssets().open("ovpns/" + configFile);
//            BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
//            StringBuilder stringBuilder = new StringBuilder();
//            String line;
//            while ((line = reader.readLine()) != null) {
//                stringBuilder.append(line).append("\n");
//            }
//            reader.close();
//            return stringBuilder.toString();
//        } catch (IOException e) {
//            Log.e(TAG, "Failed to read config file", e);
//            return "";
//        }
//    }
//
//
//    private void createNotificationChannel() {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            CharSequence name = "VPN Service";
//            String description = "VPN Connection Status";
//            int importance = NotificationManager.IMPORTANCE_LOW;
//            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, name, importance);
//            channel.setDescription(description);
//
//            NotificationManager notificationManager = getSystemService(NotificationManager.class);
//            if (notificationManager != null) {
//                notificationManager.createNotificationChannel(channel);
//            }
//        }
//    }
//
//
//    private void startForegroundNotification(String message) {
//        Intent notificationIntent = new Intent(this, MainActivity.class);
//        PendingIntent pendingIntent = PendingIntent.getActivity(
//                this,
//                0,
//                notificationIntent,
//                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ?
//                        PendingIntent.FLAG_IMMUTABLE : 0
//        );
//
//        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
//                .setContentTitle("VPN Service")
//                .setContentText(message)
//                .setSmallIcon(android_backup.R.drawable.ic_lock_lock)
//                .setContentIntent(pendingIntent)
//                .setOngoing(true)
//                .build();
//
//        startForeground(NOTIFICATION_ID, notification);
//    }
//
//    private void updateConnectionStatus(boolean isConnected, boolean isConnecting, String status) {
//        mainHandler.post(() -> {
//            if (MainActivity.instance != null) {
//                MainActivity.instance.sendStatusUpdate(isConnected, isConnecting, status);
//            }
//        });
//    }
//
//    private void sendError(String message) {
//        mainHandler.post(() -> {
//            if (MainActivity.instance != null) {
//                MainActivity.instance.sendError(message);
//            }
//        });
//    }
//
//
//    private void saveConnectionState(boolean isConnected) {
//        SharedPreferences prefs = getSharedPreferences("vpn_prefs", Context.MODE_PRIVATE);
//        prefs.edit().putBoolean("is_connected", isConnected).apply();
//    }
//
//    @Override
//    public void onDestroy() {
//        super.onDestroy();
//        if (executor != null && !executor.isShutdown()) {
//            executor.shutdown();
//        }
//        if (vpnInterface != null) {
//            try {
//                vpnInterface.close();
//            } catch (IOException e) {
//                Log.e(TAG, "Error closing VPN interface", e);
//            }
//        }
//        saveConnectionState(false);
//    }
//
//    @Nullable
//    @Override
//    public IBinder onBind(Intent intent) {
//        return null;
//    }
//}
