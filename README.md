# Submarine Control App (Flutter)

## Tính năng

- Đăng nhập bằng mật khẩu hoặc xác thực giọng nói
- Điều khiển bằng giọng nói / nhập lệnh (tiếng Việt & English)
- Bản đồ GPS với vị trí tàu ngầm mô phỏng
- Lịch sử lệnh, lọc, tìm kiếm
- Chuyển ngôn ngữ VI / EN

## Chạy ứng dụng

```bash
cd submarine_flutter
flutter pub get
flutter run
```

Yêu cầu: Flutter SDK ≥ 3.3, quyền micro (Android/iOS) cho nhận dạng giọng nói.

## Cấu trúc

```
lib/
  main.dart              # Entry, routing đăng nhập / shell
  theme.dart             # Màu & theme (giống React)
  l10n/translations.dart # Bản dịch VI/EN
  models/command.dart
  providers/app_provider.dart
  screens/               # login, voice, map, history, main_shell
  widgets/               # background, lang toggle, sound bars, stat tile
```
