import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/billing/topup_order_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBillingRepository implements BillingRepository {
  const SupabaseBillingRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  @override
  Future<BillingSnapshot> loadSnapshot() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Supabase user session is required.');
    }

    final results = await Future.wait([
      _loadWallet(user.id),
      _loadProducts(),
      _loadSubscriptions(user.id),
      _loadTransactions(user.id),
      _loadInvoices(user.id),
      _loadPaymentOrders(user.id),
    ]);

    return BillingSnapshot(
      wallet: results[0] as Wallet,
      products: results[1] as List<BillingProduct>,
      plans: _buildPlans(results[1] as List<BillingProduct>),
      subscriptions: results[2] as List<Subscription>,
      transactions: results[3] as List<WalletTransaction>,
      invoices: results[4] as List<BillingInvoice>,
      paymentOrders: results[5] as List<PaymentOrder>,
    );
  }

  @override
  Future<TopUpOrderResult?> topUp({required int amount}) async {
    final rows = await _supabase.rpc<List<dynamic>>(
      'create_topup_order',
      params: {'amount': amount, 'provider': 'manual'},
    );

    final row = rows.isEmpty ? null : rows.first as Map<String, dynamic>;
    if (row == null) return null;

    return TopUpOrderResult(
      orderId: row['order_id'] as String,
      externalReference: row['external_reference'] as String,
      status: row['order_status'] as String? ?? 'pending',
      amount: _moneyToInt(row['order_amount']),
      paymentUrl: row['payment_url'] as String?,
    );
  }

  @override
  Future<BillingSnapshot> checkoutPlan({required String planId}) async {
    return checkoutIptvSubscription(deviceCount: 1, billingCycleMonths: 1);
  }

  @override
  Future<BillingSnapshot> checkoutIptvSubscription({
    required int deviceCount,
    required int billingCycleMonths,
  }) async {
    await _supabase.rpc<void>(
      'checkout_iptv_subscription',
      params: {
        'device_count': deviceCount,
        'billing_cycle_months': billingCycleMonths,
      },
    );

    final snapshot = await loadSnapshot();
    return BillingSnapshot(
      wallet: snapshot.wallet,
      products: snapshot.products,
      plans: snapshot.plans,
      subscriptions: snapshot.subscriptions,
      transactions: snapshot.transactions,
      invoices: snapshot.invoices,
      paymentOrders: snapshot.paymentOrders,
      message: 'Langganan Costik IPTV berhasil aktif.',
    );
  }

  Future<Wallet> _loadWallet(String userId) async {
    final row = await _supabase
        .from('wallets')
        .select('user_id, balance')
        .eq('user_id', userId)
        .maybeSingle();

    return Wallet(userId: userId, balance: _moneyToInt(row?['balance']));
  }

  Future<List<BillingProduct>> _loadProducts() async {
    final rows = await _supabase
        .from('products')
        .select('id, name')
        .order('name');

    return rows.map<BillingProduct>((row) {
      final id = row['id'] as String;
      return BillingProduct(
        id: id,
        name: row['name'] as String,
        category: _categoryFromProductId(id),
      );
    }).toList();
  }

  Future<List<Subscription>> _loadSubscriptions(String userId) async {
    final rows = await _supabase
        .from('subscriptions')
        .select('id, user_id, product_id, status, starts_at, expires_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map<Subscription>((row) {
      return Subscription(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        productId: row['product_id'] as String,
        planId: '${row['product_id']}:supabase',
        status: _subscriptionStatus(row['status'] as String?),
        startedAt:
            _date(row['starts_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        expiresAt:
            _date(row['expires_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        autoRenew: false,
      );
    }).toList();
  }

  Future<List<WalletTransaction>> _loadTransactions(String userId) async {
    final rows = await _supabase
        .from('wallet_transactions')
        .select('id, user_id, type, amount')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map<WalletTransaction>((row) {
      return WalletTransaction(
        userId: row['user_id'] as String,
        type: _transactionType(row['type'] as String?),
        amount: _moneyToInt(row['amount']),
        balanceBefore: 0,
        balanceAfter: 0,
        referenceId: row['id'] as String,
      );
    }).toList();
  }

  Future<List<BillingInvoice>> _loadInvoices(String userId) async {
    final rows = await _supabase
        .from('invoices')
        .select(
          'invoice_number, user_id, amount, status, issued_at, transaction_id',
        )
        .eq('user_id', userId)
        .order('issued_at', ascending: false);

    return rows.map<BillingInvoice>((row) {
      final status = row['status'] == 'paid'
          ? BillingInvoiceStatus.paid
          : BillingInvoiceStatus.draft;
      final issuedAt =
          _date(row['issued_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return BillingInvoice(
        number: row['invoice_number'] as String,
        userId: row['user_id'] as String,
        type: BillingInvoiceType.subscription,
        status: status,
        amount: _moneyToInt(row['amount']),
        issuedAt: issuedAt,
        paidAt: status == BillingInvoiceStatus.paid ? issuedAt : null,
        referenceId:
            row['transaction_id'] as String? ?? row['invoice_number'] as String,
      );
    }).toList();
  }

  Future<List<PaymentOrder>> _loadPaymentOrders(String userId) async {
    final rows = await _supabase
        .from('payment_orders')
        .select(
          'id, external_reference, amount, status, payment_url, created_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map<PaymentOrder>((row) {
      return PaymentOrder(
        id: row['id'] as String,
        externalReference: row['external_reference'] as String,
        amount: _moneyToInt(row['amount']),
        status: row['status'] as String? ?? 'pending',
        paymentUrl: row['payment_url'] as String?,
        createdAt:
            _date(row['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }

  List<BillingPlan> _buildPlans(List<BillingProduct> products) {
    return products.map((product) {
      return BillingPlan(
        id: '${product.id}:monthly',
        productId: product.id,
        name: '${product.name} Monthly',
        price: 15000,
        durationDays: 30,
        features: const ['Read-only Supabase billing data'],
      );
    }).toList();
  }

  BillingProductCategory _categoryFromProductId(String productId) {
    if (productId.contains('iptv')) return BillingProductCategory.iptv;
    if (productId.contains('hris')) return BillingProductCategory.hris;
    if (productId.contains('pos')) return BillingProductCategory.pos;
    if (productId.contains('laundry')) return BillingProductCategory.laundry;
    return BillingProductCategory.signage;
  }

  SubscriptionStatus _subscriptionStatus(String? value) {
    return switch (value) {
      'trial' => SubscriptionStatus.trial,
      'active' => SubscriptionStatus.active,
      'grace_period' => SubscriptionStatus.gracePeriod,
      'expired' => SubscriptionStatus.expired,
      'cancelled' => SubscriptionStatus.cancelled,
      'suspended' => SubscriptionStatus.suspended,
      _ => SubscriptionStatus.expired,
    };
  }

  WalletTransactionType _transactionType(String? value) {
    return switch (value) {
      'topup' => WalletTransactionType.topup,
      'purchase' => WalletTransactionType.purchase,
      'refund' => WalletTransactionType.refund,
      'adjustment' => WalletTransactionType.adjustment,
      'bonus' => WalletTransactionType.bonus,
      _ => WalletTransactionType.purchase,
    };
  }

  int _moneyToInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    return num.tryParse(value.toString())?.round() ?? 0;
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
