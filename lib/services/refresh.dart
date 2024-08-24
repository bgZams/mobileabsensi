class SyncLimiter {
  static DateTime? lastFetchTime;
  static int syncCount = 0;
  static const int maxSyncCount = 3;
  static const Duration timeFrame = Duration(minutes: 1);

  static bool canSync() {
    DateTime now = DateTime.now();

    if (lastFetchTime != null && now.difference(lastFetchTime!) < timeFrame) {
      if (syncCount >= maxSyncCount) {
        return false;
      } else {
        syncCount++;
        return true;
      }
    } else {
      lastFetchTime = now;
      syncCount = 1;
      return true;
    }
  }
  static void reset() {
    lastFetchTime = null;
    syncCount = 0;
  }
}