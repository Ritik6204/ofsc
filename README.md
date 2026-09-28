# OFSC Inventory

Offline-first Flutter app for Store Managers and Site Supervisors. One application, role-aware navigation, local SQLite persistence, queued sync, and idempotent field transactions.

## Demo login

| Role | Username | Password |
| --- | --- | --- |
| Store Manager | `raj.kumar` | `Store@123` |
| Site Supervisor | `amit.sharma` | `Site@123` |

## Run

```bash
flutter pub get
flutter run
flutter test
```

The demo backend is in-process so the app can be used without a live server. Swap `RemoteDataSource` onto `ApiClient` when the production REST API is ready. Auth tokens are stored in secure storage. Inventory transactions are never stored only in SharedPreferences.
