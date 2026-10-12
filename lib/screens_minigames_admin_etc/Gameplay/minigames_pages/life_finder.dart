import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../themes_colors/app_theme.dart';

/// One thing a player might want to do in Life, in their own words.
class LifeFinderEntry {
  const LifeFinderEntry({
    required this.icon,
    required this.title,
    required this.keywords,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;

  /// Words somebody might type for this, beyond the title.
  final String keywords;
  final Color color;
  final VoidCallback onTap;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = '${title.toLowerCase()} $keywords';
    return q.split(RegExp(r'\s+')).every(haystack.contains);
  }
}

/// "I want to..." — every main thing to do in Life, findable by what it is
/// rather than by which menu it lives in.
///
/// **Reported as:** a younger tester *"doesn't know how to go to the doctor"*,
/// and the menu being *"too complex and the user can't find what they
/// need."* The menu is organised by where things live (Job, Money, People, Do
/// things); a player who is ill thinks "doctor", not "Do things, then Health".
/// This answers the question they actually have.
Future<void> showLifeFinder(
  BuildContext context,
  List<LifeFinderEntry> entries,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppTheme.panel,
    builder: (_) => _LifeFinder(entries: entries),
  );
}

class _LifeFinder extends StatefulWidget {
  const _LifeFinder({required this.entries});

  final List<LifeFinderEntry> entries;

  @override
  State<_LifeFinder> createState() => _LifeFinderState();
}

class _LifeFinderState extends State<_LifeFinder> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final shown = widget.entries.where((e) => e.matches(_query)).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I want to...',
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('life-find-field'),
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type: doctor, job, budget, car...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white70,
              ),
              filled: true,
              fillColor: AppTheme.inset,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.outline, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.outline, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Nothing called that. Try "doctor", "job" or "money".',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final e in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: AppTheme.inset,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(context).pop();
                                e.onTap();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: e.color,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        e.icon,
                                        color: const Color(0xFF0B1418),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        e.title,
                                        style: GoogleFonts.quicksand(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
