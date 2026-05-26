import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';

class BulkInvitePage extends ConsumerStatefulWidget {
  const BulkInvitePage({super.key});

  @override
  ConsumerState<BulkInvitePage> createState() => _BulkInvitePageState();
}

class _BulkInvitePageState extends ConsumerState<BulkInvitePage> {
  final _emailsCtrl = TextEditingController();
  String _selectedRole = 'member';
  String _selectedDept = 'Engineering';
  bool _isSending = false;
  List<Map<String, dynamic>> _sentInvites = [];
  late Box _inviteBox;
  bool _boxInitialized = false;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      _inviteBox = await Hive.openBox('org_invites');
      _loadInvitesFromHive();
    } catch (e) {
      debugPrint('Error opening invites box: $e');
      // Fallback to memory
      _sentInvites = _getMockInvites();
    } finally {
      if (mounted) {
        setState(() {
          _boxInitialized = true;
        });
      }
    }
  }

  void _loadInvitesFromHive() {
    final stored = _inviteBox.get('invites_list');
    if (stored != null) {
      try {
        final List<dynamic> decoded = jsonDecode(stored as String);
        _sentInvites = decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      } catch (e) {
        _sentInvites = _getMockInvites();
      }
    } else {
      _sentInvites = _getMockInvites();
      _saveInvitesToHive();
    }
  }

  void _saveInvitesToHive() {
    if (_inviteBox.isOpen) {
      _inviteBox.put('invites_list', jsonEncode(_sentInvites));
    }
  }

  List<Map<String, dynamic>> _getMockInvites() {
    return [
      {
        'email': 'alice.smith@company.com',
        'role': 'manager',
        'department': 'Marketing',
        'status': 'accepted',
        'date': '2026-05-20',
      },
      {
        'email': 'bob.jones@company.com',
        'role': 'member',
        'department': 'Engineering',
        'status': 'pending',
        'date': '2026-05-24',
      },
      {
        'email': 'carol.davis@company.com',
        'role': 'member',
        'department': 'Sales',
        'status': 'sent',
        'date': '2026-05-25',
      },
    ];
  }

  @override
  void dispose() {
    _emailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCSVFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final parsedEmails = _parseEmailsFromCSV(content);
        if (parsedEmails.isNotEmpty) {
          setState(() {
            final separator = _emailsCtrl.text.isNotEmpty ? ', ' : '';
            _emailsCtrl.text += separator + parsedEmails.join(', ');
          });
          if (mounted) {
            AppToast.success(context, 'Imported ${parsedEmails.length} emails from CSV');
          }
        } else {
          if (mounted) {
            AppToast.info(context, 'No valid emails found in the file');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to import CSV', description: e.toString());
      }
    }
  }

  List<String> _parseEmailsFromCSV(String content) {
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    return emailRegex.allMatches(content).map((m) => m.group(0)!).toList();
  }

  void _sendInvites() {
    final rawText = _emailsCtrl.text.trim();
    if (rawText.isEmpty) {
      AppToast.error(context, 'Please enter email addresses or upload a CSV');
      return;
    }

    setState(() => _isSending = true);

    // Extract emails
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final emails = emailRegex.allMatches(rawText).map((m) => m.group(0)!).toList();

    if (emails.isEmpty) {
      AppToast.error(context, 'No valid emails detected');
      setState(() => _isSending = false);
      return;
    }

    // Simulate invite dispatch
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      setState(() {
        for (var email in emails) {
          // Check for duplicate
          if (!_sentInvites.any((inv) => inv['email'].toString().toLowerCase() == email.toLowerCase())) {
            _sentInvites.insert(0, {
              'email': email,
              'role': _selectedRole,
              'department': _selectedDept,
              'status': 'sent',
              'date': today,
            });
          }
        }
        _emailsCtrl.clear();
        _isSending = false;
      });

      _saveInvitesToHive();
      AppToast.success(context, 'Successfully dispatched ${emails.length} invitations');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bulk Invite Team'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: !_boxInitialized
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Form section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite via Email Addresses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodyLarge?.color,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter multiple email addresses separated by commas, or upload a CSV file with an email column.',
                          style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailsCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'e.g., employee1@company.com, employee2@company.com',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 50),
                              child: IconButton(
                                icon: const Icon(Icons.cloud_upload_outlined),
                                tooltip: 'Upload CSV File',
                                onPressed: _pickCSVFile,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Dropdown selectors for Role and Department
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Default Role',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.hintColor),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedRole,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'member', child: Text('Member')),
                                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedRole = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Department',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.hintColor),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedDept,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Engineering', child: Text('Engineering')),
                                      DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
                                      DropdownMenuItem(value: 'Sales', child: Text('Sales')),
                                      DropdownMenuItem(value: 'HR', child: Text('HR')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedDept = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSending ? null : _sendInvites,
                            child: _isSending
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Send Invites'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Invitation status list header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Sent Invitations (${_sentInvites.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),

                // Invitation list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: _sentInvites.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                'No invites sent yet.',
                                style: TextStyle(color: theme.hintColor),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final invite = _sentInvites[index];
                              return _buildInviteCard(context, invite, index);
                            },
                            childCount: _sentInvites.length,
                          ),
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildInviteCard(BuildContext context, Map<String, dynamic> invite, int index) {
    final theme = Theme.of(context);
    final email = invite['email'] ?? '';
    final role = invite['role'] ?? 'member';
    final dept = invite['department'] ?? '';
    final status = invite['status'] ?? 'pending';
    final date = invite['date'] ?? '';

    Color statusColor;
    switch (status) {
      case 'accepted':
        statusColor = AppColors.success;
        break;
      case 'sent':
        statusColor = theme.colorScheme.primary;
        break;
      default:
        statusColor = theme.hintColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role[0].toUpperCase() + role.substring(1),
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dept,
                      style: TextStyle(fontSize: 11, color: theme.hintColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sent $date',
                      style: TextStyle(fontSize: 10, color: theme.hintColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              if (status != 'accepted')
                TextButton(
                  onPressed: () {
                    // Resend invite simulation
                    AppToast.success(context, 'Invitation resent to $email');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Resend', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
