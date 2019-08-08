package expo.modules.notifications.configuration;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.os.Bundle;

import java.util.HashMap;

public class Configuration {

    public static String APP_ID_KEY = "appId";
    public static String NOTIFICATION_ACTIVITY_NAME_KEY = "notificationReceiver";
    public static String PUSH_ENGINE_KEY = "pushNotificationEngine";

    static HashMap<String, String> configuration = new HashMap<>();

    static HashMap<String, String> defaultVaules = new HashMap<>();

    static {
        defaultVaules.put(APP_ID_KEY, "defaultId");
        defaultVaules.put(NOTIFICATION_ACTIVITY_NAME_KEY, null);
        defaultVaules.put(PUSH_ENGINE_KEY, "none");
    }

    public static String getValueFor(String name, Context context) {
        if (configuration.containsKey(name)) {
            return configuration.get(name);
        }

        String value = null;
        try {
            ApplicationInfo ai = context.getApplicationInfo();
            Bundle bundle = ai.metaData;
            value = bundle.getString(name);
        } catch (Exception e) {

        }
        if (value == null) {
            configuration.put(name, defaultVaules.get(name));
        } else {
            configuration.put(name, value);
        }
        return configuration.get(name);
    }

}
