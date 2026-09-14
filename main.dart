import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/models.dart';
import 'services/storage_service.dart';
import 'services/pdf_service.dart';

void main() => runApp(const KasWargaApp());

class KasWargaApp extends StatelessWidget {
  const KasWargaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KasWarga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class AppState extends ChangeNotifier {
  final storage = StorageService();
  List<Resident> residents = [];
  List<Payment> payments = [];
  List<CashTransaction> transactions = [];
  UserRole role;
  bool loaded = false;

  AppState(this.role);

  Future<void> load() async {
    residents = await storage.loadResidents();
    payments = await storage.loadPayments();
    transactions = await storage.loadTransactions();
    loaded = true;
    notifyListeners();
  }

  int get income => transactions
      .where((x) => x.type == TransactionType.income)
      .fold(0, (a, b) => a + b.amount);

  int get expense => transactions
      .where((x) => x.type == TransactionType.expense)
      .fold(0, (a, b) => a + b.amount);

  int get balance => income - expense;

  Future<void> addResident(Resident r) async {
    residents.add(r);
    await storage.saveResidents(residents);
    notifyListeners();
  }

  Future<void> updateResident(Resident r) async {
    final i = residents.indexWhere((x) => x.id == r.id);
    if (i >= 0) residents[i] = r;
    await storage.saveResidents(residents);
    notifyListeners();
  }

  Future<void> deleteResident(String id) async {
    residents.removeWhere((x) => x.id == id);
    payments.removeWhere((x) => x.residentId == id);
    await storage.saveResidents(residents);
    await storage.savePayments(payments);
    notifyListeners();
  }

  Payment paymentFor(String residentId, int year, int month) {
    return payments.firstWhere(
      (x) => x.residentId == residentId && x.year == year && x.month == month,
      orElse: () => Payment(
        residentId: residentId,
        year: year,
        month: month,
        amount: 20000,
        status: PaymentStatus.unpaid,
      ),
    );
  }

  Future<void> setPaid(String residentId, int year, int month, bool paid) async {
    final i = payments.indexWhere(
      (x) => x.residentId == residentId && x.year == year && x.month == month,
    );
    final item = Payment(
      residentId: residentId,
      year: year,
      month: month,
      amount: 20000,
      status: paid ? PaymentStatus.paid : PaymentStatus.unpaid,
      paidAt: paid ? DateTime.now() : null,
    );
    if (i >= 0) payments[i] = item;
    else payments.add(item);
    await storage.savePayments(payments);
    notifyListeners();
  }

  Future<void> addTransaction(CashTransaction t) async {
    transactions.add(t);
    await storage.saveTransactions(transactions);
    notifyListeners();
  }

  Future<String> exportBackup() => storage.exportJson(
    residents: residents,
    payments: payments,
    transactions: transactions,
  );

  Future<void> restoreBackup(String raw) async {
    await storage.restoreJson(raw);
    await load();
  }
}

String rupiah(int n) => NumberFormat.currency(
  locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
).format(n);

String id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  String? error;

  void login() async {
    UserRole? role;
    if (user.text == 'admin' && pass.text == 'admin123') role = UserRole.admin;
    if (user.text == 'warga' && pass.text == 'warga123') role = UserRole.participant;
    if (role == null) {
      setState(() => error = 'Username atau password salah');
      return;
    }
    final state = AppState(role)..load();
    await state.load();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(state: state)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.account_balance, size: 64),
                  const SizedBox(height: 12),
                  const Text('KasWarga', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const Text('Manajemen Kas & Iuran RT'),
                  const SizedBox(height: 28),
                  TextField(controller: user, decoration: const InputDecoration(labelText: 'Username')),
                  TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                  if (error != null) Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: login,
                    icon: const Icon(Icons.login),
                    label: const Text('Masuk'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Demo Admin: admin / admin123'),
                  const Text('Demo Warga: warga / warga123'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  final AppState state;
  const HomePage({super.key, required this.state});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final admin = widget.state.role == UserRole.admin;
    final pages = admin
      ? [
          DashboardPage(state: widget.state),
          ResidentsPage(state: widget.state),
          PaymentsPage(state: widget.state),
          CashbookPage(state: widget.state),
          ReportsPage(state: widget.state),
        ]
      : [
          DashboardPage(state: widget.state),
          PaymentsPage(state: widget.state),
          CashbookPage(state: widget.state),
        ];

    return AnimatedBuilder(
      animation: widget.state,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: const Text('KasWarga'),
          actions: [
            if (admin) IconButton(
              tooltip: 'Backup',
              icon: const Icon(Icons.backup),
              onPressed: () => showBackup(context),
            ),
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
            ),
          ],
        ),
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: admin
            ? const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.people), label: 'Warga'),
                NavigationDestination(icon: Icon(Icons.payments), label: 'Iuran'),
                NavigationDestination(icon: Icon(Icons.menu_book), label: 'Kas'),
                NavigationDestination(icon: Icon(Icons.picture_as_pdf), label: 'Laporan'),
              ]
            : const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.payments), label: 'Iuran'),
                NavigationDestination(icon: Icon(Icons.menu_book), label: 'Kas'),
              ],
        ),
      ),
    );
  }

  Future<void> showBackup(BuildContext context) async {
    final raw = await widget.state.exportBackup();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Backup Data'),
        content: SelectableText(
          'Backup berhasil dibuat di memori aplikasi.\n\nUntuk versi produksi, sambungkan fungsi ini ke file picker/Google Drive.\n\nUkuran data: ${raw.length} karakter.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final AppState state;
  const DashboardPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final month = DateTime.now().month;
    final year = DateTime.now().year;
    final paid = state.residents.where((r) {
      return state.paymentFor(r.id, year, month).status == PaymentStatus.paid;
    }).length;
    final unpaid = state.residents.length - paid;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SALDO SAAT INI'),
                const SizedBox(height: 8),
                Text(rupiah(state.balance), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(child: _StatCard(title: 'Pemasukan', value: rupiah(state.income), icon: Icons.arrow_downward)),
            Expanded(child: _StatCard(title: 'Pengeluaran', value: rupiah(state.expense), icon: Icons.arrow_upward)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _StatCard(title: 'Lunas', value: '$paid', icon: Icons.check_circle)),
            Expanded(child: _StatCard(title: 'Belum Lunas', value: '$unpaid', icon: Icons.warning)),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Total Warga'),
            trailing: Text('${state.residents.length}'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text('Iuran ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month))}'),
            subtitle: Text('$paid warga sudah lunas'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 6),
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

class ResidentsPage extends StatefulWidget {
  final AppState state;
  const ResidentsPage({super.key, required this.state});
  @override
  State<ResidentsPage> createState() => _ResidentsPageState();
}

class _ResidentsPageState extends State<ResidentsPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.state.residents.where((r) =>
      r.name.toLowerCase().contains(query.toLowerCase()) ||
      r.houseNumber.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Cari nama / nomor rumah',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
              ? const Center(child: Text('Belum ada data warga'))
              : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final r = list[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(r.name.isEmpty ? '?' : r.name[0])),
                    title: Text(r.name),
                    subtitle: Text('${r.houseNumber} • ${r.phone}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(label: Text(r.status == ResidentStatus.active ? 'Aktif' : 'Pindah')),
                        PopupMenuButton(
                          onSelected: (v) {
                            if (v == 'edit') _edit(r);
                            if (v == 'delete') widget.state.deleteResident(r.id);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Hapus')),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Warga'),
      ),
    );
  }

  Future<void> _edit(Resident? old) async {
    final name = TextEditingController(text: old?.name ?? '');
    final house = TextEditingController(text: old?.houseNumber ?? '');
    final phone = TextEditingController(text: old?.phone ?? '');
    ResidentStatus status = old?.status ?? ResidentStatus.active;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(old == null ? 'Tambah Warga' : 'Edit Warga'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama lengkap')),
                TextField(controller: house, decoration: const InputDecoration(labelText: 'Nomor rumah / blok')),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'HP / WhatsApp')),
                DropdownButtonFormField<ResidentStatus>(
                  value: status,
                  items: ResidentStatus.values.map((x) => DropdownMenuItem(
                    value: x, child: Text(x == ResidentStatus.active ? 'Aktif' : 'Pindah'),
                  )).toList(),
                  onChanged: (x) => setLocal(() => status = x!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty || house.text.trim().isEmpty) return;
                final r = Resident(
                  id: old?.id ?? id('resident'),
                  name: name.text.trim(),
                  houseNumber: house.text.trim(),
                  phone: phone.text.trim(),
                  status: status,
                );
                if (old == null) await widget.state.addResident(r);
                else await widget.state.updateResident(r);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentsPage extends StatefulWidget {
  final AppState state;
  const PaymentsPage({super.key, required this.state});
  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  int year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Tahun: '),
              DropdownButton<int>(
                value: year,
                items: [year - 1, year, year + 1].map((y) =>
                  DropdownMenuItem(value: y, child: Text('$y'))
                ).toList(),
                onChanged: (y) => setState(() => year = y!),
              ),
              const Spacer(),
              const Text('Iuran standar: Rp20.000'),
            ],
          ),
        ),
        Expanded(
          child: widget.state.residents.isEmpty
            ? const Center(child: Text('Belum ada warga'))
            : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: widget.state.residents.length,
              itemBuilder: (_, i) {
                final r = widget.state.residents[i];
                return Card(
                  child: ExpansionTile(
                    title: Text(r.name),
                    subtitle: Text(r.houseNumber),
                    children: List.generate(12, (index) {
                      final month = index + 1;
                      final p = widget.state.paymentFor(r.id, year, month);
                      return ListTile(
                        title: Text(DateFormat('MMMM', 'id_ID').format(DateTime(year, month))),
                        subtitle: Text(p.paidAt == null ? 'Rp20.000' : 'Dibayar ${DateFormat('dd/MM/yyyy HH:mm').format(p.paidAt!)}'),
                        trailing: widget.state.role == UserRole.admin
                          ? Switch(
                              value: p.status == PaymentStatus.paid,
                              onChanged: (v) => widget.state.setPaid(r.id, year, month, v),
                            )
                          : Chip(label: Text(p.status == PaymentStatus.paid ? 'Lunas' : 'Belum Lunas')),
                      );
                    }),
                  ),
                );
              },
            ),
        ),
      ],
    );
  }
}

class CashbookPage extends StatefulWidget {
  final AppState state;
  const CashbookPage({super.key, required this.state});
  @override
  State<CashbookPage> createState() => _CashbookPageState();
}

class _CashbookPageState extends State<CashbookPage> {
  int selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final list = widget.state.transactions.where((x) => x.date.month == selectedMonth && x.date.year == DateTime.now().year).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Bulan: '),
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(DateFormat('MMMM', 'id_ID').format(DateTime(2026, i + 1))),
                  )),
                  onChanged: (v) => setState(() => selectedMonth = v!),
                ),
                const Spacer(),
                Text('Saldo ${rupiah(widget.state.balance)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
              ? const Center(child: Text('Belum ada transaksi'))
              : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final t = list[i];
                  final income = t.type == TransactionType.income;
                  return ListTile(
                    leading: CircleAvatar(child: Icon(income ? Icons.add : Icons.remove)),
                    title: Text(t.category),
                    subtitle: Text('${DateFormat('dd/MM/yyyy').format(t.date)} • ${t.description}'),
                    trailing: Text(
                      '${income ? '+' : '-'} ${rupiah(t.amount)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
          ),
        ],
      ),
      floatingActionButton: widget.state.role == UserRole.admin
        ? FloatingActionButton.extended(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('Transaksi'),
          )
        : null,
    );
  }

  Future<void> _add() async {
    TransactionType type = TransactionType.income;
    final amount = TextEditingController();
    final category = TextEditingController();
    final desc = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Tambah Transaksi'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.income, label: Text('Pemasukan')),
                    ButtonSegment(value: TransactionType.expense, label: Text('Pengeluaran')),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setLocal(() => type = v.first),
                ),
                TextField(controller: category, decoration: const InputDecoration(labelText: 'Kategori')),
                TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah (Rp)')),
                TextField(controller: desc, decoration: const InputDecoration(labelText: 'Keterangan')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final n = int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                if (n <= 0 || category.text.trim().isEmpty) return;
                await widget.state.addTransaction(CashTransaction(
                  id: id('tx'),
                  date: DateTime.now(),
                  type: type,
                  category: category.text.trim(),
                  amount: n,
                  description: desc.text.trim(),
                ));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  final AppState state;
  const ReportsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Laporan', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      Card(
        child: ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: const Text('Cetak / Simpan Buku Kas PDF'),
          subtitle: Text('${state.transactions.length} transaksi'),
          onTap: () => PdfService().printCashReport(state.transactions),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.chat),
          title: const Text('Kirim tagihan WhatsApp'),
          subtitle: const Text('Pilih warga yang belum lunas'),
          onTap: () => _whatsapp(context),
        ),
      ),
    ],
  );

  Future<void> _whatsapp(BuildContext context) async {
    final current = DateTime.now();
    final unpaid = state.residents.where((r) =>
      state.paymentFor(r.id, current.year, current.month).status == PaymentStatus.unpaid &&
      r.phone.trim().isNotEmpty
    ).toList();

    if (unpaid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada warga dengan nomor HP yang bisa ditagih.')));
      return;
    }

    final r = unpaid.first;
    final phone = r.phone.replaceFirst(RegExp(r'^0'), '62').replaceAll(RegExp(r'[^0-9]'), '');
    final message = 'Halo ${r.name}, mohon pembayaran iuran RT bulan ${DateFormat('MMMM yyyy', 'id_ID').format(current)} sebesar Rp20.000. Terima kasih.';
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}