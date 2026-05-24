import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/post_repository.dart';

class NewPostScreen extends ConsumerStatefulWidget {
  const NewPostScreen({super.key});

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  late final MarkdownTextEditingController _postController;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  bool _isPosting = false;
  bool _isAnonymous = false;

  File? _mediaFile;
  String? _mediaType; // 'image' or 'video'
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _postController = MarkdownTextEditingController(
      syntaxColor: const Color(0x66009688), // Subtle teal transparency
      boldStyle: const TextStyle(fontWeight: FontWeight.bold),
      italicStyle: const TextStyle(fontStyle: FontStyle.italic),
      underlineStyle: const TextStyle(decoration: TextDecoration.underline),
      strikethroughStyle: const TextStyle(decoration: TextDecoration.lineThrough),
      codeStyle: const TextStyle(fontFamily: 'monospace'),
      headingStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _mediaFile = File(image.path);
          _mediaType = 'image';
        });
      }
    } catch (e) {
      AppToast.error(context, 'Failed to pick image', description: e.toString());
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _mediaFile = File(video.path);
          _mediaType = 'video';
        });
      }
    } catch (e) {
      AppToast.error(context, 'Failed to pick video', description: e.toString());
    }
  }

  void _removeMedia() {
    setState(() {
      _mediaFile = null;
      _mediaType = null;
    });
  }

  Future<void> _submitPost() async {
    final userState = ref.read(authStateProvider);
    final user = userState.value;
    final content = _postController.text.trim();
    final title = _titleController.text.trim();

    if (user == null) {
      AppToast.error(context, 'You must be logged in to post');
      return;
    }
    if (content.isEmpty && title.isEmpty && _mediaFile == null) {
      AppToast.warning(context, 'Post cannot be completely empty');
      return;
    }

    setState(() => _isPosting = true);

    try {
      await ref.read(postRepositoryProvider).createPost(
        uid: user.$id,
        title: title,
        content: content,
        isAnonymous: _isAnonymous,
        mediaFile: _mediaFile,
        mediaType: _mediaType,
      );

      if (mounted) {
        AppToast.success(
          context, 
          _isAnonymous ? 'Posted anonymously!' : 'Post shared successfully!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to post', description: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    _titleController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Text(
          'New Post',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.xmark,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isPosting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    onPressed: _submitPost,
                    child: Text(
                      'Post',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title/Header text input container
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _titleController,
                  maxLines: 1,
                  enabled: !_isPosting,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: "Add a title (optional)",
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Post text input container
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _postController,
                      focusNode: _contentFocusNode,
                      maxLines: 6,
                      enabled: !_isPosting,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: _isAnonymous
                            ? "Share your thoughts anonymously in a judgment-free space..."
                            : "What's on your mind?",
                        hintStyle: TextStyle(color: hintColor),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFormatToolbar(
                      isDark,
                      primaryColor,
                      isDark ? AppColors.darkSurface2 : AppColors.background,
                      borderCol,
                      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              // Selected Media Preview (if any)
              if (_mediaFile != null) ...[
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _mediaType == 'image'
                          ? Image.file(
                              _mediaFile!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 180,
                              color: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.video_camera_solid,
                                      color: primaryColor,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Video Selected',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _mediaFile!.path.split('/').last,
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _isPosting ? null : _removeMedia,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Media Picker Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPosting ? null : _pickImage,
                      icon: const Icon(CupertinoIcons.photo),
                      label: const Text('Add Image'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: primaryColor,
                        side: BorderSide(color: borderCol, width: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPosting ? null : _pickVideo,
                      icon: const Icon(CupertinoIcons.video_camera),
                      label: const Text('Add Video'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: primaryColor,
                        side: BorderSide(color: borderCol, width: 1.2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Post anonymously switch
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol, width: 1.2),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isAnonymous
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : (isDark ? AppColors.darkSurface2 : AppColors.background),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAnonymous ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                        color: _isAnonymous ? AppColors.accent : primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Post Anonymously",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Hide your identity. Moderation features will be disabled for this post.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: _isAnonymous,
                      activeTrackColor: AppColors.accent,
                      onChanged: _isPosting
                          ? null
                          : (val) {
                              setState(() {
                                _isAnonymous = val;
                              });
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyFormat(String prefix, String suffix) {
    _contentFocusNode.requestFocus();
    final text = _postController.text;
    final selection = _postController.selection;
    
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start;
      final end = selection.end;
      
      final selectedText = text.substring(start, end);
      final newText = text.replaceRange(start, end, '$prefix$selectedText$suffix');
      
      _postController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: end + prefix.length,
        ),
      );
    } else {
      final start = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(start, start, '$prefix$suffix');
      _postController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length),
      );
    }
  }

  void _applyLinePrefix(String prefix) {
    _contentFocusNode.requestFocus();
    final text = _postController.text;
    final selection = _postController.selection;
    
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    
    int lineStart = start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    
    final beforeText = text.substring(0, lineStart);
    final selectionText = text.substring(lineStart, end);
    final afterText = text.substring(end);
    
    final lines = selectionText.split('\n');
    final formattedLines = lines.map((line) {
      if (line.startsWith(prefix)) {
        return line.substring(prefix.length);
      }
      return '$prefix$line';
    }).join('\n');
    
    final newText = '$beforeText$formattedLines$afterText';
    
    _postController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: lineStart,
        extentOffset: lineStart + formattedLines.length,
      ),
    );
  }

  Widget _buildFormatToolbar(
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
    Color borderCol,
    Color textSecondary,
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        children: [
          _buildFormatButton(
            icon: CupertinoIcons.bold,
            tooltip: "Bold",
            onTap: () => _applyFormat("**", "**"),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.italic,
            tooltip: "Italic",
            onTap: () => _applyFormat("*", "*"),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.underline,
            tooltip: "Underline",
            onTap: () => _applyFormat("__", "__"),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.strikethrough,
            tooltip: "Strikethrough",
            onTap: () => _applyFormat("~~", "~~"),
            color: primaryColor,
          ),
          _buildDivider(borderCol),
          _buildFormatButton(
            icon: Icons.title,
            tooltip: "Heading",
            onTap: () => _applyLinePrefix("### "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.list_bullet,
            tooltip: "Bullet List",
            onTap: () => _applyLinePrefix("- "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.list_number,
            tooltip: "Numbered List",
            onTap: () => _applyLinePrefix("1. "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.square_list,
            tooltip: "Checklist",
            onTap: () => _applyLinePrefix("- [ ] "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: CupertinoIcons.quote_bubble,
            tooltip: "Quote",
            onTap: () => _applyLinePrefix("> "),
            color: primaryColor,
          ),
          _buildFormatButton(
            icon: Icons.code,
            tooltip: "Code Block",
            onTap: () => _applyFormat("```\n", "\n```"),
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(Color borderCol) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      width: 1,
      color: borderCol,
    );
  }
}

class MarkdownTextEditingController extends TextEditingController {
  final Color syntaxColor;
  final TextStyle boldStyle;
  final TextStyle italicStyle;
  final TextStyle underlineStyle;
  final TextStyle strikethroughStyle;
  final TextStyle codeStyle;
  final TextStyle headingStyle;

  MarkdownTextEditingController({
    super.text,
    required this.syntaxColor,
    required this.boldStyle,
    required this.italicStyle,
    required this.underlineStyle,
    required this.strikethroughStyle,
    required this.codeStyle,
    required this.headingStyle,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final textVal = value.text;
    if (textVal.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final topLevelRegExp = RegExp(
      r'(```[\s\S]*?```)|(\*\*\*.*?\*\*\*)|(\*\*.*?\*\*)|(\*.*?\*)|(__.*?__)|(~~.*?~~)|(`.*?`)|(^### .*$)',
      multiLine: true,
    );

    final nestedRegExp = RegExp(
      r'(\*\*\*.*?\*\*\*)|(\*\*.*?\*\*)|(\*.*?\*)|(__.*?__)|(~~.*?~~)',
      multiLine: true,
    );

    List<InlineSpan> parse(String text, TextStyle? currentStyle, bool isTopLevel) {
      if (text.isEmpty) return [];

      final activeRegExp = isTopLevel ? topLevelRegExp : nestedRegExp;
      final match = activeRegExp.firstMatch(text);
      if (match == null) {
        return [TextSpan(text: text, style: currentStyle)];
      }

      final List<InlineSpan> spans = [];

      // 1. Text before match
      if (match.start > 0) {
        spans.addAll(parse(text.substring(0, match.start), currentStyle, isTopLevel));
      }

      // 2. The match itself
      final matchedText = match.group(0)!;

      if (isTopLevel && match.group(1) != null) {
        // Code block: ```[\s\S]*?```
        final content = matchedText.substring(3, matchedText.length - 3);
        spans.add(TextSpan(text: '```', style: currentStyle?.copyWith(color: syntaxColor)));
        spans.add(TextSpan(text: content, style: currentStyle?.merge(codeStyle)));
        spans.add(TextSpan(text: '```', style: currentStyle?.copyWith(color: syntaxColor)));
      } else {
        if (matchedText.startsWith('***') && matchedText.endsWith('***') && matchedText.length >= 6) {
          final content = matchedText.substring(3, matchedText.length - 3);
          spans.add(TextSpan(text: '***', style: currentStyle?.copyWith(color: syntaxColor)));
          spans.addAll(parse(content, currentStyle?.merge(boldStyle).merge(italicStyle), false));
          spans.add(TextSpan(text: '***', style: currentStyle?.copyWith(color: syntaxColor)));
        } else if (matchedText.startsWith('**') && matchedText.endsWith('**') && matchedText.length >= 4) {
          final content = matchedText.substring(2, matchedText.length - 2);
          spans.add(TextSpan(text: '**', style: currentStyle?.copyWith(color: syntaxColor)));
          spans.addAll(parse(content, currentStyle?.merge(boldStyle), false));
          spans.add(TextSpan(text: '**', style: currentStyle?.copyWith(color: syntaxColor)));
        } else if (matchedText.startsWith('__') && matchedText.endsWith('__') && matchedText.length >= 4) {
          final content = matchedText.substring(2, matchedText.length - 2);
          spans.add(TextSpan(text: '__', style: currentStyle?.copyWith(color: syntaxColor)));
          spans.addAll(parse(content, currentStyle?.merge(underlineStyle), false));
          spans.add(TextSpan(text: '__', style: currentStyle?.copyWith(color: syntaxColor)));
        } else if (matchedText.startsWith('~~') && matchedText.endsWith('~~') && matchedText.length >= 4) {
          final content = matchedText.substring(2, matchedText.length - 2);
          spans.add(TextSpan(text: '~~', style: currentStyle?.copyWith(color: syntaxColor)));
          spans.addAll(parse(content, currentStyle?.merge(strikethroughStyle), false));
          spans.add(TextSpan(text: '~~', style: currentStyle?.copyWith(color: syntaxColor)));
        } else if (matchedText.startsWith('*') && matchedText.endsWith('*') && matchedText.length >= 2) {
          final content = matchedText.substring(1, matchedText.length - 1);
          spans.add(TextSpan(text: '*', style: currentStyle?.copyWith(color: syntaxColor)));
          spans.addAll(parse(content, currentStyle?.merge(italicStyle), false));
          spans.add(TextSpan(text: '*', style: currentStyle?.copyWith(color: syntaxColor)));
        } else if (isTopLevel && matchedText.startsWith('`') && matchedText.endsWith('`') && matchedText.length >= 2) {
          final content = matchedText.substring(1, matchedText.length - 1);
          spans.add(TextSpan(text: '`', style: currentStyle?.copyWith(color: syntaxColor)));
          spans.add(TextSpan(text: content, style: currentStyle?.merge(codeStyle)));
          spans.add(TextSpan(text: '`', style: currentStyle?.copyWith(color: syntaxColor)));
        } else if (isTopLevel && matchedText.startsWith('### ')) {
          spans.add(TextSpan(text: '### ', style: currentStyle?.copyWith(color: syntaxColor)));
          final content = matchedText.substring(4);
          spans.addAll(parse(content, currentStyle?.merge(headingStyle), false));
        } else {
          spans.add(TextSpan(text: matchedText, style: currentStyle));
        }
      }

      // 3. Text after match
      if (match.end < text.length) {
        spans.addAll(parse(text.substring(match.end), currentStyle, isTopLevel));
      }

      return spans;
    }

    final children = parse(textVal, style, true);
    return TextSpan(children: children, style: style);
  }
}
