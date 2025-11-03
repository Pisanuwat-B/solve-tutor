import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../authentication/service/auth_provider.dart';
import '../../live_classroom/components/room_loading_screen.dart';

class RevenueSummaryPage extends StatefulWidget {
  const RevenueSummaryPage({super.key});

  @override
  State<RevenueSummaryPage> createState() => _RevenueSummaryPage();
}

class _RevenueSummaryPage extends State<RevenueSummaryPage> {
  late AuthProvider auth;
  int? _subsCount = 0;
  int? _tutorCount = 0;
  int? _publishedCourseCount = 0;
  int? _unpublishedCourseCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    auth = Provider.of<AuthProvider>(context, listen: false);
    _load();
  }

  Future<void> _load() async {
    try {
      final subsCount = await countSubscribedStudentsForTutor();
      final tutorCount = await getVerifiedTutorCount();
      final publishedCount = await getPublishedCountForTutor();
      final unpublishedCount = await getUnpublishedCountForTutor();
      setState(() {
        _subsCount = subsCount;
        _publishedCourseCount = publishedCount;
        _unpublishedCourseCount = unpublishedCount;
        _tutorCount = tutorCount;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<int?> getVerifiedTutorCount() async {
    final q = FirebaseFirestore.instance
        .collection('users')
        .where('can_create', isEqualTo: true);

    final agg = await q.count().get();
    return agg.count;
  }

  Future<int> countSubscribedStudentsForTutor() async {
    final ordersSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where('tutorId', isEqualTo: auth.user!.id!)
        .get();

    // Distinct student IDs
    final studentIds = <String>{
      for (final d in ordersSnap.docs)
        (d.data()['studentId'] as String?) ?? ''
    }..remove(''); // drop null/empty just in case

    if (studentIds.isEmpty) return 0;
    return studentIds.length;
  }

  Future<int?> getPublishedCountForTutor() async {
    final q = FirebaseFirestore.instance
        .collection('course')
        .where('tutor_id', isEqualTo: auth.user!.id!)
        .where('publishing', isEqualTo: true);
    final agg = await q.count().get();
    return agg.count;
  }

  Future<int?> getUnpublishedCountForTutor() async {
    final q = FirebaseFirestore.instance
        .collection('course')
        .where('tutor_id', isEqualTo: auth.user!.id!)
        .where('publishing', isEqualTo: false);
    final agg = await q.count().get();
    return agg.count;
  }

  @override
  Widget build(BuildContext context) {
    final double minimumExpectedEarn;
    if (_subsCount == null || _subsCount == 0) {
      minimumExpectedEarn = 0;
    } else {
      minimumExpectedEarn = 499 * _subsCount! / _tutorCount!;
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('สรุปรายได้'),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF6F7F9),
      body: _loading ? const LoadingScreen() : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'คอร์ส solvepad',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'สรุปรายได้จากการขายคอร์ส solvepad บน marketplace',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main card
          Card(
            elevation: 0,
            color: Colors.white,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รายได้รวม + (ยอดที่คุณกำลังจะได้รับ)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '01/08/2023 - 31/08/2023',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '0.00฿ + ($minimumExpectedEarn)',
                            style: TextStyle(
                              color: const Color(0xFF10B981),
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF20B153),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text('ถอนเงิน'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  // Three summary tiles
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, c) {
                      final isNarrow = c.maxWidth < 600;
                      final children = [
                        _StatTile(
                          title: 'คอร์สเรียน',
                          period: '01/08/2023 - 31/08/2023',
                          mainText: '$_publishedCourseCount',
                          unit: 'คอร์ส',
                          sub: 'คุณมี $_unpublishedCourseCount คอร์สที่ยังไม่ได้ออนไลน์',
                          accent: Colors.black87,
                        ),
                        _StatTile(
                          title: 'ยอดขายขั้นต่ำมี่คุณจะได้รับเดือนนี้',
                          period: '01/08/2023 - 31/08/2023',
                          mainText: '$minimumExpectedEarn ฿',
                          sub: 'คุณมีนักเรียน $_subsCount คน',
                          accent: Colors.black87,
                        ),
                      ];

                      if (isNarrow) {
                        log('narrow');
                        return Column(
                          children: [
                            for (final w in children) ...[
                              w,
                              const SizedBox(height: 10),
                            ]
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (int i = 0; i < children.length; i++) ...[
                            Expanded(child: children[i]),
                            if (i != children.length - 1)
                              SizedBox(
                                height: 120,
                                child: VerticalDivider(
                                  width: 50,
                                  color: Colors.grey.shade200,
                                  thickness: 1,
                                ),
                              ),
                          ]
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String period;
  final String mainText;
  final String? unit;
  final String? sub;
  final String? chipText;
  final IconData? chipIcon;
  final Color? chipColor;
  final Color accent;

  const _StatTile({
    required this.title,
    required this.period,
    required this.mainText,
    this.unit,
    this.sub,
    this.chipText,
    this.chipIcon,
    this.chipColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final subtle = TextStyle(color: Colors.grey.shade600);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(period, style: subtle),
          const SizedBox(height: 8),
          Text(
            '$mainText ${unit ?? ''}',
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (chipText != null) ...[
            const SizedBox(height: 6),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (chipColor ?? Colors.grey).withOpacity(.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chipIcon != null)
                    Icon(chipIcon, size: 16, color: chipColor),
                  if (chipIcon != null) const SizedBox(width: 6),
                  Text(chipText!,
                      style: TextStyle(
                          color: chipColor ?? Colors.grey.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!, style: subtle),
          ],
        ],
      ),
    );
  }
}