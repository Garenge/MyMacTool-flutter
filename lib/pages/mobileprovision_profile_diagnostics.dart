import 'mobileprovision_profile_info.dart';

enum ProfileDiagnosticSeverity {
  ok('通过'),
  info('提示'),
  warning('注意'),
  error('风险');

  const ProfileDiagnosticSeverity(this.label);

  final String label;
}

enum BundleIdentifierMatchKind { exact, wildcard, mismatch, unknown }

class BundleIdentifierMatchResult {
  const BundleIdentifierMatchResult({
    required this.kind,
    required this.appBundleIdentifier,
    required this.profileBundleIdentifier,
  });

  final BundleIdentifierMatchKind kind;
  final String appBundleIdentifier;
  final String profileBundleIdentifier;

  bool get isMatched {
    return kind == BundleIdentifierMatchKind.exact ||
        kind == BundleIdentifierMatchKind.wildcard;
  }

  String get label {
    switch (kind) {
      case BundleIdentifierMatchKind.exact:
        return '完全匹配';
      case BundleIdentifierMatchKind.wildcard:
        return '通配符匹配';
      case BundleIdentifierMatchKind.mismatch:
        return '未匹配';
      case BundleIdentifierMatchKind.unknown:
        return '无法判断';
    }
  }

  String get detail {
    switch (kind) {
      case BundleIdentifierMatchKind.exact:
        return 'IPA Bundle ID 与 Profile Bundle ID 完全一致。';
      case BundleIdentifierMatchKind.wildcard:
        return 'Profile 使用通配符覆盖当前 IPA Bundle ID。';
      case BundleIdentifierMatchKind.mismatch:
        return 'IPA Bundle ID 与 Profile Bundle ID 不一致。';
      case BundleIdentifierMatchKind.unknown:
        return '缺少 IPA 或 Profile Bundle ID，无法判断匹配关系。';
    }
  }

  static BundleIdentifierMatchResult evaluate({
    required String? appBundleIdentifier,
    required String? profileBundleIdentifier,
  }) {
    final appId = appBundleIdentifier?.trim() ?? '';
    final profileId = profileBundleIdentifier?.trim() ?? '';

    if (appId.isEmpty || profileId.isEmpty) {
      return BundleIdentifierMatchResult(
        kind: BundleIdentifierMatchKind.unknown,
        appBundleIdentifier: appId,
        profileBundleIdentifier: profileId,
      );
    }

    if (appId == profileId) {
      return BundleIdentifierMatchResult(
        kind: BundleIdentifierMatchKind.exact,
        appBundleIdentifier: appId,
        profileBundleIdentifier: profileId,
      );
    }

    if (_matchesWildcard(appId, profileId)) {
      return BundleIdentifierMatchResult(
        kind: BundleIdentifierMatchKind.wildcard,
        appBundleIdentifier: appId,
        profileBundleIdentifier: profileId,
      );
    }

    return BundleIdentifierMatchResult(
      kind: BundleIdentifierMatchKind.mismatch,
      appBundleIdentifier: appId,
      profileBundleIdentifier: profileId,
    );
  }

  static bool _matchesWildcard(String appId, String profileId) {
    if (profileId == '*') {
      return true;
    }

    if (profileId.endsWith('.*')) {
      final prefix = profileId.substring(0, profileId.length - 1);
      return appId.startsWith(prefix) && appId.length > prefix.length;
    }

    if (profileId.endsWith('*')) {
      final prefix = profileId.substring(0, profileId.length - 1);
      return prefix.isNotEmpty && appId.startsWith(prefix);
    }

    return false;
  }
}

class ProfileDiagnosticItem {
  const ProfileDiagnosticItem({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final ProfileDiagnosticSeverity severity;
}

class MobileProvisionProfileDiagnostics {
  const MobileProvisionProfileDiagnostics({
    required this.bundleIdentifierMatch,
    required this.items,
  });

  final BundleIdentifierMatchResult bundleIdentifierMatch;
  final List<ProfileDiagnosticItem> items;

  int get riskCount {
    return items
        .where(
          (ProfileDiagnosticItem item) =>
              item.severity == ProfileDiagnosticSeverity.error,
        )
        .length;
  }

  int get warningCount {
    return items
        .where(
          (ProfileDiagnosticItem item) =>
              item.severity == ProfileDiagnosticSeverity.warning,
        )
        .length;
  }

  String get summaryText {
    if (riskCount > 0 || warningCount > 0) {
      final parts = <String>[
        if (riskCount > 0) '$riskCount 个风险',
        if (warningCount > 0) '$warningCount 个注意项',
      ];
      return parts.join('，');
    }

    return '未发现明显签名风险';
  }

  List<ProfileDiagnosticItem> get notableItems {
    final important = items
        .where(
          (ProfileDiagnosticItem item) =>
              item.severity == ProfileDiagnosticSeverity.error ||
              item.severity == ProfileDiagnosticSeverity.warning,
        )
        .toList();

    if (important.isNotEmpty) {
      return important;
    }

    return items.take(3).toList();
  }

  String get notableText {
    return notableItems
        .map((ProfileDiagnosticItem item) => '${item.title}：${item.message}')
        .join('\n');
  }

  factory MobileProvisionProfileDiagnostics.evaluate(
    MobileProvisionProfileInfo profile, {
    String? appBundleIdentifier,
    DateTime? now,
  }) {
    final bundleIdentifierMatch = BundleIdentifierMatchResult.evaluate(
      appBundleIdentifier: appBundleIdentifier,
      profileBundleIdentifier: profile.bundleIdentifier,
    );
    final items = <ProfileDiagnosticItem>[
      _buildBundleIdentifierItem(
        profile: profile,
        appBundleIdentifier: appBundleIdentifier,
        match: bundleIdentifierMatch,
      ),
      _buildExpirationItem(profile, now ?? DateTime.now()),
      ..._buildTeamIdentifierItems(profile),
      ..._buildEntitlementItems(profile),
    ];

    return MobileProvisionProfileDiagnostics(
      bundleIdentifierMatch: bundleIdentifierMatch,
      items: items,
    );
  }

  static ProfileDiagnosticItem _buildBundleIdentifierItem({
    required MobileProvisionProfileInfo profile,
    required String? appBundleIdentifier,
    required BundleIdentifierMatchResult match,
  }) {
    final appId = appBundleIdentifier?.trim() ?? '';
    final profileId = profile.bundleIdentifier?.trim() ?? '';

    if (appId.isEmpty) {
      return _buildProfileBundleIdentifierItem(profileId);
    }

    switch (match.kind) {
      case BundleIdentifierMatchKind.exact:
        return ProfileDiagnosticItem(
          title: 'Bundle ID',
          message: 'IPA $appId 与 Profile 完全匹配。',
          severity: ProfileDiagnosticSeverity.ok,
        );
      case BundleIdentifierMatchKind.wildcard:
        return ProfileDiagnosticItem(
          title: 'Bundle ID',
          message: 'Profile $profileId 通过通配符覆盖 IPA $appId。',
          severity: ProfileDiagnosticSeverity.warning,
        );
      case BundleIdentifierMatchKind.mismatch:
        return ProfileDiagnosticItem(
          title: 'Bundle ID',
          message: 'IPA $appId 与 Profile ${_valueOrDash(profileId)} 不一致。',
          severity: ProfileDiagnosticSeverity.error,
        );
      case BundleIdentifierMatchKind.unknown:
        return const ProfileDiagnosticItem(
          title: 'Bundle ID',
          message: '缺少 IPA 或 Profile Bundle ID，无法判断是否可安装。',
          severity: ProfileDiagnosticSeverity.warning,
        );
    }
  }

  static ProfileDiagnosticItem _buildProfileBundleIdentifierItem(
    String profileId,
  ) {
    if (profileId.isEmpty) {
      return const ProfileDiagnosticItem(
        title: 'Bundle ID',
        message: 'Profile 未声明 Bundle ID，需回到原包检查签名链路。',
        severity: ProfileDiagnosticSeverity.warning,
      );
    }

    if (profileId.contains('*')) {
      return ProfileDiagnosticItem(
        title: 'Bundle ID',
        message: 'Profile 使用通配符 $profileId，部分 App 能力可能受限制。',
        severity: ProfileDiagnosticSeverity.warning,
      );
    }

    return ProfileDiagnosticItem(
      title: 'Bundle ID',
      message: 'Profile 绑定到 $profileId。',
      severity: ProfileDiagnosticSeverity.ok,
    );
  }

  static ProfileDiagnosticItem _buildExpirationItem(
    MobileProvisionProfileInfo profile,
    DateTime now,
  ) {
    final expirationDate = profile.expirationDate;

    if (expirationDate == null) {
      return const ProfileDiagnosticItem(
        title: '有效期',
        message: '未读取到过期时间。',
        severity: ProfileDiagnosticSeverity.warning,
      );
    }

    final remaining = expirationDate.difference(now);

    if (remaining.isNegative) {
      return const ProfileDiagnosticItem(
        title: '有效期',
        message: 'Profile 已过期，安装或重签会失败。',
        severity: ProfileDiagnosticSeverity.error,
      );
    }

    final days = remaining.inDays;

    if (days <= 30) {
      return ProfileDiagnosticItem(
        title: '有效期',
        message: 'Profile 将在 $days 天内过期。',
        severity: ProfileDiagnosticSeverity.warning,
      );
    }

    return ProfileDiagnosticItem(
      title: '有效期',
      message: 'Profile 还有 $days 天过期。',
      severity: ProfileDiagnosticSeverity.ok,
    );
  }

  static List<ProfileDiagnosticItem> _buildTeamIdentifierItems(
    MobileProvisionProfileInfo profile,
  ) {
    final entitlementTeamId = _stringEntitlement(
      profile,
      'com.apple.developer.team-identifier',
    );

    if (entitlementTeamId == null || profile.teamIdentifiers.isEmpty) {
      return const <ProfileDiagnosticItem>[];
    }

    if (profile.teamIdentifiers.contains(entitlementTeamId)) {
      return <ProfileDiagnosticItem>[
        ProfileDiagnosticItem(
          title: 'Team ID',
          message: 'Entitlements Team ID 与 Profile Team ID 一致。',
          severity: ProfileDiagnosticSeverity.ok,
        ),
      ];
    }

    return <ProfileDiagnosticItem>[
      ProfileDiagnosticItem(
        title: 'Team ID',
        message:
            'Entitlements Team ID $entitlementTeamId 不在 Profile Team ID 中。',
        severity: ProfileDiagnosticSeverity.error,
      ),
    ];
  }

  static List<ProfileDiagnosticItem> _buildEntitlementItems(
    MobileProvisionProfileInfo profile,
  ) {
    final items = <ProfileDiagnosticItem>[];

    if (profile.entitlements.isEmpty) {
      return const <ProfileDiagnosticItem>[
        ProfileDiagnosticItem(
          title: 'Entitlements',
          message: '未读取到权限声明。',
          severity: ProfileDiagnosticSeverity.warning,
        ),
      ];
    }

    items.add(_buildDebugEntitlementItem(profile));
    items.addAll(_buildPushEntitlementItems(profile));
    items.addAll(_buildCapabilityCountItems(profile));

    return items;
  }

  static ProfileDiagnosticItem _buildDebugEntitlementItem(
    MobileProvisionProfileInfo profile,
  ) {
    final getTaskAllow = _boolEntitlement(profile, 'get-task-allow');

    if (getTaskAllow == true) {
      return const ProfileDiagnosticItem(
        title: '调试权限',
        message: 'get-task-allow=true，适合开发或 Ad Hoc，发布前需要确认。',
        severity: ProfileDiagnosticSeverity.warning,
      );
    }

    if (getTaskAllow == false) {
      return const ProfileDiagnosticItem(
        title: '调试权限',
        message: 'get-task-allow=false，调试权限已关闭。',
        severity: ProfileDiagnosticSeverity.ok,
      );
    }

    return const ProfileDiagnosticItem(
      title: '调试权限',
      message: '未声明 get-task-allow。',
      severity: ProfileDiagnosticSeverity.info,
    );
  }

  static List<ProfileDiagnosticItem> _buildPushEntitlementItems(
    MobileProvisionProfileInfo profile,
  ) {
    final pushEnvironment = _stringEntitlement(profile, 'aps-environment');

    if (pushEnvironment == null || pushEnvironment.isEmpty) {
      return const <ProfileDiagnosticItem>[];
    }

    final severity = pushEnvironment == 'development'
        ? ProfileDiagnosticSeverity.warning
        : ProfileDiagnosticSeverity.info;

    return <ProfileDiagnosticItem>[
      ProfileDiagnosticItem(
        title: '推送环境',
        message: 'aps-environment=$pushEnvironment。',
        severity: severity,
      ),
    ];
  }

  static List<ProfileDiagnosticItem> _buildCapabilityCountItems(
    MobileProvisionProfileInfo profile,
  ) {
    final items = <ProfileDiagnosticItem>[];

    _addListCapabilityItem(
      items,
      profile,
      key: 'com.apple.developer.associated-domains',
      title: 'Associated Domains',
    );
    _addListCapabilityItem(
      items,
      profile,
      key: 'com.apple.security.application-groups',
      title: 'App Groups',
    );
    _addListCapabilityItem(
      items,
      profile,
      key: 'keychain-access-groups',
      title: 'Keychain Groups',
    );

    return items;
  }

  static void _addListCapabilityItem(
    List<ProfileDiagnosticItem> items,
    MobileProvisionProfileInfo profile, {
    required String key,
    required String title,
  }) {
    final values = _stringListEntitlement(profile, key);

    if (values.isEmpty) {
      return;
    }

    items.add(
      ProfileDiagnosticItem(
        title: title,
        message: '${values.length} 项：${_previewValues(values)}',
        severity: ProfileDiagnosticSeverity.info,
      ),
    );
  }

  static bool? _boolEntitlement(
    MobileProvisionProfileInfo profile,
    String key,
  ) {
    final value = profile.entitlements[key];
    return value is bool ? value : null;
  }

  static String? _stringEntitlement(
    MobileProvisionProfileInfo profile,
    String key,
  ) {
    final value = profile.entitlements[key];
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  static List<String> _stringListEntitlement(
    MobileProvisionProfileInfo profile,
    String key,
  ) {
    final value = profile.entitlements[key];

    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  static String _previewValues(List<String> values) {
    final preview = values.take(3).join(', ');

    if (values.length <= 3) {
      return preview;
    }

    return '$preview 等';
  }

  static String _valueOrDash(String value) {
    return value.isEmpty ? '-' : value;
  }
}
