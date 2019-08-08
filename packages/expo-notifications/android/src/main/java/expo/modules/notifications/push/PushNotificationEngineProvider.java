package expo.modules.notifications.push;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import expo.modules.notifications.configuration.Configuration;
import expo.modules.notifications.push.engines.BareEngine;
import expo.modules.notifications.push.engines.ExpoEngine;
import expo.modules.notifications.push.engines.StabEngine;

public class PushNotificationEngineProvider {

    private static Map<String, Engine> engines;

    public synchronized static Engine getPushNotificationEngine(Context context) {
        init();
        return engines.get(Configuration.getValueFor(Configuration.PUSH_ENGINE_KEY, context));
    }

    private static void init() {
        if (engines == null) {
            engines = new HashMap<>();
            engines.put("none", new StabEngine());
            engines.put("bare", new BareEngine());
            engines.put("expo", new ExpoEngine());
        }
    }

}
