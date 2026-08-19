/// Who you are, and how to stop being a guest.
///
/// There is no signed-out state to draw: the catalogue hands everybody an
/// identity on first contact, so this screen always has somebody to describe.
/// What changes is what you can do next — a guest can register or sign in, an
/// account can sign out — and registering keeps the row, so nothing watched so
/// far is lost by doing it.
library;

import 'package:flutter/material.dart';
import 'package:kino_api/kino_api.dart';

import '../../app.dart';
import '../../core/async_value.dart';
import '../../core/formatting.dart';
import '../../core/kino.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/glyph.dart';
import '../../widgets/section_head.dart';
import '../../widgets/states.dart';
import '../welcome/welcome_screen.dart';
import 'account_view_model.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountViewModel _model;

  @override
  void initState() {
    super.initState();
    _model = AccountViewModel(Kino.read(context))..load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.account)),
        body: switch (_model.state) {
          Loading<User>() => const Spinner(),
          Failure<User>(:final error) => Failed(error: error, onRetry: _model.load),
          Data<User>(:final value) => _Body(model: _model, user: value),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.model, required this.user});

  final AccountViewModel model;
  final User user;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (user.isGuest ? l10n.guest : l10n.account).toUpperCase(),
                style: kicker(palette.accent),
              ),
              const SizedBox(height: 4),
              Text(user.displayName, style: heading(32, color: palette.text)),
              const SizedBox(height: 12),
              _Facts(user: user),
            ],
          ),
        ),
        if (model.note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _Said(note: model.note!),
          ),

        SectionHead(l10n.yourName),
        _RenameForm(model: model, user: user),

        // A guest is one device away from losing everything they have watched;
        // these are the fixes, and both keep the row rather than starting a new
        // one. Which comes first depends on what is being held: a remote makes
        // the forms below miserable and the phone one obvious.
        if (user.isGuest) ...[
          if (Kino.isTv(context)) ...[
            SectionHead(l10n.linkDevice),
            _LinkTile(model: model),
          ],
          SectionHead(l10n.createAnAccount),
          _ClaimForm(model: model),
          SectionHead(l10n.alreadyHaveOne),
          _LoginForm(model: model),
          if (!Kino.isTv(context)) ...[
            SectionHead(l10n.linkDevice),
            _LinkTile(model: model),
          ],
        ],

        SectionHead(l10n.appearance),
        const _ThemeChoice(),
        SectionHead(l10n.language),
        const _LanguageChoice(),

        SectionHead(l10n.thisDevice),
        _Actions(model: model, user: user),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// The last thing that happened, in the reader's language — the view model
/// reports facts, and this is where they become sentences.
class _Said extends StatelessWidget {
  const _Said({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    final (text, wrong) = switch (note) {
      Done(:final did, :final detail) => (
          switch (did) {
            Did.renamed => l10n.renamed(detail),
            Did.created => l10n.accountCreated(detail),
            Did.signedIn => l10n.signedInAs(detail),
            Did.signedOut => l10n.signedOut,
            Did.switched => l10n.nowWatchingAs(detail),
          },
          false,
        ),
      Refused(:final problem) => ('$problem', true),
    };

    return Text(
      text,
      style: body(13, weight: 600, color: wrong ? palette.accent : palette.muted),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    final rows = <(String, String)>[
      if (user.hasEmail()) (l10n.labelEmail, user.email),
      (l10n.labelId, user.publicId),
      (l10n.labelRole, user.role == Role.ROLE_ADMIN ? l10n.roleAdmin : l10n.roleUser),
      (l10n.labelSince, day(user.createdAt)),
      (l10n.labelLastSeen, day(user.lastSeenAt)),
    ];

    return Column(
      children: [
        for (final (name, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  child: Text(
                    name.toUpperCase(),
                    style: body(11, weight: 700, color: palette.faint),
                  ),
                ),
                Expanded(child: Text(value, style: body(13, color: palette.text))),
              ],
            ),
          ),
      ],
    );
  }
}

class _RenameForm extends StatefulWidget {
  const _RenameForm({required this.model, required this.user});

  final AccountViewModel model;
  final User user;

  @override
  State<_RenameForm> createState() => _RenameFormState();
}

class _RenameFormState extends State<_RenameForm> {
  late final _name = TextEditingController(text: widget.user.displayName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _name,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.displayName),
              onSubmitted: widget.model.rename,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: widget.model.busy ? null : () => widget.model.rename(_name.text),
            child: Text(l10n.save.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

/// Register. Not called "sign up" anywhere the reader can see it: they already
/// have an account, and this gives it a way back in from another device.
class _ClaimForm extends StatefulWidget {
  const _ClaimForm({required this.model});

  final AccountViewModel model;

  @override
  State<_ClaimForm> createState() => _ClaimFormState();
}

class _ClaimFormState extends State<_ClaimForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState?.validate() ?? false) {
      widget.model.claim(email: _email.text, password: _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.createAccountBlurb, style: body(13, color: palette.muted)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: l10n.labelEmail),
              validator: (value) => _email_(value, l10n),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              obscureText: _hidden,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l10n.password,
                suffixIcon: IconButton(
                  icon: Glyph(_hidden ? Glyphs.eye : Glyphs.eyeShut, size: 18),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ),
              // The server's rule, said here so a refusal doesn't cost a round
              // trip. It is still the server's rule; this only saves the trip.
              validator: (value) => (value?.length ?? 0) < 8 ? l10n.shortPassword : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.model.busy ? null : _submit,
                child: Text(l10n.createAccount.toUpperCase()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.model});

  final AccountViewModel model;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState?.validate() ?? false) {
      widget.model.login(email: _email.text, password: _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.signInBlurb, style: body(13, color: palette.muted)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: l10n.labelEmail),
              validator: (value) => _email_(value, l10n),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(labelText: l10n.password),
              validator: (value) => (value?.isEmpty ?? true) ? l10n.fieldRequired : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.model.busy ? null : _submit,
                child: Text(l10n.signIn.toUpperCase()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enough of a check to catch a typo, and no more — what counts as an address is
/// the server's business, and a clever pattern here only ever rejects somebody's
/// perfectly good email.
String? _email_(String? value, AppLocalizations l10n) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return l10n.fieldRequired;
  return text.contains('@') && text.contains('.') ? null : l10n.notAnEmail;
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<ThemeMode>(
        style: SegmentedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        segments: [
          ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
          ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
          ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
        ],
        selected: {settings.theme},
        showSelectedIcon: false,
        onSelectionChanged: (chosen) => settings.chooseTheme(chosen.first),
      ),
    );
  }
}

/// Which language, with "the one the phone is set to" as its own option rather
/// than as a hidden default — a reader who picks Ukrainian on an English phone
/// should keep it, and one who picks nothing should follow the phone.
class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        segments: [
          ButtonSegment(value: '', label: Text(l10n.languageSystem)),
          // Named in themselves, always: a reader looking for their own language
          // should not have to read another one to find it.
          const ButtonSegment(value: 'uk', label: Text('Українська')),
          const ButtonSegment(value: 'en', label: Text('English')),
        ],
        selected: {settings.locale?.languageCode ?? ''},
        showSelectedIcon: false,
        onSelectionChanged: (chosen) => settings.chooseLocale(
          chosen.first.isEmpty ? null : Locale(chosen.first),
        ),
      ),
    );
  }
}

/// Sign in without typing: a code here, approved in a browser there.
class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.model});

  final AccountViewModel model;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return ListTile(
      leading: const Glyph(Glyphs.share),
      title: Text(l10n.signInOnAnotherDevice),
      subtitle: Text(l10n.signInOnAnotherDeviceBlurb, style: body(12, color: palette.muted)),
      onTap: () async {
        final linked = await Navigator.of(context).push<User>(
          MaterialPageRoute(builder: (_) => const LinkScreen()),
        );
        // Somebody said yes: this device is a different person now, and this
        // screen is still describing the old one.
        if (linked == null || !context.mounted) return;
        await model.load();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.linkedAs(linked.displayName))));
        }
      },
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.model, required this.user});

  final AccountViewModel model;
  final User user;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        if (!user.isGuest)
          ListTile(
            leading: const Glyph(Glyphs.out),
            title: Text(l10n.signOut),
            subtitle: Text(l10n.signOutBlurb, style: body(12, color: palette.muted)),
            onTap: model.busy ? null : model.logout,
          ),
        ListTile(
          leading: const Glyph(Glyphs.newPerson),
          title: Text(l10n.watchAsSomebodyElse),
          subtitle: Text(l10n.watchAsBlurb, style: body(12, color: palette.muted)),
          onTap: model.busy ? null : model.newGuest,
        ),
      ],
    );
  }
}
