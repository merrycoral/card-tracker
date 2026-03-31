import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/open_banking_service.dart';

// ── 로그인 상태 ────────────────────────────────────────────────────────────────

final obLoginStateProvider = FutureProvider<bool>((ref) async {
  return OpenBankingService.instance.isLoggedIn;
});

// ── 연결된 카드 목록 ───────────────────────────────────────────────────────────

final obCardsProvider = FutureProvider<List<OBCard>>((ref) async {
  final isLoggedIn = await ref.watch(obLoginStateProvider.future);
  if (!isLoggedIn) return [];
  return OpenBankingService.instance.fetchCards();
});

// ── 카드별 이번 달 사용금액 ───────────────────────────────────────────────────

final obMonthlyUsageProvider =
    FutureProvider.family<double, _UsageParams>((ref, params) async {
  final isLoggedIn = await ref.watch(obLoginStateProvider.future);
  if (!isLoggedIn) return 0;
  return OpenBankingService.instance.fetchMonthlyUsage(
    cardNo: params.cardNo,
    year: params.year,
    month: params.month,
  );
});

// ── 카드 승인 내역 ────────────────────────────────────────────────────────────

final obTransactionsProvider =
    FutureProvider.family<List<OBTransaction>, _TxnParams>((ref, params) async {
  final isLoggedIn = await ref.watch(obLoginStateProvider.future);
  if (!isLoggedIn) return [];
  return OpenBankingService.instance.fetchApprovals(
    cardNo: params.cardNo,
    inquiryType: '0',
    fromDate: DateTime(params.year, params.month, 1),
    toDate: DateTime(params.year, params.month + 1, 0),
  );
});

// ── 오픈뱅킹 연동 카드번호 매핑 provider ─────────────────────────────────────
// cardId(앱 내 카드) → cardNo(오픈뱅킹 카드번호) 매핑을 저장

final obCardMappingProvider =
    StateNotifierProvider<OBCardMappingNotifier, Map<String, String>>((ref) {
  return OBCardMappingNotifier();
});

class OBCardMappingNotifier extends StateNotifier<Map<String, String>> {
  OBCardMappingNotifier() : super({});

  void link(String cardId, String cardNo) {
    state = {...state, cardId: cardNo};
  }

  void unlink(String cardId) {
    final next = Map<String, String>.from(state);
    next.remove(cardId);
    state = next;
  }

  String? cardNoFor(String cardId) => state[cardId];
}

// ── Param classes ─────────────────────────────────────────────────────────────

class _UsageParams {
  final String cardNo;
  final int year;
  final int month;
  const _UsageParams(this.cardNo, this.year, this.month);

  @override
  bool operator ==(Object other) =>
      other is _UsageParams &&
      cardNo == other.cardNo &&
      year == other.year &&
      month == other.month;

  @override
  int get hashCode => Object.hash(cardNo, year, month);
}

class _TxnParams {
  final String cardNo;
  final int year;
  final int month;
  const _TxnParams(this.cardNo, this.year, this.month);

  @override
  bool operator ==(Object other) =>
      other is _TxnParams &&
      cardNo == other.cardNo &&
      year == other.year &&
      month == other.month;

  @override
  int get hashCode => Object.hash(cardNo, year, month);
}

// ── Convenience extensions ────────────────────────────────────────────────────

extension UsageParamsX on AutoDisposeFutureProviderRef<double> {
  static _UsageParams params(String cardNo, int year, int month) =>
      _UsageParams(cardNo, year, month);
}

extension TxnParamsX on AutoDisposeFutureProviderRef<List<OBTransaction>> {
  static _TxnParams params(String cardNo, int year, int month) =>
      _TxnParams(cardNo, year, month);
}

// Public factory functions for creating params
_UsageParams usageParams(String cardNo, int year, int month) =>
    _UsageParams(cardNo, year, month);

_TxnParams txnParams(String cardNo, int year, int month) =>
    _TxnParams(cardNo, year, month);
