package expo.modules.notifications.presenters;

import android.app.ActivityManager;
import android.content.Context;
import android.os.Bundle;

import expo.modules.notifications.postoffice.PostOfficeProxy;

import static android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND;
import static android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE;

public class SmartNotificationPresenter implements NotificationPresenter {

  private NotificationPresenter mNotificationPresenter = new NotificationPresenterImpl();

  @Override
  public void presentNotification(Context context, String appId, Bundle notification, int notificationId) {
    if (isInForegroundState()) {
      PostOfficeProxy.getInstance().sendForegroundNotification(appId, notification);
    } else {
      mNotificationPresenter.presentNotification(context, appId, notification, notificationId);
    }
  }

  private boolean isInForegroundState() {
      ActivityManager.RunningAppProcessInfo appProcessInfo = new ActivityManager.RunningAppProcessInfo();
      ActivityManager.getMyMemoryState(appProcessInfo);
      return (appProcessInfo.importance == IMPORTANCE_FOREGROUND || appProcessInfo.importance == IMPORTANCE_VISIBLE); // check
  }

}
