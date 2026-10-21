double? _d(dynamic v) => (v as num?)?.toDouble();

class ProProfile {
  ProProfile(this.m);
  final Map<String, dynamic> m;

  String get userId => m['user_id'] as String;
  String get accountType => (m['account_type'] as String?) ?? 'individual';
  String? get businessName => m['business_name'] as String?;
  String? get bio => m['bio'] as String?;
  int get years => (m['years_experience'] as int?) ?? 0;
  String? get slug => m['slug'] as String?;
  String get status => (m['status'] as String?) ?? 'draft';
  String? get statusNote => m['status_note'] as String?;
  int get level => (m['verification_level'] as int?) ?? 1;
  bool get online => (m['is_online'] as bool?) ?? false;
  String? get baseAddress => m['base_address'] as String?;
  double? get baseLat => _d(m['base_lat']);
  double? get baseLng => _d(m['base_lng']);
  int get radiusKm => (m['radius_km'] as int?) ?? 15;
  String? get bankName => m['bank_name'] as String?;
  String? get accountNumber => m['account_number'] as String?;
  String? get accountName => m['account_name'] as String?;
  bool get notifyJobs => (m['notify_jobs'] as bool?) ?? true;
  bool get notifyMessages => (m['notify_messages'] as bool?) ?? true;
  double get rating => _d(m['rating']) ?? 0;
  int get ratingCount => (m['rating_count'] as int?) ?? 0;
  int get jobsDone => (m['jobs_done'] as int?) ?? 0;
  bool get approved => status == 'approved';
}

class OfferedService {
  OfferedService({required this.id, required this.categoryId, required this.pricingType, this.price, this.description, this.isActive = true});
  final String? id;
  final String categoryId;
  String pricingType;
  num? price;
  String? description;
  bool isActive;

  factory OfferedService.fromMap(Map<String, dynamic> m) => OfferedService(
        id: m['id'] as String?,
        categoryId: m['category_id'] as String,
        pricingType: (m['pricing_type'] as String?) ?? 'fixed',
        price: m['price'] as num?,
        description: m['description'] as String?,
        isActive: (m['is_active'] as bool?) ?? true,
      );

  String get priceLabel => switch (pricingType) {
        'hourly' => price == null ? 'Per hour' : '₦${price!.round()}/hr',
        'starting' => price == null ? 'Starting price' : 'From ₦${price!.round()}',
        'quote' => 'Quote on request',
        _ => price == null ? 'Fixed price' : '₦${price!.round()}',
      };
}

class DayHours {
  DayHours({required this.weekday, required this.enabled, required this.start, required this.end});
  final int weekday;
  bool enabled;
  String start;
  String end;

  factory DayHours.fromMap(Map<String, dynamic> m) => DayHours(
        weekday: m['weekday'] as int,
        enabled: (m['enabled'] as bool?) ?? true,
        start: (m['start_time'] as String).substring(0, 5),
        end: (m['end_time'] as String).substring(0, 5),
      );
}

class JobOffer {
  JobOffer({required this.id, required this.bookingId, required this.status, this.quoteAmount, this.quoteNote, required this.createdAt, this.proId});
  final String id;
  final String bookingId;
  final String status;
  final num? quoteAmount;
  final String? quoteNote;
  final DateTime createdAt;
  final String? proId;

  factory JobOffer.fromMap(Map<String, dynamic> m) => JobOffer(
        id: m['id'] as String,
        bookingId: m['booking_id'] as String,
        status: m['status'] as String,
        quoteAmount: m['quote_amount'] as num?,
        quoteNote: m['quote_note'] as String?,
        proId: m['pro_id'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}

class VerificationDoc {
  VerificationDoc({required this.id, required this.kind, required this.status, this.title, this.note});
  final String id;
  final String kind;
  final String status;
  final String? title;
  final String? note;

  factory VerificationDoc.fromMap(Map<String, dynamic> m) => VerificationDoc(
        id: m['id'] as String,
        kind: m['kind'] as String,
        status: m['status'] as String,
        title: m['title'] as String?,
        note: m['note'] as String?,
      );
}

class PortfolioItem {
  PortfolioItem({required this.id, required this.url, this.caption});
  final String id;
  final String url;
  final String? caption;

  factory PortfolioItem.fromMap(Map<String, dynamic> m) =>
      PortfolioItem(id: m['id'] as String, url: m['image_url'] as String, caption: m['caption'] as String?);
}

class TeamMember {
  TeamMember({required this.id, required this.name, this.phone, this.role});
  final String id;
  final String name;
  final String? phone;
  final String? role;

  factory TeamMember.fromMap(Map<String, dynamic> m) =>
      TeamMember(id: m['id'] as String, name: m['name'] as String, phone: m['phone'] as String?, role: m['role'] as String?);
}

class Payout {
  Payout({required this.id, required this.amount, required this.status, required this.createdAt, this.bankName, this.accountNumber});
  final String id;
  final num amount;
  final String status;
  final DateTime createdAt;
  final String? bankName;
  final String? accountNumber;

  factory Payout.fromMap(Map<String, dynamic> m) => Payout(
        id: m['id'] as String,
        amount: m['amount'] as num,
        status: m['status'] as String,
        bankName: m['bank_name'] as String?,
        accountNumber: m['account_number'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}

class ProReview {
  ProReview({required this.id, required this.rating, this.comment, this.reply, required this.createdAt, required this.bookingId});
  final String id;
  final int rating;
  final String? comment;
  final String? reply;
  final DateTime createdAt;
  final String bookingId;

  factory ProReview.fromMap(Map<String, dynamic> m) => ProReview(
        id: m['id'] as String,
        rating: m['rating'] as int,
        comment: m['comment'] as String?,
        reply: m['reply'] as String?,
        bookingId: m['booking_id'] as String,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.kind,
    this.body,
    this.mediaPath,
    required this.masked,
    required this.createdAt,
  });
  final String id;
  final String senderId;
  final String kind;
  final String? body;
  final String? mediaPath;
  final bool masked;
  final DateTime createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as String,
        senderId: m['sender_id'] as String,
        kind: m['kind'] as String,
        body: m['body'] as String?,
        mediaPath: m['media_path'] as String?,
        masked: (m['is_masked'] as bool?) ?? false,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}

/// The other person on a booking (name and photo only).
class Party {
  Party(this.m);
  final Map<String, dynamic> m;
  String get id => m['id'] as String;
  String get name => (m['name'] as String?) ?? 'User';
  String? get avatar => m['avatar'] as String?;
  double get rating => (m['rating'] as num?)?.toDouble() ?? 0;
  int get ratingCount => (m['rating_count'] as int?) ?? 0;
  int get jobsDone => (m['jobs_done'] as int?) ?? 0;
  int get level => (m['verification_level'] as int?) ?? 0;
  String? get slug => m['slug'] as String?;
  String get initials => name.trim().isEmpty ? '?' : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
}
