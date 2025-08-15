import 'dart:developer';

import 'package:flutter/material.dart';

class RevenueSummaryPage extends StatelessWidget {
  const RevenueSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('สรุปรายได้'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'คอร์สบันทึกวิดีโอ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'สรุปรายได้จากการขายคอร์สบันทึกวิดีโอบน marketplace',
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
                            'รายได้รวม (หลังหักค่าบริการ)',
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
                            '850.00฿',
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
                      final children = const [
                        _StatTile(
                          title: 'คอร์สเรียน',
                          period: '01/08/2023 - 31/08/2023',
                          mainText: '3',
                          unit: 'คอร์ส',
                          sub: 'คุณมี 3 คอร์สที่ยังไม่ได้ออนไลน์',
                          accent: Colors.black87,
                        ),
                        _StatTile(
                          title: 'ยอดขาย',
                          period: '01/08/2023 - 31/08/2023',
                          mainText: '1,000 ฿',
                          chipText: 'เพิ่มขึ้น 5% จากเดือนที่ผ่านมา',
                          chipIcon: Icons.trending_up,
                          chipColor: Color(0xFF10B981),
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
      backgroundColor: const Color(0xFFF6F7F9),
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