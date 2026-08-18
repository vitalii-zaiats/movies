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
import '../../widgets/section_head.dart';
import '../../widgets/states.dart';
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
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Account')),
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

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.isGuest ? 'GUEST' : 'ACCOUNT',
                style: kicker(palette.accent),
              ),
              const SizedBox(height: 4),
              Text(user.displayName, style: heading(32, color: palette.text)),
              const SizedBox(height: 12),
              _Facts(user: user),
            ],
          ),
        ),
        if (model.said != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              model.said!,
              style: body(13, weight: 600, color: model.wentWrong ? palette.accent : palette.muted),
            ),
          ),

        const SectionHead('Your name'),
        _RenameForm(model: model, user: user),

        // A guest is one device away from losing everything they've watched;
        // this is the fix, and it keeps the row rather than starting a new one.
        if (user.isGuest) ...[
          const SectionHead('Create an account'),
          _ClaimForm(model: model),
          const SectionHead('Already have one'),
          _LoginForm(model: model),
        ],

        const SectionHead('Appearance'),
        const _ThemeChoice(),

        const SectionHead('This device'),
        _Actions(model: model, user: user),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final rows = <(String, String)>[
      if (user.hasEmail()) ('Email', user.email),
      ('Id', user.publicId),
      ('Role', user.role == Role.ROLE_ADMIN ? 'admin' : 'user'),
      ('Since', day(user.createdAt)),
      ('Last seen', day(user.lastSeenAt)),
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
                  width: 96,
                  child: Text(name.toUpperCase(), style: body(11, weight: 700, color: palette.faint)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _name,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Display name'),
              onSubmitted: widget.model.rename,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: widget.model.busy ? null : () => widget.model.rename(_name.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

/// Register. Deliberately not called "sign up" anywhere the user can see: they
/// already have an account, this gives it a way back in from another device.
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keeps everything you have watched — the email and password are '
              'written onto this same account.',
              style: body(13, color: palette.muted),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _email_,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              obscureText: _hidden,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off, size: 18),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ),
              // The server's rule, said here so a refusal doesn't cost a round
              // trip. It is still the server's rule; this only saves the trip.
              validator: (value) =>
                  (value?.length ?? 0) < 8 ? 'At least eight characters' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.model.busy ? null : _submit,
                child: const Text('CREATE ACCOUNT'),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signing in swaps this device to that account. The guest you are '
              'now stays where it is.',
              style: body(13, color: palette.muted),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _email_,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.model.busy ? null : _submit,
                child: const Text('SIGN IN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enough of a check to catch a typo, and no more — what counts as an address
/// is the server's business, and a clever pattern here only ever rejects
/// somebody's perfectly good email.
String? _email_(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Required';
  return text.contains('@') && text.contains('.') ? null : 'Doesn’t look like an email';
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<ThemeMode>(
        style: SegmentedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
        ],
        selected: {settings.value},
        showSelectedIcon: false,
        onSelectionChanged: (chosen) => settings.choose(chosen.first),
      ),
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

    return Column(
      children: [
        if (!user.isGuest)
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            subtitle: Text(
              'Back to being a guest on this device.',
              style: body(12, color: palette.muted),
            ),
            onTap: model.busy ? null : model.logout,
          ),
        ListTile(
          leading: const Icon(Icons.person_add_alt),
          title: const Text('Watch as somebody else'),
          subtitle: Text(
            'A second identity on this device, with its own history.',
            style: body(12, color: palette.muted),
          ),
          onTap: model.busy ? null : model.newGuest,
        ),
      ],
    );
  }
}
