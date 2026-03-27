import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PaymentService — wraps Stripe SDK + Firebase Cloud Functions
// ─────────────────────────────────────────────────────────────────────────────
class PaymentService {
  final FirebaseFunctions _functions;

  PaymentService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  /// Call the `createEscrowPayment` Cloud Function to create a PaymentIntent.
  /// Returns the client secret.
  Future<String> createEscrowPayment({
    required String taskId,
    required String bidId,
    required double amount,
  }) async {
    final callable = _functions.httpsCallable('createEscrowPayment');
    final result = await callable.call<Map<String, dynamic>>({
      'taskId': taskId,
      'bidId':  bidId,
      'amount': amount,
    });
    final clientSecret = result.data['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('No client secret returned from server');
    }
    return clientSecret;
  }

  /// Initialise Stripe payment sheet and present it.
  /// Returns true if the payment was successful.
  Future<bool> presentPaymentSheet({
    required String clientSecret,
    required String merchantDisplayName,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName:       merchantDisplayName,
        style:                     ThemeMode.system,
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return false; // user dismissed
      }
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final paymentServiceProvider = Provider<PaymentService>(
  (_) => PaymentService(),
);
