package com.codejet.jetvpn;

//import android.content.Context;
//import android.content.Intent;
//import android.content.SharedPreferences;
//import android.net.VpnService;
//import android.os.Bundle;
//
//import androidx.annotation.NonNull;
//
//import java.io.IOException;
//import java.util.ArrayList;
//import java.util.HashMap;
//import java.util.List;
//import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
//import io.flutter.embedding.engine.FlutterEngine;
//import io.flutter.plugin.common.MethodChannel;

public class MainActivityBackup extends FlutterActivity {
//
//    private static final String CHANNEL = "com.codejet.jetvpn/channel";
//    private static final int VPN_REQUEST_CODE = 432;
//    private MethodChannel methodChannel;
//    private MethodChannel.Result pendingResult;
//    public static MainActivity instance;
//
//
//        protected void onCreate(Bundle saveInstanceState) {
//        super.onCreate(saveInstanceState);
//    }
//
//
//    @Override
//    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
//        super.configureFlutterEngine(flutterEngine);
//
//        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
//        methodChannel.setMethodCallHandler((call, result) -> {
//            switch (call.method){
//                case "connectVPN":
//                    String configContent = call.argument("configContent");
//                    if(configContent == null){
//                        throw new IllegalArgumentException("Config content not provided");
//                    }
//                    connectVPN(configContent, result);
//                    break;
//
//                case "disconnectVPN":
//                    disconnectVPN(result);
//                    break;
//
//                case "getVPNStatus":
//                    result.success(isVPNConnected());
//                    break;
//
//                case "getAvailableConfigs":
//                    result.success(getAvailableConfigs());
//                    break;
//
//                default:
//                    result.notImplemented();
//                    break;
//
//            }
//        });
//
//    }
//
//
//    private String pendingConfigContent; // Store config content for permission callback
//
//    private void connectVPN(String configContent, MethodChannel.Result result){
//        Intent vpnIntent = VpnService.prepare(this);
//
//        if(vpnIntent != null){
//            // VPN permission not granted
//            pendingResult = result;
//            pendingConfigContent = configContent; // Store the config content
//            startActivityForResult(vpnIntent, VPN_REQUEST_CODE);
//        } else {
//            // VPN permission granted
//            startVPNService(configContent);
//            result.success(true);
//        }
//    }
//
//    private void disconnectVPN(MethodChannel.Result result){
//        Intent intent = new Intent(this, OpenVPNService.class);
//        intent.setAction(OpenVPNService.ACTION_DISCONNECT);
//        startService(intent);
//        result.success(true);
//    }
//
//    private boolean isVPNConnected() {
//        SharedPreferences prefs = getSharedPreferences("vpn_prefs", Context.MODE_PRIVATE);
//        return prefs.getBoolean("is_connected", false);
//    }
//
//
//
//    private List<String> getAvailableConfigs() {
//        List<String> configList = new ArrayList<>();
//        try {
//            String[] files = getAssets().list("ovpns");
//            if (files != null) {
//                for (String file : files) {
//                    if (file.endsWith(".ovpn")) {
//                        configList.add(file);
//                    }
//                }
//            }
//        } catch (IOException e) {
//            e.printStackTrace();
//        }
//        return configList;
//    }
//
//    private void startVPNService(String configContent) {
//        Intent intent = new Intent(this, OpenVPNService.class);
//        intent.setAction(OpenVPNService.ACTION_CONNECT);
//        intent.putExtra("config_content", configContent);
//        startService(intent);
//    }
//
//
//
//
//    public void sendStatusUpdate(boolean isConnected, boolean isConnecting, String status) {
//        Map<String, Object> arguments = new HashMap<>();
//        arguments.put("isConnected", isConnected);
//        arguments.put("isConnecting", isConnecting);
//        arguments.put("status", status);
//
//        if (methodChannel != null) {
//            methodChannel.invokeMethod("onVPNStatusChanged", arguments);
//        }
//    }
//
//    public void sendError(String message) {
//        Map<String, Object> arguments = new HashMap<>();
//        arguments.put("message", message);
//
//        if (methodChannel != null) {
//            methodChannel.invokeMethod("onVPNError", arguments);
//        }
//    }
//
//    @Override
//    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
//        super.onActivityResult(requestCode, resultCode, data);
//
//        if (requestCode == VPN_REQUEST_CODE) {
//            if (resultCode == RESULT_OK) {
//                // VPN permission granted
//                if (pendingResult != null && pendingConfigContent != null) {
//                    startVPNService(pendingConfigContent);
//                    pendingResult.success(true);
//                }
//            } else {
//                // VPN permission denied
//                if (pendingResult != null) {
//                    pendingResult.success(false);
//                }
//                sendStatusUpdate(false, false, "VPN permission denied");
//            }
//            pendingResult = null;
//            pendingConfigContent = null;
//        }
//    }
//
//    protected void onDestroy() {
//        super.onDestroy();
//    }
}
