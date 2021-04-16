import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../customer_session.dart';

class PaymentMethod {
  final String id;
  final String last4;
  final String brand;
  final DateTime expirationDate;

  const PaymentMethod(this.id, this.last4, this.brand, this.expirationDate);

  String getExpirationAsString() {
    return '${expirationDate.month}/${expirationDate.year}';
  }
}

/// A managed repository for payment methods.
/// This is the preferred way to work with payment methods when using Flutter.
/// The store will only refresh itself if there are active listeners.
///
///
class PaymentMethodStore extends ChangeNotifier {
  final List<PaymentMethod> paymentMethods = [];
  bool isLoading = false;

  /// The customer session the store operates on.
  final CustomerSession _customerSession;

  static PaymentMethodStore? _instance;

  /// Access the singleton instance of [PaymentMethodStore].
  static PaymentMethodStore get instance {
    _instance ??= PaymentMethodStore();
    return _instance!;
  }

  PaymentMethodStore({CustomerSession? customerSession})
      : _customerSession = customerSession ?? CustomerSession.instance {
    _customerSession.addListener(() => dispose());
  }

  /// Refreshes data from the API when the first listener is added.
  @override
  void addListener(VoidCallback listener) {
    final isFirstListener = !hasListeners;
    super.addListener(listener);
    if (isFirstListener) refresh();
  }

  /// Attach a payment method and refresh the store if there are any active listeners.
  Future<Map> attachPaymentMethod(String paymentMethodId) async {
    final paymentMethodFuture =
        await _customerSession.attachPaymentMethod(paymentMethodId);
    refresh();
    return paymentMethodFuture;
  }

  /// Detach a payment method and refresh the store if there are any active listeners.
  Future<Map> detachPaymentMethod(String paymentMethodId) async {
    final paymentMethodFuture =
        await _customerSession.detachPaymentMethod(paymentMethodId);
    refresh();
    return paymentMethodFuture;
  }

  /// Refresh the store if there are any active listeners.
  Future<void> refresh() {
    if (!hasListeners) return Future.value();

    final paymentMethodFuture = _customerSession.listPaymentMethods(limit: 100);
    isLoading = true;
    notifyListeners();
    return paymentMethodFuture.then((value) {
      final List listData = value['data'] ?? <PaymentMethod>[];
      paymentMethods.clear();
      if (listData.isNotEmpty) {
        paymentMethods.addAll(listData
            .map((item) => PaymentMethod(
                item['id'],
                item['card']['last4'],
                item['card']['brand'],
                DateTime(item['card']['exp_year'], item['card']['exp_month'])))
            .toList());
      }
    }).whenComplete(() {
      isLoading = false;
      notifyListeners();
    });
  }

  /// Clear the store, notify all active listeners and dispose the ChangeNotifier.
  @override
  void dispose() {
    paymentMethods.clear();
    notifyListeners();
    super.dispose();
  }
}
