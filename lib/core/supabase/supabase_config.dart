class SupabaseConfig {
  const SupabaseConfig._();

  static const _defaultUrl = 'https://mkdacnbbvjgekosdhevw.supabase.co';
  static const _defaultPublishableKey =
      'sb_publishable_dpm-U61n41ih8DM8vGyNhQ_fMSyt5WL';

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: _defaultPublishableKey,
    ),
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
