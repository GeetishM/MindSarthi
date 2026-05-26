import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/app_lock/app_lock_settings_screen.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';
import 'package:mindsarthi/core/widgets/theme_toggle.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';

class ProfessionalProfile extends ConsumerStatefulWidget {
  const ProfessionalProfile({super.key});

  @override
  ConsumerState<ProfessionalProfile> createState() => _ProfessionalProfileState();
}

class _ProfessionalProfileState extends ConsumerState<ProfessionalProfile> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  bool _isLoading = true;
  File? _localImageFile;
  String? _profileImageUrl;
  bool _isSaving = false;
  bool _isVerified = false;
  List<String> _specializations = [];
  List<models.Document> _certificates = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _experienceCtrl.dispose();
    _specCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;
      final databases = AppwriteService().databases;

      String defaultName = user.name;
      String? imageUrl;
      try {
        final userDoc = await databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollectionId,
          documentId: user.$id,
        );
        defaultName = userDoc.data['name'] ?? user.name;
        imageUrl = userDoc.data['profileImageUrl'];
      } catch (_) {}

      try {
        final doc = await databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.professionalProfilesCollectionId,
          documentId: user.$id,
        );

        final data = doc.data;
        _nameCtrl.text = data['name'] ?? defaultName;
        _bioCtrl.text = data['bio'] ?? '';
        _experienceCtrl.text = (data['experience'] ?? 0).toString();
        _specializations = List<String>.from(data['specializations'] ?? []);
        _isVerified = data['isVerified'] ?? false;
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          _nameCtrl.text = defaultName;
          _experienceCtrl.text = '0';
          _specializations = [];
          _isVerified = false;
        } else {
          rethrow;
        }
      }

      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
        });
      }
      await _loadCertificates();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCertificates() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final databases = AppwriteService().databases;
    try {
      final res = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.certificatesCollectionId,
        queries: [
          Query.equal('userId', user.$id),
        ],
      );
      if (mounted) {
        setState(() {
          _certificates = res.documents;
        });
      }
    } catch (e) {
      debugPrint('Error loading certificates: $e');
    }
  }

  bool _checkCompleteness() {
    final name = _nameCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final expText = _experienceCtrl.text.trim();
    final hasCertificates = _certificates.isNotEmpty;
    final hasSpecializations = _specializations.isNotEmpty;

    return name.isNotEmpty &&
        bio.isNotEmpty &&
        expText.isNotEmpty &&
        hasSpecializations &&
        hasCertificates;
  }

  double _calculateCompletenessPercentage() {
    double percent = 0.0;
    if (_nameCtrl.text.trim().isNotEmpty) percent += 0.2;
    if (_bioCtrl.text.trim().isNotEmpty) percent += 0.2;
    if (_experienceCtrl.text.trim().isNotEmpty) percent += 0.2;
    if (_specializations.isNotEmpty) percent += 0.2;
    if (_certificates.isNotEmpty) percent += 0.2;
    return percent;
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;
      final databases = AppwriteService().databases;

      String? imageUrl = _profileImageUrl;
      if (_localImageFile != null) {
        final uploadedUrl = await _uploadProfileImage(_localImageFile!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          if (mounted) {
            AppToast.error(context, 'Failed to upload profile photo');
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      final expVal = int.tryParse(_experienceCtrl.text.trim()) ?? 0;
      final isComplete = _checkCompleteness();

      bool docExists = false;
      try {
        await databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.professionalProfilesCollectionId,
          documentId: user.$id,
        );
        docExists = true;
      } catch (_) {}

      final profileData = {
        'userId': user.$id,
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'experience': expVal,
        'specializations': _specializations,
        'role': 'professional',
        'rating': 5.0,
        'reviewsCount': 0,
        'startingPrice': 1000,
        'availableSlots': <String>[],
        'isVerified': _isVerified,
        'profileComplete': isComplete,
      };

      if (docExists) {
        await databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.professionalProfilesCollectionId,
          documentId: user.$id,
          data: profileData,
        );
      } else {
        await databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.professionalProfilesCollectionId,
          documentId: user.$id,
          data: profileData,
        );
      }

      try {
        final usersUpdateData = {
          'name': _nameCtrl.text.trim(),
        };
        if (imageUrl != null) {
          usersUpdateData['profileImageUrl'] = imageUrl;
        }
        await databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollectionId,
          documentId: user.$id,
          data: usersUpdateData,
        );
      } catch (e) {
        debugPrint('Error updating users collection document: $e');
      }

      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
          _localImageFile = null;
        });
      }

      if (mounted) AppToast.success(context, 'Profile saved successfully!');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Save failed', description: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSpecialization() {
    final text = _specCtrl.text.trim();
    if (text.isNotEmpty && !_specializations.contains(text)) {
      setState(() {
        _specializations.add(text);
        _specCtrl.clear();
      });
    }
  }

  Future<void> _deleteCertificate(String docId, String fileId) async {
    try {
      final databases = AppwriteService().databases;
      final storage = AppwriteService().storage;

      await databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.certificatesCollectionId,
        documentId: docId,
      );

      if (fileId.isNotEmpty) {
        try {
          await storage.deleteFile(
            bucketId: AppwriteConstants.certificatesBucketId,
            fileId: fileId,
          );
        } catch (e) {
          debugPrint('Error deleting certificate file: $e');
        }
      }

      if (mounted) AppToast.success(context, 'Certificate removed');
      await _loadCertificates();
      await _saveProfile();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to delete certificate', description: e.toString());
      }
    }
  }

  void _showAddCertificateDialog() {
    final titleCtrl = TextEditingController();
    final instCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    PlatformFile? selectedFile;
    bool isUploadingFile = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            Future<void> pickDoc() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                );
                if (result != null) {
                  setDialogState(() {
                    selectedFile = result.files.single;
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.error(context, 'File picker error', description: e.toString());
                }
              }
            }

            Future<void> submit() async {
              final title = titleCtrl.text.trim();
              final inst = instCtrl.text.trim();
              final yearText = yearCtrl.text.trim();
              final year = int.tryParse(yearText);

              if (title.isEmpty || inst.isEmpty || year == null || selectedFile == null) {
                if (context.mounted) {
                  AppToast.warning(context, 'Please fill in all fields and select a file.');
                }
                return;
              }

              setDialogState(() => isUploadingFile = true);

              try {
                final user = ref.read(authStateProvider).value;
                if (user == null) return;

                final databases = AppwriteService().databases;
                final storage = AppwriteService().storage;

                String fileId = ID.unique();
                await storage.createFile(
                  bucketId: AppwriteConstants.certificatesBucketId,
                  fileId: fileId,
                  file: InputFile.fromPath(
                    path: selectedFile!.path!,
                    filename: selectedFile!.name,
                  ),
                );

                await databases.createDocument(
                  databaseId: AppwriteConstants.databaseId,
                  collectionId: AppwriteConstants.certificatesCollectionId,
                  documentId: ID.unique(),
                  data: {
                    'userId': user.$id,
                    'degreeName': title,
                    'institution': inst,
                    'year': year,
                    'fileId': fileId,
                    'fileType': selectedFile!.extension ?? 'pdf',
                    'verified': false,
                  },
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (context.mounted) {
                  AppToast.success(context, 'Certificate added successfully!');
                }
                await _loadCertificates();
                await _saveProfile();
              } catch (e) {
                if (context.mounted) {
                  AppToast.error(context, 'Upload failed', description: e.toString());
                }
              } finally {
                setDialogState(() => isUploadingFile = false);
              }
            }

            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Add Certificate/Degree',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              content: isUploadingFile
                  ? const SizedBox(
                      height: 150,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Uploading document... Please wait.'),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Degree / Certificate Title',
                              hintText: 'e.g. Master of Clinical Psychology',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: instCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Institution',
                              hintText: 'e.g. Boston University',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: yearCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Graduation Year',
                              hintText: 'e.g. 2020',
                            ),
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: pickDoc,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.upload_file_rounded, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedFile != null
                                          ? selectedFile!.name
                                          : 'Select Certificate (PDF/Image)',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              actions: isUploadingFile
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: const Text('Add'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await ref.read(authStateProvider.notifier).signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Logout failed', description: e.toString());
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  title: Text('Choose from Gallery', style: TextStyle(color: textPrimary)),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70,
                    );
                    if (file != null) {
                      setState(() {
                        _localImageFile = File(file.path);
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  title: Text('Take a Photo', style: TextStyle(color: textPrimary)),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                    );
                    if (file != null) {
                      setState(() {
                        _localImageFile = File(file.path);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _uploadProfileImage(File file) async {
    try {
      final appwrite = AppwriteService();
      final storage = Storage(appwrite.client);
      final uniqueId = ID.unique();
      final uploadedFile = await storage.createFile(
        bucketId: AppwriteConstants.mediaBucketId,
        fileId: uniqueId,
        file: InputFile.fromPath(
          path: file.path,
          filename: file.path.split('/').last,
        ),
      );
      final viewUrl = 'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteConstants.mediaBucketId}/files/${uploadedFile.$id}/view?project=${appwrite.client.config['project']}';
      return viewUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    return Text(
      (_nameCtrl.text.isNotEmpty) ? _nameCtrl.text[0].toUpperCase() : 'D',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, bool isDark) {
    final activeColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                activeColor,
                accentColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurface : AppColors.white,
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
              child: _localImageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(
                        _localImageFile!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            _profileImageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(theme),
                          ),
                        )
                      : _buildInitialsAvatar(theme),
            ),
          ),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.headlineSmall?.color ?? theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: Text(
                  _isSaving ? 'Saving...' : 'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompletenessProgress(),
                  const SizedBox(height: 24),

                  Center(
                    child: _buildAvatar(theme, isDark),
                  ),
                  const SizedBox(height: 28),

                  _buildLabel('Display Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Dr. Jane Smith',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Experience (Years)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _experienceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '10',
                      prefixIcon: Icon(Icons.work_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Bio'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'A brief introduction about yourself...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Specializations'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _specCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. CBT, Anxiety',
                          ),
                          onFieldSubmitted: (_) => _addSpecialization(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addSpecialization,
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _specializations.map((spec) {
                      return Chip(
                        label: Text(spec),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () =>
                            setState(() => _specializations.remove(spec)),
                        backgroundColor: theme.colorScheme.tertiary,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        deleteIconColor: theme.colorScheme.primary,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  _buildCertificatesSection(),
                  const SizedBox(height: 32),

                  Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodySmall?.color,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        CupertinoIcons.lock_shield,
                        color: theme.textTheme.bodyMedium?.color,
                        size: 22,
                      ),
                      title: const Text(
                        'App Lock',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Secure your app with a passcode',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        CupertinoIcons.chevron_forward,
                        color: theme.textTheme.bodySmall?.color,
                        size: 16,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AppLockSettingsScreen()),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                        color: theme.textTheme.bodyMedium?.color,
                        size: 22,
                      ),
                      title: Text(
                        isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      subtitle: Text(
                        'Toggle app theme',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      trailing: const ThemeToggleSwitch(),
                      onTap: () => context.read<ThemeProvider>().toggle(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      onTap: _logout,
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      subtitle: Text(
                        'Sign out of your account',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCompletenessProgress() {
    final theme = Theme.of(context);
    final percent = _calculateCompletenessPercentage();
    final isComplete = percent >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete ? 'Profile Complete!' : 'Complete Your Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 15,
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
              minHeight: 8,
            ),
          ),
          if (!isComplete) ...[
            const SizedBox(height: 10),
            Text(
              'Add name, bio, experience, specialization, and at least one certificate/degree to unlock Insights CMS and appear in counselling search results.',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertificatesSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Certificates & Degrees'),
            TextButton.icon(
              onPressed: _showAddCertificateDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_certificates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.card_membership_rounded,
                  size: 40,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(height: 10),
                Text(
                  'No certificates or degrees added yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _certificates.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cert = _certificates[index];
              final isVerified = cert.data['verified'] as bool? ?? false;
              final fileType = cert.data['fileType'] as String? ?? 'pdf';
              final docId = cert.$id;
              final fileId = cert.data['fileId'] as String? ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiary,
                    child: Icon(
                      fileType.toLowerCase() == 'pdf'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    cert.data['degreeName'] ?? 'Degree',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cert.data['institution'] ?? 'Institution'} (${cert.data['year'] ?? ''})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isVerified ? 'Verified' : 'Pending Verification',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _deleteCertificate(docId, fileId),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: theme.textTheme.bodyMedium?.color,
      ),
    );
  }
}
