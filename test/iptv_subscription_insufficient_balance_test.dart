import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:costikstudio/features/billing/cubit/billing_cubit.dart';
import 'package:costikstudio/features/subscription/view/iptv_subscription_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows top up guidance when IPTV checkout balance is insufficient',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repository = DummyBillingRepository();
      final cubit = BillingCubit(repository: repository);
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BillingCubit>.value(
            value: cubit,
            child: const Scaffold(body: IptvSubscriptionPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Nama Hotel / Instansi / Perusahaan'),
        'Costik Hotel',
      );
      await tester.enterText(
        find.bySemanticsLabel('Nama Penanggung Jawab (PIC)'),
        'Kama',
      );
      await tester.enterText(
        find.bySemanticsLabel('Alamat Email'),
        'kama@example.com',
      );
      await tester.enterText(
        find.bySemanticsLabel('No. WhatsApp / Telepon'),
        '08123456789',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, '25 Device'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '1 Tahun (12 Bln)'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Konfirmasi & Lanjut Pembayaran'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saldo Belum Cukup'), findsOneWidget);
      expect(find.text('Saldo Saat Ini'), findsOneWidget);
      expect(find.text('Total Langganan'), findsOneWidget);
      expect(find.text('Perlu Top Up'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Top Up Balance'),
        findsOneWidget,
      );
    },
  );
}
