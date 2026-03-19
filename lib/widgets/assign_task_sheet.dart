import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group_member.dart';

class AssignTaskSheet extends StatefulWidget {
  final List<GroupMember> members;
  final void Function(String userId) onAssign;

  const AssignTaskSheet({
    super.key,
    required this.members,
    required this.onAssign,
  });

  @override
  State<AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends State<AssignTaskSheet> {
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Assign Task',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.members.map((member) {
                    final selected = _selectedUserId == member.userId;
                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? const Color(0xFFC9A84C)
                            : cs.onSurfaceVariant,
                      ),
                      title: Text(
                        member.displayName ?? 'Unknown',
                        style: GoogleFonts.dmSans(fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: member.allowTaskAssignment == false
                          ? Text('Has not accepted assignments',
                              style: GoogleFonts.dmSans(
                                  fontSize: 12, color: cs.onSurfaceVariant))
                          : null,
                      onTap: () =>
                          setState(() => _selectedUserId = member.userId),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _selectedUserId != null
                    ? () => widget.onAssign(_selectedUserId!)
                    : null,
                child: const Text('Assign'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
