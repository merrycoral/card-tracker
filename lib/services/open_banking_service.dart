import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// 금융결제원 오픈뱅킹 API 연동 서비스
/// Docs: https://developers.kftc.or.kr/dev
class OpenBankingService {
  OpenBankingService._();
  static final OpenBankingService instance = OpenBankingService._();

  // ── 환경 설정 ──────────────────────────────────────────────────────────────
  // 테스트: testapi.openbanking.or.kr / 운영: openapi.openbanking.or.kr
  static const _baseUrl = 'https://testapi.openbanking.or.kr';
  static const _clientId = '8c106530-3bed-4492-a2fd-2efb6e8d6ac9';
  static const _clientSecret = 'fff1cc44-fa92-4b79-b9db-c431dd37eb8f';
  static const _redirectUri = 'cardtracker://oauth/callback';
  static const _scope = 'inquiry';

  // ── Secure Storage 키 ──────────────────────────────────────────────────────
  static const _keyAccessToken = 'ob_access_token';
  static const _keyRefreshToken = 'ob_refresh_token';
  static const _keyUserSeqNo = 'ob_user_seq_no';
  static const _keyTokenExpiry = 'ob_token_expiry';

  final _storage = const FlutterSecureStorage();

  // ─────────────────────────────────────────────────────────────────────────
  // OAuth 2.0 인증
  // ─────────────────────────────────────────────────────────────────────────

  /// 오픈뱅킹 로그인 (브라우저 OAuth 플로우)
  Future<void> authorize() async {
    final state = const Uuid().v4();

    final authUrl = Uri.parse('$_baseUrl/oauth/2.0/authorize').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'scope': _scope,
        'state': state,
        'auth_type': '0', // 0: 최초인증, 1: 재인증
      },
    );

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'cardtracker',
    );

    final uri = Uri.parse(result);
    final code = uri.queryParameters['code'];
    final returnedState = uri.queryParameters['state'];

    if (code == null) throw Exception('인증 코드를 받지 못했습니다.');
    if (returnedState != state) throw Exception('State 불일치 — CSRF 위험');

    await _exchangeCodeForToken(code);
  }

  /// 인증 코드 → Access Token 교환
  Future<void> _exchangeCodeForToken(String code) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/oauth/2.0/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    _assertSuccess(res, '토큰 발급');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _saveTokens(data);
  }

  /// Access Token 갱신
  Future<void> refreshToken() async {
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    if (refreshToken == null) throw Exception('리프레시 토큰 없음 — 재로그인 필요');

    final res = await http.post(
      Uri.parse('$_baseUrl/oauth/2.0/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      },
    );

    _assertSuccess(res, '토큰 갱신');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _saveTokens(data);
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final expiry = DateTime.now()
        .add(Duration(seconds: (data['expires_in'] as int? ?? 7776000)))
        .toIso8601String();

    await Future.wait([
      _storage.write(key: _keyAccessToken, value: data['access_token'] as String?),
      _storage.write(key: _keyRefreshToken, value: data['refresh_token'] as String?),
      _storage.write(key: _keyUserSeqNo, value: data['user_seq_no'] as String?),
      _storage.write(key: _keyTokenExpiry, value: expiry),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 토큰 유효성 확인
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> get isLoggedIn async {
    final token = await _storage.read(key: _keyAccessToken);
    return token != null;
  }

  Future<String> get _validAccessToken async {
    final expiryStr = await _storage.read(key: _keyTokenExpiry);
    if (expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      // 만료 5분 전에 갱신
      if (expiry.isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
        await refreshToken();
      }
    }
    final token = await _storage.read(key: _keyAccessToken);
    if (token == null) throw Exception('로그인이 필요합니다.');
    return token;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 카드 API
  // ─────────────────────────────────────────────────────────────────────────

  /// 연결된 카드 목록 조회
  Future<List<OBCard>> fetchCards() async {
    final token = await _validAccessToken;
    final userSeqNo = await _storage.read(key: _keyUserSeqNo) ?? '';

    final res = await http.get(
      Uri.parse('$_baseUrl/v2.0/card/cards').replace(
        queryParameters: {
          'user_seq_no': userSeqNo,
        },
      ),
      headers: _authHeaders(token),
    );

    _assertSuccess(res, '카드 목록 조회');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['card_list'] as List<dynamic>? ?? [];
    return list.map((e) => OBCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 카드 승인 내역 조회 (이번 달 실적)
  Future<List<OBTransaction>> fetchApprovals({
    required String cardNo,        // 카드번호
    required String inquiryType,   // 0: 전체, 1: 승인, 2: 취소
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final token = await _validAccessToken;
    final fmt = (DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

    final res = await http.get(
      Uri.parse('$_baseUrl/v2.0/card/approval/list').replace(
        queryParameters: {
          'card_no': cardNo,
          'inquiry_type': inquiryType,
          'from_date': fmt(fromDate),
          'to_date': fmt(toDate),
          'sort_order': 'D', // 최신순
          'limit': '500',
        },
      ),
      headers: _authHeaders(token),
    );

    _assertSuccess(res, '승인내역 조회');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['approval_list'] as List<dynamic>? ?? [];
    return list
        .map((e) => OBTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 이번 달 카드별 총 사용금액 (실적) 계산
  Future<double> fetchMonthlyUsage({
    required String cardNo,
    required int year,
    required int month,
  }) async {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0); // 말일

    final txns = await fetchApprovals(
      cardNo: cardNo,
      inquiryType: '1', // 승인만 (취소 제외)
      fromDate: from,
      toDate: to,
    );

    return txns.fold<double>(
      0,
      (sum, t) => sum + t.approvedAmount,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 로그아웃
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };

  void _assertSuccess(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = res.body;
      throw Exception('$label 실패 [${res.statusCode}]: $body');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 데이터 모델
// ─────────────────────────────────────────────────────────────────────────────

class OBCard {
  final String cardNo;      // 카드번호 (마스킹)
  final String cardName;    // 카드명
  final String company;     // 카드사
  final String cardType;    // 신용(CR) / 체크(CH)

  OBCard({
    required this.cardNo,
    required this.cardName,
    required this.company,
    required this.cardType,
  });

  factory OBCard.fromJson(Map<String, dynamic> j) => OBCard(
        cardNo: j['card_no'] as String? ?? '',
        cardName: j['card_name'] as String? ?? '',
        company: j['card_company'] as String? ?? '',
        cardType: j['card_type'] as String? ?? '',
      );

  bool get isCredit => cardType == 'CR';
}

class OBTransaction {
  final String approvalNo;    // 승인번호
  final DateTime approvedAt;  // 승인일시
  final String merchantName;  // 가맹점명
  final double approvedAmount;// 승인금액
  final bool isCancelled;     // 취소 여부

  OBTransaction({
    required this.approvalNo,
    required this.approvedAt,
    required this.merchantName,
    required this.approvedAmount,
    required this.isCancelled,
  });

  factory OBTransaction.fromJson(Map<String, dynamic> j) {
    final dateStr = j['approved_date'] as String? ?? '19700101';
    final timeStr = j['approved_time'] as String? ?? '000000';
    final dt = DateTime(
      int.parse(dateStr.substring(0, 4)),
      int.parse(dateStr.substring(4, 6)),
      int.parse(dateStr.substring(6, 8)),
      int.parse(timeStr.substring(0, 2)),
      int.parse(timeStr.substring(2, 4)),
    );
    return OBTransaction(
      approvalNo: j['approval_no'] as String? ?? '',
      approvedAt: dt,
      merchantName: j['merchant_name'] as String? ?? '',
      approvedAmount: double.tryParse(j['approved_amount']?.toString() ?? '0') ?? 0,
      isCancelled: (j['cancel_yn'] as String?) == 'Y',
    );
  }
}
