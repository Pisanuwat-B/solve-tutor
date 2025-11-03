import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../live_classroom/components/room_loading_screen.dart';

class AdminFinance extends StatefulWidget {
  const AdminFinance({super.key});

  @override
  State<AdminFinance> createState() => _AdminFinanceState();
}

class _AdminFinanceState extends State<AdminFinance> {
  int? _subsCount = 0;
  int? _courseCount = 0;
  int? _tutorCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final subsCount = await getTotalSubscribers();
      final courseCount = await getPublishedCoursesCount();
      final tutorCount = await getVerifiedTutorCount();
      setState(() {
        _subsCount = subsCount;
        _courseCount = courseCount;
        _tutorCount = tutorCount;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load';
        _loading = false;
      });
    }
  }

  Future<int?> getTotalSubscribers() async {
    final q = FirebaseFirestore.instance
        .collection('users')
        .where('isSubs', isEqualTo: true);

    final agg = await q.count().get();     // aggregation query
    return agg.count;
  }

  Future<int?> getPublishedCoursesCount() async {
    final q = FirebaseFirestore.instance
        .collection('course')
        .where('publishing', isEqualTo: true);

    final agg = await q.count().get();
    return agg.count;
  }

  Future<int?> getVerifiedTutorCount() async {
    final q = FirebaseFirestore.instance
        .collection('users')
        .where('can_create', isEqualTo: true);

    final agg = await q.count().get();
    return agg.count;
  }

  @override
  Widget build(BuildContext context) {
    final earnings = _subsCount! * 599;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('สรุปการเงิน สำหรับ Admin'),
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
                  'คอร์ส Solvepad Marketplace',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'สรุปรายได้จากการขายคอร์ส Solvepad marketplace',
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รายได้รวม',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '01/10/2025 - 31/10/2025',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '$earnings ฿',
                            style: TextStyle(
                              color: const Color(0xFF10B981),
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      _StatTile(
                        title: 'จำนวนนักเรียนที่กด subscribe',
                        mainText: '$_subsCount',
                        unit: 'คน',
                        accent: Colors.black87,
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
                        child: const Text('กดไปก็ไม่มีอะไรหรอก ปุ่มนี้'),
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
                          title: 'คอร์สเรียนทั้งหมด',
                          period: '01/10/2025 - 31/10/2025',
                          mainText: '$_courseCount',
                          unit: 'คอร์ส',
                          sub: 'จำนวนคอร์สออนไลน์ ที่นักเรียนสามารถเข้าถึงได้',
                          accent: Colors.black87,
                        ),
                        _StatTile(
                          title: 'จำนวน tutor ที่ยืนยันตัวตนแล้ว',
                          period: '01/10/2025 - 31/10/2025',
                          mainText: '$_tutorCount คน',
                          chipText: 'เพิ่มขึ้น 100% จากเดือนที่ผ่านมา',
                          chipIcon: Icons.trending_up,
                          chipColor: const Color(0xFF10B981),
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
  final String? period;
  final String mainText;
  final String? unit;
  final String? sub;
  final String? chipText;
  final IconData? chipIcon;
  final Color? chipColor;
  final Color accent;

  const _StatTile({
    required this.title,
    this.period,
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
          if (period != null) Text(period!, style: subtle),
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