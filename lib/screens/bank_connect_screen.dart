import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../providers/open_banking_provider.dart';
import '../services/open_banking_service.dart';

/// 오픈뱅킹 연결 & 카드 매핑 화면
class BankConnectScreen extends ConsumerStatefulWidget {
  final CardModel appCard; // 앱에 등록된 카드 (연동 대상)

  const BankConnectScreen({super.key, required this.appCard});

  @override
  ConsumerState<BankConnectScreen> createState() => _BankConnectScreenState();
}

class _BankConnectScreenState extends ConsumerState<BankConnectScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await OpenBankingService.instance.authorize();
      ref.invalidate(obLoginStateProvider);
      ref.invalidate(obCardsProvider);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await OpenBankingService.instance.logout();
    ref.invalidate(obLoginStateProvider);
    ref.invalidate(obCardsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(obLoginStateProvider);
    final mapping = ref.watch(obCardMappingProvider);
    final linkedCardNo = mapping[widget.appCard.id];

    return Scaffold(
      appBar: AppBar(title: const Text('오픈뱅킹 연동')),
      body: loginState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString(), onRetry: () => ref.invalidate(obLoginStateProvider)),
        data: (isLoggedIn) => isLoggedIn
            ? _LinkedView(
                appCard: widget.appCard,
                linkedCardNo: linkedCardNo,
                onLogout: _logout,
              )
            : _LoginView(
                loading: _loading,
                error: _error,
                onLogin: _login,
              ),
      ),
    );
  }
}

// ── 미로그인 뷰 ────────────────────────────────────────────────────────────────

class _LoginView extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onLogin;

  const _LoginView({required this.loading, required this.error, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text('오픈뱅킹 로그인',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            '금융결제원 오픈뱅킹에 로그인하면\n카드 사용 내역을 자동으로 불러옵니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.6),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '신용카드 승인 내역(출금 전)도\n실시간으로 조회됩니다.',
                    style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
          if (error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(error!,
                  style: TextStyle(color: Colors.red[700], fontSize: 13)),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onLogin,
              icon: loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(loading ? '로그인 중...' : '오픈뱅킹 로그인'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 로그인 후 카드 매핑 뷰 ────────────────────────────────────────────────────

class _LinkedView extends ConsumerWidget {
  final CardModel appCard;
  final String? linkedCardNo;
  final VoidCallback onLogout;

  const _LinkedView({
    required this.appCard,
    required this.linkedCardNo,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obCardsAsync = ref.watch(obCardsProvider);

    return obCardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(obCardsProvider),
      ),
      data: (obCards) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 연결 상태 배너
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('오픈뱅킹 연결됨',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ),
                TextButton(
                  onPressed: onLogout,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('연결 해제'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 앱 카드 정보
          Text('연동할 앱 카드',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(appCard.colorValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Color(appCard.colorValue).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 26,
                  decoration: BoxDecoration(
                    color: Color(appCard.colorValue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appCard.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(appCard.company,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                if (linkedCardNo != null) ...[
                  const Spacer(),
                  const Icon(Icons.link, color: Colors.green, size: 18),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 오픈뱅킹 카드 목록
          Text('오픈뱅킹 카드 선택',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 8),
          if (obCards.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('연결된 카드가 없습니다.'),
              ),
            )
          else
            ...obCards.map((c) => _OBCardTile(
                  obCard: c,
                  isLinked: c.cardNo == linkedCardNo,
                  onTap: () {
                    ref
                        .read(obCardMappingProvider.notifier)
                        .link(appCard.id, c.cardNo);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${appCard.name} ↔ ${c.cardName} 연동 완료'),
                      ),
                    );
                    Navigator.pop(context);
                  },
                )),
        ],
      ),
    );
  }
}

class _OBCardTile extends StatelessWidget {
  final OBCard obCard;
  final bool isLinked;
  final VoidCallback onTap;

  const _OBCardTile({
    required this.obCard,
    required this.isLinked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLinked
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Container(
          width: 40, height: 26,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.credit_card, size: 18, color: Colors.grey[600]),
        ),
        title: Text(obCard.cardName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${obCard.company}  •  ${obCard.isCredit ? '신용' : '체크'}카드'),
        trailing: isLinked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
