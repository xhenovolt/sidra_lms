import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/payments/direct_payments.dart';
import '../../../core/settings/public_settings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/appearance.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../payments/data/payments_repository.dart';

String themeName(AppLocalizations l10n, String id) => switch (id) {
  'teal' => l10n.apThTeal,
  'night' => l10n.apThNight,
  'sand' => l10n.apThSand,
  'ocean' => l10n.apThOcean,
  'emerald' => l10n.apThEmerald,
  'royal' => l10n.apThRoyal,
  'rose' => l10n.apThRose,
  'gold_night' => l10n.apThGoldNight,
  'olive' => l10n.apThOlive,
  'sky' => l10n.apThSky,
  'crimson' => l10n.apThCrimson,
  _ => l10n.apThSlate,
};

String wallpaperName(AppLocalizations l10n, String id) => switch (id) {
  'dawn' => l10n.apWpDawn,
  'dunes' => l10n.apWpDunes,
  'mint' => l10n.apWpMint,
  'sky' => l10n.apWpSky,
  'dusk' => l10n.apWpDusk,
  'night_sky' => l10n.apWpNightSky,
  'forest' => l10n.apWpForest,
  _ => l10n.apWpRose,
};

/// Profile › Appearance: light or dark, themes, wallpaper and text size for
/// everyone; more themes, any colour, fonts and corners with premium themes
/// (bought once with MarzPay). The superadmin also sets everyone's look.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(appearanceProvider);
    final ctl = ref.read(appearanceProvider.notifier);
    final org =
        ref.watch(publicSettingsProvider).value ?? const PublicSettings({});
    final premium = hasPremiumThemes(ref);
    final free = freeThemeIds(org);
    final superadmin = ref.watch(
      authSessionProvider.select((s) => s.user?.isSuperadmin ?? false),
    );
    final price = int.tryParse(org.values['themes_premium_price'] ?? '');

    Widget section(String title, [String? hint]) => Padding(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (hint != null) Text(hint, style: theme.textTheme.bodySmall),
        ],
      ),
    );

    Future<void> needPremium() => showUnlockSheet(context, ref);

    Widget locked(Widget child, {required bool open}) => open
        ? child
        : Stack(
            children: [
              Opacity(opacity: 0.45, child: child),
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(Icons.lock, size: 16),
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.apTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
        children: [
          if (!premium)
            Card(
              margin: const EdgeInsets.only(top: Space.md),
              color: theme.colorScheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(l10n.apPremiumTitle),
                subtitle: Text(
                  price == null
                      ? l10n.apPremiumNotOnSale
                      : l10n.apPremiumOffer(formatMoney(price, 'UGX')),
                ),
                trailing: price == null
                    ? null
                    : FilledButton(
                        onPressed: needPremium,
                        child: Text(l10n.apUnlock),
                      ),
              ),
            ),
          if (superadmin)
            Card(
              margin: const EdgeInsets.only(top: Space.md),
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.apOrgLook),
                subtitle: Text(l10n.apOrgLookHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OrgLookScreen(),
                  ),
                ),
              ),
            ),
          section(l10n.apMode),
          SegmentedButton<String?>(
            segments: [
              ButtonSegment(value: null, label: Text(l10n.apModeOrg)),
              ButtonSegment(
                value: 'light',
                label: Text(l10n.apModeLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: 'dark',
                label: Text(l10n.apModeDark),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {me.mode == 'system' ? null : me.mode},
            onSelectionChanged: (v) => ctl.update(me.copyWith(mode: v.first)),
          ),
          section(l10n.apThemes, l10n.apThemesHint),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              _Swatch(
                color:
                    colorFromHex(org.values['theme_seed']) ??
                    SidraColors.teal700,
                label: l10n.apOrgDefault,
                selected: me.themeId == null && me.customSeed == null,
                onTap: () =>
                    ctl.update(me.copyWith(themeId: null, customSeed: null)),
              ),
              for (final t in themeOptions)
                locked(
                  _Swatch(
                    color: t.seed,
                    accent: t.accent,
                    dark: t.dark,
                    label: themeName(l10n, t.id),
                    selected: me.themeId == t.id && me.customSeed == null,
                    onTap: premium || free.contains(t.id)
                        ? () => ctl.update(
                            me.copyWith(themeId: t.id, customSeed: null),
                          )
                        : needPremium,
                  ),
                  open: premium || free.contains(t.id),
                ),
            ],
          ),
          section(l10n.apAnyColour, premium ? null : l10n.apPremiumOnly),
          locked(
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final c in colorChoices)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: premium
                        ? () => ctl.update(
                            me.copyWith(customSeed: colorHex(c), themeId: null),
                          )
                        : needPremium,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: c,
                      child: me.customSeed == colorHex(c)
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            open: premium,
          ),
          section(l10n.apWallpaper, l10n.apWallpaperHint),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              _WallTile(
                label: l10n.apOrgDefault,
                selected: me.wallpaper == null,
                onTap: () => ctl.update(me.copyWith(wallpaper: null)),
                child: const Icon(Icons.business_outlined),
              ),
              _WallTile(
                label: l10n.apWpNone,
                selected: me.wallpaper == 'none',
                onTap: () => ctl.update(me.copyWith(wallpaper: 'none')),
                child: const Icon(Icons.block),
              ),
              for (final e in wallpaperGradients.entries)
                _WallTile(
                  label: wallpaperName(l10n, e.key),
                  selected: me.wallpaper == e.key,
                  gradient: e.value,
                  onTap: () => ctl.update(me.copyWith(wallpaper: e.key)),
                ),
              _WallTile(
                label: l10n.apWpPhoto,
                selected: me.wallpaper == 'photo',
                image: me.wallpaperFile == null
                    ? null
                    : FileImage(File(me.wallpaperFile!)),
                onTap: () => _pickPhoto(context, ref),
                child: me.wallpaperFile == null
                    ? const Icon(Icons.add_photo_alternate_outlined)
                    : null,
              ),
            ],
          ),
          section(
            l10n.apCover,
            premium ? l10n.apCoverHint : l10n.apPremiumOnly,
          ),
          locked(
            Slider(
              value:
                  (me.dim ??
                          double.tryParse(org.values['theme_dim'] ?? '') ??
                          0.85)
                      .clamp(0, 0.95),
              max: 0.95,
              divisions: 19,
              onChanged: premium
                  ? (v) => ctl.update(me.copyWith(dim: v))
                  : null,
            ),
            open: premium,
          ),
          section(l10n.apTextSize),
          Row(
            children: [
              const Icon(Icons.text_decrease, size: 18),
              Expanded(
                child: Slider(
                  value: me.textScale.clamp(0.85, 1.4),
                  min: 0.85,
                  max: 1.4,
                  divisions: 11,
                  label: '${(me.textScale * 100).round()}%',
                  onChanged: (v) => ctl.update(me.copyWith(textScale: v)),
                ),
              ),
              const Icon(Icons.text_increase, size: 22),
            ],
          ),
          section(l10n.apFont, premium ? null : l10n.apPremiumOnly),
          locked(
            Wrap(
              spacing: Space.xs,
              children: [
                for (final (id, label) in [
                  (null, l10n.apOrgDefault),
                  ('lora', 'Lora'),
                  ('amiri', 'Amiri'),
                  ('system', l10n.apFontSystem),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: me.font == id,
                    onSelected: premium
                        ? (_) => ctl.update(me.copyWith(font: id))
                        : (_) => needPremium(),
                  ),
              ],
            ),
            open: premium,
          ),
          section(l10n.apCorners, premium ? null : l10n.apPremiumOnly),
          locked(
            Slider(
              value:
                  (me.radius ??
                          double.tryParse(org.values['theme_radius'] ?? '') ??
                          12)
                      .clamp(0, 28),
              max: 28,
              divisions: 14,
              onChanged: premium
                  ? (v) => ctl.update(me.copyWith(radius: v))
                  : null,
            ),
            open: premium,
          ),
          const SizedBox(height: Space.md),
          OutlinedButton.icon(
            onPressed: () => ctl.update(Appearance(textScale: me.textScale)),
            icon: const Icon(Icons.restart_alt),
            label: Text(l10n.apReset),
          ),
        ],
      ),
    );
  }

  /// A photo from the gallery, copied into Sidra's own folder (it stays on
  /// this phone).
  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final target = File(
      p.join(dir.path, 'wallpaper${p.extension(picked.path)}'),
    );
    final old = ref.read(appearanceProvider).wallpaperFile;
    // A new name each time so the picture on screen changes at once.
    final saved = await File(picked.path).copy(
      p.join(
        dir.path,
        'wallpaper-${DateTime.now().millisecondsSinceEpoch}${p.extension(target.path)}',
      ),
    );
    if (old != null && old != saved.path) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
    final me = ref.read(appearanceProvider);
    await ref
        .read(appearanceProvider.notifier)
        .update(me.copyWith(wallpaper: 'photo', wallpaperFile: saved.path));
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent,
    this.dark = false,
  });
  final Color color;
  final Color? accent;
  final bool dark;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.md),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    dark ? const Color(0xFF101614) : color,
                    accent ?? color,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _WallTile extends StatelessWidget {
  const _WallTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.gradient,
    this.image,
    this.child,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final List<Color>? gradient;
  final ImageProvider? image;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.md),
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(Radii.sm),
                gradient: gradient == null
                    ? null
                    : LinearGradient(
                        colors: gradient!,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                image: image == null
                    ? null
                    : DecorationImage(image: image!, fit: BoxFit.cover),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: child == null ? null : Center(child: child),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- unlocking --

/// Premium themes for the superadmin's price, paid with MarzPay: the prompt
/// goes to the phone, and the themes unlock once MarzPay confirms.
Future<void> showUnlockSheet(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _UnlockSheet(),
    );

class _UnlockSheet extends ConsumerStatefulWidget {
  const _UnlockSheet();

  @override
  ConsumerState<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends ConsumerState<_UnlockSheet> {
  late final _phone = TextEditingController(
    text: ref.read(authSessionProvider).user?.phone ?? '',
  );
  String? _status; // null | waiting | done | failed
  String? _error;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final api = ref.read(postgresApiProvider);
    setState(() {
      _status = 'waiting';
      _error = null;
    });
    try {
      final res = Payment.fromJson(
        Map<String, dynamic>.from(
          await api.rpc(
            'start_product_payment',
            params: {
              'p_product': 'themes_premium',
              'p_phone': _phone.text.trim(),
            },
          ) as Map,
        ),
      );
      final direct = ref.read(directPaymentsProvider);
      if (direct != null &&
          res.providerUuid == null &&
          res.reference != null &&
          res.phone != null) {
        await direct.send(
          paymentId: res.id,
          reference: res.reference!,
          amount: res.amount,
          phone: res.phone!,
          description: 'Sidra premium themes',
        );
      }
      final started = DateTime.now();
      _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          var p = Payment.fromJson(
            Map<String, dynamic>.from(
              await api.rpc(
                'my_product_payment',
                params: {'p_product': 'themes_premium'},
              ) as Map,
            ),
          );
          if (p.awaitingPayer && p.providerUuid != null && direct != null) {
            final checked = await direct.check(
              paymentId: p.id,
              providerUuid: p.providerUuid!,
              reference: p.reference!,
            );
            if (checked != null) p = Payment.fromJson(checked);
          }
          if (!mounted) return;
          if (p.status == PaymentStatus.verified) {
            _poll?.cancel();
            ref.invalidate(entitlementsProvider);
            setState(() => _status = 'done');
          } else if (p.status == PaymentStatus.failed ||
              p.status == PaymentStatus.rejected) {
            _poll?.cancel();
            setState(() => _status = 'failed');
          } else if (DateTime.now().difference(started) >
              const Duration(minutes: 4)) {
            _poll?.cancel();
            setState(() => _status = 'failed');
          }
        } catch (_) {
          // keep trying until the time is up
        }
      });
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _status = null;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = null;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final org =
        ref.watch(publicSettingsProvider).value ?? const PublicSettings({});
    final price = int.tryParse(org.values['themes_premium_price'] ?? '');
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.apPremiumTitle, style: theme.textTheme.titleLarge),
          Text(l10n.apPremiumWhat, style: theme.textTheme.bodySmall),
          const SizedBox(height: Space.md),
          if (price == null)
            Text(l10n.apPremiumNotOnSale)
          else if (_status == 'done')
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(l10n.apUnlocked),
            )
          else if (_status == 'waiting')
            ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(l10n.payCheckPhoneTitle),
              subtitle: Text(l10n.apApprove(formatMoney(price, 'UGX'))),
            )
          else ...[
            if (_status == 'failed')
              Text(
                l10n.payFailedBody,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.payPhoneLabel),
            ),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: _pay,
              icon: const Icon(Icons.phone_android),
              label: Text(l10n.apPay(formatMoney(price, 'UGX'))),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------- organisation look --

/// Superadmin only: the look every phone starts with, which themes are free
/// and the price of premium themes.
class OrgLookScreen extends ConsumerStatefulWidget {
  const OrgLookScreen({super.key});

  @override
  ConsumerState<OrgLookScreen> createState() => _OrgLookScreenState();
}

class _OrgLookScreenState extends ConsumerState<OrgLookScreen> {
  late final Map<String, String?> _v = {
    ...((ref.read(publicSettingsProvider).value ?? const PublicSettings({}))
        .values),
  };
  late final _price = TextEditingController(
    text: _v['themes_premium_price'] ?? '',
  );
  late final _url = TextEditingController(
    text: _v['theme_wallpaper_url'] ?? '',
  );
  bool _saving = false;

  Set<String> get _free => freeThemeIds(PublicSettings(_v));

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(postgresApiProvider)
          .rpc(
            'set_display_settings',
            params: {
              'p_values': {
                for (final k in const [
                  'theme_seed',
                  'theme_accent',
                  'theme_mode',
                  'theme_font',
                  'theme_radius',
                  'theme_wallpaper',
                  'theme_dim',
                  'theme_free_ids',
                ])
                  k: _v[k] ?? '',
                'theme_wallpaper_url': _url.text.trim(),
                'themes_premium_price': _price.text.trim(),
              },
            },
          );
      ref.invalidate(publicSettingsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminSaved)));
    } on AppFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget section(String t) => Padding(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
      child: Text(t, style: theme.textTheme.titleMedium),
    );
    Widget colours(String key) => Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final c in colorChoices)
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => setState(() => _v[key] = colorHex(c)),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: c,
              child: _v[key] == colorHex(c)
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.apOrgLook),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.adminSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Space.md),
            child: Text(l10n.apOrgLookIntro, style: theme.textTheme.bodySmall),
          ),
          section(l10n.apMainColour),
          colours('theme_seed'),
          section(l10n.apAccentColour),
          colours('theme_accent'),
          section(l10n.apMode),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'system', label: Text(l10n.apModeSystem)),
              ButtonSegment(value: 'light', label: Text(l10n.apModeLight)),
              ButtonSegment(value: 'dark', label: Text(l10n.apModeDark)),
            ],
            selected: {_v['theme_mode'] ?? 'system'},
            onSelectionChanged: (v) =>
                setState(() => _v['theme_mode'] = v.first),
          ),
          section(l10n.apFont),
          Wrap(
            spacing: Space.xs,
            children: [
              for (final (id, label) in [
                ('lora', 'Lora'),
                ('amiri', 'Amiri'),
                ('system', l10n.apFontSystem),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: (_v['theme_font'] ?? 'lora') == id,
                  onSelected: (_) => setState(() => _v['theme_font'] = id),
                ),
            ],
          ),
          section(l10n.apCorners),
          Slider(
            value: (double.tryParse(_v['theme_radius'] ?? '') ?? 12).clamp(
              0,
              28,
            ),
            max: 28,
            divisions: 14,
            label: _v['theme_radius'] ?? '12',
            onChanged: (v) =>
                setState(() => _v['theme_radius'] = '${v.round()}'),
          ),
          section(l10n.apWallpaper),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              _WallTile(
                label: l10n.apWpNone,
                selected: _v['theme_wallpaper'] == null,
                onTap: () => setState(() => _v['theme_wallpaper'] = null),
                child: const Icon(Icons.block),
              ),
              for (final e in wallpaperGradients.entries)
                _WallTile(
                  label: wallpaperName(l10n, e.key),
                  selected: _v['theme_wallpaper'] == e.key,
                  gradient: e.value,
                  onTap: () => setState(() => _v['theme_wallpaper'] = e.key),
                ),
            ],
          ),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.apWallpaperLink,
              hintText: 'https://…',
            ),
          ),
          section(l10n.apCover),
          Slider(
            value: (double.tryParse(_v['theme_dim'] ?? '') ?? 0.85).clamp(
              0,
              0.95,
            ),
            max: 0.95,
            divisions: 19,
            onChanged: (v) =>
                setState(() => _v['theme_dim'] = v.toStringAsFixed(2)),
          ),
          section(l10n.apFreeThemes),
          Wrap(
            spacing: Space.xs,
            children: [
              for (final t in themeOptions)
                FilterChip(
                  label: Text(themeName(l10n, t.id)),
                  avatar: CircleAvatar(backgroundColor: t.seed),
                  selected: _free.contains(t.id),
                  onSelected: (on) => setState(() {
                    final set = {..._free};
                    on ? set.add(t.id) : set.remove(t.id);
                    _v['theme_free_ids'] = set.join(',');
                  }),
                ),
            ],
          ),
          section(l10n.apPremiumPrice),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.payAmountLabel('UGX'),
              helperText: l10n.apPremiumPriceHint,
            ),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    );
  }
}
