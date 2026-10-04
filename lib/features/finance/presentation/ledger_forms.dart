import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../admin/presentation/admin_common.dart';
import '../../payments/data/payments_repository.dart' show formatMoney;
import '../data/ledger_repository.dart';

// ------------------------------------------------------------- pieces --

String accountTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'asset' => l10n.lgTypeAsset,
  'liability' => l10n.lgTypeLiability,
  'equity' => l10n.lgTypeEquity,
  'income' => l10n.lgTypeIncome,
  _ => l10n.lgTypeExpense,
};

/// Chooses one account from the chart (only those [filter] allows).
Future<LedgerAccount?> pickAccount(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required bool Function(LedgerAccount a) filter,
}) async {
  final all = await ref.read(ledgerAccountsProvider.future);
  if (!context.mounted) return null;
  final choices = [
    for (final a in all)
      if (a.isActive && filter(a)) a,
  ];
  return showDialog<LedgerAccount>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return SimpleDialog(
        title: Text(title),
        children: [
          if (choices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Text(l10n.lgNoAccounts),
            ),
          for (final a in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, a),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.name),
                subtitle: Text('${a.code} · ${accountTypeLabel(l10n, a.type)}'),
                trailing: a.isMoney
                    ? Text(formatMoney(a.balance, 'UGX'))
                    : null,
              ),
            ),
        ],
      );
    },
  );
}

bool isMoneyAccount(LedgerAccount a) => a.isMoney;
bool isExpenseAccount(LedgerAccount a) => a.type == 'expense';

/// One field of a [LedgerForm].
sealed class LedgerField {
  const LedgerField(this.key, this.label, {this.required = true});
  final String key;
  final String label;
  final bool required;
}

class AccountField extends LedgerField {
  const AccountField(super.key, super.label, this.filter, {this.initial});
  final bool Function(LedgerAccount a) filter;
  final LedgerAccount? initial;
}

class AmountField extends LedgerField {
  const AmountField(
    super.key,
    super.label, {
    super.required,
    this.allowZero = false,
  });
  final bool allowZero;
}

class DateField extends LedgerField {
  const DateField(
    super.key,
    super.label, {
    super.required,
    this.future = false,
  });
  final bool future;
}

class TextLedgerField extends LedgerField {
  const TextLedgerField(
    super.key,
    super.label, {
    super.required = false,
    this.hint,
  });
  final String? hint;
}

class WholeNumberField extends LedgerField {
  const WholeNumberField(
    super.key,
    super.label, {
    super.required = false,
    this.hint,
  });
  final String? hint;
}

class SwitchLedgerField extends LedgerField {
  const SwitchLedgerField(super.key, super.label, {this.hint})
    : super(required: false);
  final String? hint;
}

/// A bottom-sheet form for one finance action: fill the fields, save, the
/// database checks and posts it. Pops with true after a successful save.
class LedgerForm extends ConsumerStatefulWidget {
  const LedgerForm({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    this.intro,
  });

  final String title;
  final String? intro;
  final List<LedgerField> fields;
  final Future<void> Function(Map<String, Object?> values) onSave;

  @override
  ConsumerState<LedgerForm> createState() => _LedgerFormState();
}

class _LedgerFormState extends ConsumerState<LedgerForm> {
  final _form = GlobalKey<FormState>();
  final _values = <String, Object?>{};
  final _text = <String, TextEditingController>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      switch (f) {
        case AccountField(:final initial) when initial != null:
          _values[f.key] = initial;
        case DateField(required: true):
          _values[f.key] = DateTime.now();
        case SwitchLedgerField():
          _values[f.key] = false;
        case AmountField() || TextLedgerField() || WholeNumberField():
          _text[f.key] = TextEditingController();
        default:
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_form.currentState!.validate()) return;
    for (final f in widget.fields) {
      if (f is AccountField && _values[f.key] == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.lgChoose(f.label))));
        return;
      }
    }
    final values = <String, Object?>{..._values};
    for (final f in widget.fields) {
      final t = _text[f.key]?.text.trim() ?? '';
      switch (f) {
        case AmountField():
          values[f.key] = t.isEmpty
              ? null
              : double.parse(t.replaceAll(',', ''));
        case WholeNumberField():
          values[f.key] = t.isEmpty ? null : int.parse(t);
        case TextLedgerField():
          values[f.key] = t.isEmpty ? null : t;
        default:
      }
    }
    setState(() => _saving = true);
    final ok = await runAdminAction(
      context,
      () => widget.onSave(values),
      success: l10n.adminSaved,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            if (widget.intro != null) ...[
              const SizedBox(height: Space.xs),
              Text(widget.intro!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: Space.sm),
            for (final f in widget.fields)
              switch (f) {
                AccountField() => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance_outlined),
                  title: Text(
                    (_values[f.key] as LedgerAccount?)?.name ?? f.label,
                  ),
                  subtitle: _values[f.key] == null ? null : Text(f.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final a = await pickAccount(
                      context,
                      ref,
                      title: f.label,
                      filter: f.filter,
                    );
                    if (a != null) setState(() => _values[f.key] = a);
                  },
                ),
                AmountField(:final allowZero) => TextFormField(
                  controller: _text[f.key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: f.label),
                  validator: (v) {
                    final t = (v ?? '').trim().replaceAll(',', '');
                    if (t.isEmpty) {
                      return f.required ? l10n.fieldRequired : null;
                    }
                    final n = double.tryParse(t);
                    if (n == null || n < 0 || (!allowZero && n == 0)) {
                      return l10n.payAmountInvalid;
                    }
                    return null;
                  },
                ),
                DateField(:final future) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(
                    _values[f.key] == null
                        ? f.label
                        : date.format(_values[f.key]! as DateTime),
                  ),
                  subtitle: _values[f.key] == null ? null : Text(f.label),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate:
                          (_values[f.key] as DateTime?) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: future
                          ? DateTime.now().add(const Duration(days: 730))
                          : DateTime.now(),
                    );
                    if (d != null) setState(() => _values[f.key] = d);
                  },
                ),
                TextLedgerField(:final hint) => TextFormField(
                  controller: _text[f.key],
                  decoration: InputDecoration(
                    labelText: f.label,
                    hintText: hint,
                  ),
                  validator: (v) => f.required && (v?.trim().isEmpty ?? true)
                      ? l10n.fieldRequired
                      : null,
                ),
                WholeNumberField(:final hint) => TextFormField(
                  controller: _text[f.key],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: f.label,
                    hintText: hint,
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) {
                      return f.required ? l10n.fieldRequired : null;
                    }
                    return (int.tryParse(t) ?? 0) > 0
                        ? null
                        : l10n.payAmountInvalid;
                  },
                ),
                SwitchLedgerField(:final hint) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _values[f.key] == true,
                  onChanged: (v) => setState(() => _values[f.key] = v),
                  title: Text(f.label),
                  subtitle: hint == null ? null : Text(hint),
                ),
              },
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.adminSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [child] as a bottom sheet; true when something was saved.
Future<bool> showLedgerSheet(BuildContext context, Widget child) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => child,
    ) ??
    false;

DateTime _date(Map<String, Object?> v, String key) =>
    (v[key] as DateTime?) ?? DateTime.now();
LedgerAccount _acct(Map<String, Object?> v, String key) =>
    v[key]! as LedgerAccount;
double _amount(Map<String, Object?> v, String key) => v[key]! as double;

// ------------------------------------------------------------ actions --

/// The things finance staff do with the books.
enum LedgerAction { expense, moneyIn, moneyOut, transfer, bill, asset, count }

/// Opens the form for [action]; true when it was saved (refresh screens).
Future<bool> runLedgerAction(
  BuildContext context,
  WidgetRef ref,
  LedgerAction action, {
  LedgerAccount? account,
}) async {
  final l10n = AppLocalizations.of(context);
  final repo = ref.read(ledgerRepositoryProvider);
  final form = switch (action) {
    LedgerAction.expense => LedgerForm(
      title: l10n.financeRecordExpense,
      intro: l10n.lgExpenseIntro,
      fields: [
        AccountField('account', l10n.lgWhatFor, isExpenseAccount),
        AccountField('from', l10n.lgPaidFrom, isMoneyAccount, initial: account),
        AmountField('amount', l10n.payAmountLabel('UGX')),
        DateField('date', l10n.lgDate),
        TextLedgerField('payee', l10n.financePayee),
        TextLedgerField('note', l10n.payNoteLabel),
      ],
      onSave: (v) => repo.recordExpense(
        accountId: _acct(v, 'account').id,
        accountName: _acct(v, 'account').name,
        paidFrom: _acct(v, 'from').id,
        amount: _amount(v, 'amount'),
        spentOn: _date(v, 'date'),
        payee: v['payee'] as String?,
        description: v['note'] as String?,
      ),
    ),
    LedgerAction.moneyIn => LedgerForm(
      title: l10n.lgMoneyIn,
      intro: l10n.lgMoneyInIntro,
      fields: [
        AccountField(
          'to',
          l10n.lgReceivedInto,
          isMoneyAccount,
          initial: account,
        ),
        AccountField(
          'source',
          l10n.lgKindOfMoney,
          (a) =>
              !a.isMoney &&
              const {'income', 'liability', 'equity'}.contains(a.type) &&
              a.code != '2090',
        ),
        AmountField('amount', l10n.payAmountLabel('UGX')),
        DateField('date', l10n.lgDate),
        TextLedgerField('memo', l10n.lgDescription),
      ],
      onSave: (v) => repo.moneyIn(
        to: _acct(v, 'to').id,
        source: _acct(v, 'source').id,
        amount: _amount(v, 'amount'),
        date: _date(v, 'date'),
        memo: v['memo'] as String?,
      ),
    ),
    LedgerAction.moneyOut => LedgerForm(
      title: l10n.lgMoneyOut,
      intro: l10n.lgMoneyOutIntro,
      fields: [
        AccountField('from', l10n.lgPaidFrom, isMoneyAccount, initial: account),
        AccountField(
          'target',
          l10n.lgWhatFor,
          (a) => !a.isMoney && a.type != 'income' && a.code != '2090',
        ),
        AmountField('amount', l10n.payAmountLabel('UGX')),
        DateField('date', l10n.lgDate),
        TextLedgerField('memo', l10n.lgDescription),
      ],
      onSave: (v) => repo.moneyOut(
        from: _acct(v, 'from').id,
        target: _acct(v, 'target').id,
        amount: _amount(v, 'amount'),
        date: _date(v, 'date'),
        memo: v['memo'] as String?,
      ),
    ),
    LedgerAction.transfer => LedgerForm(
      title: l10n.lgTransfer,
      intro: l10n.lgTransferIntro,
      fields: [
        AccountField(
          'from',
          l10n.lgFromAccount,
          isMoneyAccount,
          initial: account,
        ),
        AccountField('to', l10n.lgToAccount, isMoneyAccount),
        AmountField('amount', l10n.payAmountLabel('UGX')),
        AmountField(
          'fee',
          l10n.lgTransferCharge,
          required: false,
          allowZero: true,
        ),
        DateField('date', l10n.lgDate),
        TextLedgerField('memo', l10n.lgDescription),
      ],
      onSave: (v) => repo.transfer(
        from: _acct(v, 'from').id,
        to: _acct(v, 'to').id,
        amount: _amount(v, 'amount'),
        fee: v['fee'] as double?,
        date: _date(v, 'date'),
        memo: v['memo'] as String?,
      ),
    ),
    LedgerAction.bill => LedgerForm(
      title: l10n.lgRecordBill,
      intro: l10n.lgBillIntro,
      fields: [
        TextLedgerField('supplier', l10n.lgSupplier, required: true),
        AccountField(
          'account',
          l10n.lgWhatFor,
          (a) => !a.isMoney && (a.type == 'expense' || a.code == '1500'),
        ),
        AmountField('amount', l10n.payAmountLabel('UGX')),
        DateField('date', l10n.lgBillDate),
        DateField('due', l10n.lgDueDate, required: false, future: true),
        TextLedgerField('note', l10n.lgDescription),
      ],
      onSave: (v) => repo.recordBill(
        supplier: v['supplier']! as String,
        accountId: _acct(v, 'account').id,
        amount: _amount(v, 'amount'),
        billDate: _date(v, 'date'),
        dueDate: v['due'] as DateTime?,
        description: v['note'] as String?,
      ),
    ),
    LedgerAction.asset => LedgerForm(
      title: l10n.lgRecordAsset,
      intro: l10n.lgAssetIntro,
      fields: [
        TextLedgerField('name', l10n.lgAssetName, required: true),
        AmountField('cost', l10n.lgCost),
        DateField('date', l10n.lgPurchasedOn),
        AccountField(
          'from',
          l10n.lgPaidHow,
          (a) => a.isMoney || a.code == '2000' || a.code == '3000',
        ),
        WholeNumberField(
          'life',
          l10n.lgUsefulLife,
          hint: l10n.lgUsefulLifeHint,
        ),
        TextLedgerField('note', l10n.payNoteLabel),
      ],
      onSave: (v) => repo.recordAsset(
        name: v['name']! as String,
        cost: _amount(v, 'cost'),
        purchasedOn: _date(v, 'date'),
        paidFrom: _acct(v, 'from').id,
        usefulLifeMonths: v['life'] as int?,
        note: v['note'] as String?,
      ),
    ),
    LedgerAction.count => LedgerForm(
      title: l10n.lgCountMoney,
      intro: l10n.lgCountIntro,
      fields: [
        AccountField(
          'account',
          l10n.lgMoneyAccount,
          isMoneyAccount,
          initial: account,
        ),
        AmountField('counted', l10n.lgCounted, allowZero: true),
        DateField('date', l10n.lgDate),
        TextLedgerField('note', l10n.lgCountNote),
        SwitchLedgerField(
          'post',
          l10n.lgPostDifference,
          hint: l10n.lgPostDifferenceHint,
        ),
      ],
      onSave: (v) async {
        final r = await repo.reconcile(
          accountId: _acct(v, 'account').id,
          asOf: _date(v, 'date'),
          counted: _amount(v, 'counted'),
          note: v['note'] as String?,
          postDifference: v['post'] == true,
        );
        if (!context.mounted) return;
        final diff = r.numOrNull('difference') ?? 0;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.lgCountResult),
            content: Text(
              diff == 0
                  ? l10n.lgCountMatches(
                      formatMoney(r.numOrNull('books') ?? 0, 'UGX'),
                    )
                  : l10n.lgCountDiffers(
                      formatMoney(r.numOrNull('books') ?? 0, 'UGX'),
                      formatMoney(diff, 'UGX'),
                    ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      },
    ),
  };
  final saved = await showLedgerSheet(context, form);
  if (saved) refreshLedger(ref);
  return saved;
}

/// The starting amount of one account, from real records.
Future<bool> setOpeningBalance(
  BuildContext context,
  WidgetRef ref,
  LedgerAccount account,
) async {
  final l10n = AppLocalizations.of(context);
  final saved = await showLedgerSheet(
    context,
    LedgerForm(
      title: l10n.lgOpeningFor(account.name),
      intro: l10n.lgOpeningIntro,
      fields: [
        AmountField('amount', l10n.lgOpeningAmount, allowZero: true),
        DateField('date', l10n.lgOpeningDate),
      ],
      onSave: (v) => ref
          .read(ledgerRepositoryProvider)
          .setOpeningBalance(
            account.id,
            _amount(v, 'amount'),
            _date(v, 'date'),
          ),
    ),
  );
  if (saved) refreshLedger(ref);
  return saved;
}

/// Pays all or part of a bill.
Future<bool> payBill(BuildContext context, WidgetRef ref, Json bill) async {
  final l10n = AppLocalizations.of(context);
  final saved = await showLedgerSheet(
    context,
    LedgerForm(
      title: l10n.lgPayBill(bill.str('supplier')),
      intro: l10n.lgStillOwed(formatMoney(bill.numOrNull('owed') ?? 0, 'UGX')),
      fields: [
        AccountField('from', l10n.lgPaidFrom, isMoneyAccount),
        AmountField('amount', l10n.payAmountLabel('UGX')),
        DateField('date', l10n.lgDate),
      ],
      onSave: (v) => ref
          .read(ledgerRepositoryProvider)
          .payBill(
            bill.str('id'),
            _acct(v, 'from').id,
            _amount(v, 'amount'),
            _date(v, 'date'),
          ),
    ),
  );
  if (saved) refreshLedger(ref);
  return saved;
}

/// Sets the plan for one income or expense account for a month.
Future<bool> setBudget(
  BuildContext context,
  WidgetRef ref, {
  LedgerAccount? account,
}) async {
  final l10n = AppLocalizations.of(context);
  return showLedgerSheet(
    context,
    LedgerForm(
      title: l10n.lgSetBudget,
      intro: l10n.lgBudgetIntro,
      fields: [
        AccountField(
          'account',
          l10n.lgBudgetAccount,
          (a) => a.type == 'income' || a.type == 'expense',
          initial: account,
        ),
        DateField('month', l10n.lgBudgetMonth, future: true),
        AmountField('amount', l10n.payAmountLabel('UGX'), allowZero: true),
      ],
      onSave: (v) => ref
          .read(ledgerRepositoryProvider)
          .setBudget(
            _acct(v, 'account').id,
            _date(v, 'month'),
            _amount(v, 'amount'),
          ),
    ),
  );
}

/// Adds an account, or edits one.
Future<bool> editAccount(
  BuildContext context,
  WidgetRef ref, {
  LedgerAccount? account,
}) async {
  final saved = await showLedgerSheet(
    context,
    _AccountEditor(account: account),
  );
  if (saved) refreshLedger(ref);
  return saved;
}

class _AccountEditor extends ConsumerStatefulWidget {
  const _AccountEditor({this.account});
  final LedgerAccount? account;

  @override
  ConsumerState<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<_AccountEditor> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.account?.code);
  late final _name = TextEditingController(text: widget.account?.name);
  late final _description = TextEditingController(
    text: widget.account?.description,
  );
  late String _type = widget.account?.type ?? 'expense';
  late bool _money = widget.account?.isMoney ?? false;
  late bool _active = widget.account?.isActive ?? true;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final builtIn = widget.account?.isSystem ?? false;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.account == null ? l10n.lgAddAccount : l10n.lgEditAccount,
              style: theme.textTheme.titleLarge,
            ),
            if (builtIn)
              Text(l10n.lgBuiltInNote, style: theme.textTheme.bodySmall),
            TextFormField(
              controller: _code,
              enabled: !builtIn,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.lgAccountCode,
                hintText: l10n.lgAccountCodeHint,
              ),
              validator: (v) => RegExp(r'^\d{3,6}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : l10n.lgAccountCodeHint,
            ),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.lgAccountName),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? l10n.fieldRequired : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.lgAccountType),
              items: [
                for (final t in const [
                  'asset',
                  'liability',
                  'equity',
                  'income',
                  'expense',
                ])
                  DropdownMenuItem(
                    value: t,
                    child: Text(accountTypeLabel(l10n, t)),
                  ),
              ],
              onChanged: builtIn
                  ? null
                  : (v) => setState(() {
                      _type = v!;
                      if (_type != 'asset') _money = false;
                    }),
            ),
            if (_type == 'asset')
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _money,
                onChanged: builtIn ? null : (v) => setState(() => _money = v),
                title: Text(l10n.lgIsMoney),
                subtitle: Text(l10n.lgIsMoneyHint),
              ),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(labelText: l10n.lgDescription),
            ),
            if (widget.account != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: Text(l10n.lgInUse),
              ),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      setState(() => _saving = true);
                      final ok = await runAdminAction(
                        context,
                        () => ref
                            .read(ledgerRepositoryProvider)
                            .saveAccount(
                              id: widget.account?.id,
                              code: _code.text.trim(),
                              name: _name.text.trim(),
                              type: _type,
                              isMoney: _money,
                              description: _description.text.trim().isEmpty
                                  ? null
                                  : _description.text.trim(),
                              isActive: _active,
                            ),
                        success: l10n.adminSaved,
                      );
                      if (!context.mounted) return;
                      setState(() => _saving = false);
                      if (ok) Navigator.pop(context, true);
                    },
              child: Text(l10n.adminSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// A journal entry written by hand: any number of lines; the two totals
/// must match before it can be saved.
Future<bool> postJournalEntry(BuildContext context, WidgetRef ref) async {
  final saved = await showLedgerSheet(context, const _JournalEditor());
  if (saved) refreshLedger(ref);
  return saved;
}

class _JournalLine {
  LedgerAccount? account;
  final debit = TextEditingController();
  final credit = TextEditingController();
  double get d => double.tryParse(debit.text.trim().replaceAll(',', '')) ?? 0;
  double get c => double.tryParse(credit.text.trim().replaceAll(',', '')) ?? 0;
}

class _JournalEditor extends ConsumerStatefulWidget {
  const _JournalEditor();

  @override
  ConsumerState<_JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends ConsumerState<_JournalEditor> {
  final _memo = TextEditingController();
  final _lines = [_JournalLine(), _JournalLine()];
  DateTime _date = DateTime.now();
  bool _saving = false;

  double get _dr => _lines.fold(0, (s, l) => s + l.d);
  double get _cr => _lines.fold(0, (s, l) => s + l.c);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balanced = _dr > 0 && (_dr - _cr).abs() < 0.005;
    final complete = _lines.every(
      (l) => l.account != null && ((l.d > 0) != (l.c > 0)),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Space.lg,
        0,
        Space.lg,
        MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(l10n.lgJournalEntry, style: theme.textTheme.titleLarge),
          Text(l10n.lgJournalIntro, style: theme.textTheme.bodySmall),
          TextField(
            controller: _memo,
            decoration: InputDecoration(labelText: l10n.lgDescription),
            onChanged: (_) => setState(() {}),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(DateFormat.yMMMd(l10n.localeName).format(_date)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          for (final (i, line) in _lines.indexed)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(line.account?.label ?? l10n.lgChooseAccount),
                      trailing: _lines.length > 2
                          ? IconButton(
                              tooltip: l10n.lgRemoveLine,
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _lines.removeAt(i)),
                            )
                          : null,
                      onTap: () async {
                        final a = await pickAccount(
                          context,
                          ref,
                          title: l10n.lgChooseAccount,
                          filter: (_) => true,
                        );
                        if (a != null) setState(() => line.account = a);
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: line.debit,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.lgDebit,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: TextField(
                            controller: line.credit,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.lgCredit,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          TextButton.icon(
            onPressed: () => setState(() => _lines.add(_JournalLine())),
            icon: const Icon(Icons.add),
            label: Text(l10n.lgAddLine),
          ),
          Text(
            l10n.lgTotals(formatMoney(_dr, 'UGX'), formatMoney(_cr, 'UGX')),
            style: theme.textTheme.titleSmall?.copyWith(
              color: balanced ? null : theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed:
                _saving || !balanced || !complete || _memo.text.trim().isEmpty
                ? null
                : () async {
                    setState(() => _saving = true);
                    final ok = await runAdminAction(
                      context,
                      () => ref.read(ledgerRepositoryProvider).postJournal(
                        _date,
                        _memo.text.trim(),
                        [
                          for (final l in _lines)
                            (l.account!.id, l.d, l.c, null),
                        ],
                      ),
                      success: l10n.adminSaved,
                    );
                    if (!context.mounted) return;
                    setState(() => _saving = false);
                    if (ok) Navigator.pop(context, true);
                  },
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    );
  }
}
