// Translations — Dart port of translations.ts
// Supports Vietnamese (vi) and English (en)

enum Lang { vi, en }

class AppTranslations {
  final Lang lang;
  const AppTranslations(this.lang);

  bool get isVi => lang == Lang.vi;

  // Login
  String get loginSubtitle => isVi
      ? 'HỆ THỐNG ĐIỀU KHIỂN AUV'
      : 'AUV CONTROL SYSTEM';
  String get selectAuth =>
      isVi ? 'Chọn phương thức xác thực' : 'Select authentication method';
  String get voiceAuth => isVi ? 'Xác thực giọng nói' : 'Voice Authentication';
  String get voiceAuthDesc =>
        isVi ? 'Nhận dạng cụm từ bí mật' : 'Secret phrase recognition';
  String get passwordAuth => isVi ? 'Mật khẩu bảo mật' : 'Secure Password';
  String get passwordAuthDesc =>
      isVi ? 'Nhập thông tin đăng nhập' : 'Enter credentials';
  String get usernameLabel => isVi ? 'TÊN ĐĂNG NHẬP' : 'USERNAME';
  String get passwordLabel => isVi ? 'MẬT KHẨU' : 'PASSWORD';
  String get usernameHint => isVi ? 'Nhập tên đăng nhập' : 'Enter username';
  String get authenticate => isVi ? 'XÁC THỰC' : 'AUTHENTICATE';
  String get back => isVi ? '← Quay lại' : '← Go back';
  String get wrongCreds => isVi
      ? 'Thông tin không đúng. Vui lòng thử lại.'
      : 'Invalid credentials. Please try again.';
  String get networkError => isVi
      ? 'Không kết nối được máy chủ. Kiểm tra backend đang chạy.'
      : 'Cannot reach server. Ensure the backend is running.';
  String get sayPhrase => isVi ? 'Hãy nói gì đó' : 'Please say something';
  String get pressmic =>
      isVi ? 'Nhấn microphone để bắt đầu' : 'Press microphone to begin';
  String get listening => isVi ? 'Đang lắng nghe...' : 'Listening...';
  String get verifying =>
      isVi ? 'Đang xác thực giọng nói...' : 'Verifying voice...';
  String get authSuccess =>
      isVi ? 'Xác thực thành công!' : 'Authentication successful!';
  String get voiceNotSupported =>
      isVi ? 'Không hỗ trợ nhận dạng giọng nói' : 'Voice recognition not supported';
  String get voiceVerifyFailed =>
      isVi ? 'Xác thực giọng nói thất bại' : 'Voice authentication failed';

  // Nav
  String get missionTime => isVi ? 'THỜI GIAN NHIỆM VỤ' : 'MISSION TIME';
  String get logout => isVi ? 'Đăng xuất' : 'Logout';
  String get control => isVi ? 'Điều Khiển' : 'Control';
  String get map => isVi ? 'Bản Đồ' : 'Map';
  String get history => isVi ? 'Lịch Sử' : 'History';

  // Voice Control
  String get systemReady => isVi ? 'Hệ thống sẵn sàng' : 'System ready';
  String get listeningCmd =>
      isVi ? 'Đang lắng nghe lệnh...' : 'Listening for commands...';
  String get enterCmd =>
      isVi ? 'Nhập lệnh điều khiển...' : 'Enter control command...';
  String get systemLabel => isVi ? 'HỆ THỐNG' : 'SYSTEM';
  String get depth => isVi ? 'ĐỘ SÂU' : 'DEPTH';
  String get speed => isVi ? 'TỐC ĐỘ' : 'SPEED';
  String get heading => isVi ? 'HƯỚNG' : 'HEADING';
  String get pressure => isVi ? 'ÁP SUẤT' : 'PRESSURE';
  String get sendingAudio => isVi ? 'Đang gửi âm thanh...' : 'Sending audio...';
  String get processingCmd => isVi ? 'Đang xử lý lệnh...' : 'Processing command...';
  String get cmdExecuted => isVi ? 'Lệnh đã thực thi' : 'Command executed';
  String get speakerFailed => isVi ? 'Xác minh người nói thất bại' : 'Speaker verification failed';
  String get roleDenied => isVi ? 'Không có quyền thực hiện lệnh' : 'Role permission denied';
  String get invalidCommand => isVi ? 'Không nhận diện được lệnh' : 'Invalid command';
  String get cmdRejected => isVi ? 'Lệnh bị từ chối' : 'Command rejected';

  // GPS
  String get currentPos => isVi ? 'VỊ TRÍ HIỆN TẠI' : 'CURRENT POSITION';

  // History
  String get historyTitle => isVi ? 'Lịch Sử Lệnh' : 'Command History';
  String get historySubtitle => isVi ? 'lệnh đã ghi lại' : 'commands recorded';
  String get searchPlaceholder =>
      isVi ? 'Tìm kiếm lệnh hoặc phản hồi...' : 'Search commands or responses...';
  String get all => isVi ? 'Tất cả' : 'All';
  String get successful => isVi ? 'Thành công' : 'Successful';
  String get unsuccessful => isVi ? 'Thất bại' : 'Unsuccessful';
  String get showing => isVi ? 'Hiển thị' : 'Showing';
  String get of => isVi ? '/' : 'of';
  String get autoRecord => isVi ? 'Ghi nhận tự động' : 'Auto recording';
  String get noCommands =>
      isVi ? 'Không tìm thấy lệnh nào' : 'No commands found';
  String get timeJustNow => isVi ? 'Vừa xong' : 'Just now';
  String get timeMinAgo => isVi ? 'phút trước' : 'min ago';
  String get timeHrAgo => isVi ? 'giờ trước' : 'hr ago';
  String get timeDayAgo => isVi ? 'ngày trước' : 'days ago';
  String get cmdId => isVi ? 'ID LỆNH' : 'COMMAND ID';
  String get statusLabel => isVi ? 'TRẠNG THÁI' : 'STATUS';
  String get timeLabel => isVi ? 'THỜI GIAN' : 'TIME';
  String get statusSuccess => isVi ? 'Thành công' : 'Success';
  String get statusWarning => isVi ? 'Cảnh báo' : 'Warning';
  String get statusError => isVi ? 'Khẩn cấp' : 'Emergency';

  // Role title translation based on role code
  String roleTitle(String? roleCode) {
    if (roleCode == null || roleCode.isEmpty) {
      return isVi ? 'Sĩ Quan' : 'Officer';
    }
    if (roleCode == 'ADMIN') {
      return isVi ? 'Quản trị' : 'Admin';
    }
    if (roleCode.startsWith('OFFICER_')) {
      final level = roleCode.split('_')[1];
      return isVi ? 'Sĩ quan $level' : 'Officer $level';
    }
    // fallback to raw code if unrecognized
    return roleCode;
  }
}
