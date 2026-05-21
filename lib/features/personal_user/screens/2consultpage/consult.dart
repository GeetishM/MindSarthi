import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

class Therapist {
  final String id;
  final String name;
  final String role;
  final String experience;
  final double rating;
  final int reviewsCount;
  final int startingPrice;
  final List<String> expertiseTags;
  final String biography;
  final List<String> availableSlots;
  final Color avatarColor;

  const Therapist({
    required this.id,
    required this.name,
    required this.role,
    required this.experience,
    required this.rating,
    required this.reviewsCount,
    required this.startingPrice,
    required this.expertiseTags,
    required this.biography,
    required this.availableSlots,
    required this.avatarColor,
  });
}

class Session {
  final String id;
  final String therapistName;
  final String status;
  final DateTime dateTime;
  final String type; // Video, Voice, Chat

  const Session({
    required this.id,
    required this.therapistName,
    required this.status,
    required this.dateTime,
    required this.type,
  });
}

const List<Therapist> kTherapists = [
  Therapist(
    id: '1',
    name: 'Dr. Neha Sharma',
    role: 'Consultant Psychiatrist',
    experience: '12 years',
    rating: 4.9,
    reviewsCount: 124,
    startingPrice: 800,
    expertiseTags: ['Anxiety', 'Depression'],
    biography: 'Dr. Neha is a licensed psychiatrist specializing in clinical treatments for mood and developmental disorders, helping people lead balanced lives.',
    availableSlots: ['02:00 PM', '04:30 PM', '06:00 PM'],
    avatarColor: Colors.teal,
  ),
  Therapist(
    id: '2',
    name: 'Dr. John Doe',
    role: 'Clinical Psychologist',
    experience: '10 years',
    rating: 4.7,
    reviewsCount: 98,
    startingPrice: 600,
    expertiseTags: ['OCD', 'Sleep', 'Stress'],
    biography: 'Dr. John employs cognitive behavioral therapy strategies to resolve OCD, sleep disturbances, and prolonged chronic stress patterns.',
    availableSlots: ['09:00 AM', '11:30 AM', '03:00 PM'],
    avatarColor: Colors.indigo,
  ),
  Therapist(
    id: '3',
    name: 'Dr. Jane Smith',
    role: 'CBT Therapist',
    experience: '8 years',
    rating: 4.8,
    reviewsCount: 84,
    startingPrice: 500,
    expertiseTags: ['Anxiety', 'Depression', 'Relationship'],
    biography: 'Jane focuses on collaborative relationship therapy and structured Cognitive Behavioral Therapy to overcome emotional challenges.',
    availableSlots: ['10:00 AM', '01:00 PM', '05:30 PM'],
    avatarColor: Colors.purple,
  ),
  Therapist(
    id: '4',
    name: 'Arjun Mehta',
    role: 'Clinical Social Worker',
    experience: '6 years',
    rating: 4.6,
    reviewsCount: 57,
    startingPrice: 450,
    expertiseTags: ['Stress', 'Relationship'],
    biography: 'Arjun brings extensive clinical social work experience to support individuals recovering from trauma and relationship strain.',
    availableSlots: ['11:00 AM', '03:30 PM', '07:00 PM'],
    avatarColor: Colors.amber,
  ),
];

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  String _selectedCategory = 'All';
  String _selectedSort = 'Rating';
  List<Session> _sessions = [];

  final List<String> _categories = [
    'All',
    'Anxiety',
    'Depression',
    'OCD',
    'Stress',
    'Sleep',
    'Relationship',
  ];

  @override
  void initState() {
    super.initState();
    _sessions = [
      Session(
        id: 's1',
        therapistName: 'Dr. Neha Sharma',
        status: 'Upcoming',
        dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        type: 'Video',
      ),
      Session(
        id: 's2',
        therapistName: 'Dr. John Doe',
        status: 'Completed',
        dateTime: DateTime.now().subtract(const Duration(days: 3)),
        type: 'Voice',
      ),
    ];
  }

  int _parseSlotHour(String slot) {
    final parts = slot.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.tryParse(timeParts[0]) ?? 9;
    final ampm = parts[1];
    if (ampm == 'PM' && hour != 12) {
      hour += 12;
    } else if (ampm == 'AM' && hour == 12) {
      hour = 0;
    }
    return hour;
  }

  int _parseSlotMinute(String slot) {
    final parts = slot.split(' ');
    final timeParts = parts[0].split(':');
    return int.tryParse(timeParts[1]) ?? 0;
  }

  void _openBookingSheet(BuildContext context, Therapist therapist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BookingSheet(
          therapist: therapist,
          onBookingConfirmed: (DateTime selectedDate, String selectedSlot, String medium) {
            final newSession = Session(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              therapistName: therapist.name,
              status: 'Upcoming',
              dateTime: DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                _parseSlotHour(selectedSlot),
                _parseSlotMinute(selectedSlot),
              ),
              type: medium,
            );
            setState(() {
              _sessions.insert(0, newSession);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Session booked with ${therapist.name}!",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    // Filter therapists
    final filteredTherapists = kTherapists.where((t) {
      if (_selectedCategory == 'All') return true;
      return t.expertiseTags.contains(_selectedCategory);
    }).toList();

    // Sort therapists
    if (_selectedSort == 'Price') {
      filteredTherapists.sort((a, b) => a.startingPrice.compareTo(b.startingPrice));
    } else if (_selectedSort == 'Experience') {
      int getYears(String exp) => int.tryParse(exp.replaceAll(RegExp(r'\D'), '')) ?? 0;
      filteredTherapists.sort((a, b) => getYears(b.experience).compareTo(getYears(a.experience)));
    } else if (_selectedSort == 'Rating') {
      filteredTherapists.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          "EXPERTS",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: scaffoldBg,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sessions Section
          if (_sessions.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Sessions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        itemCount: _sessions.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          return SessionCard(
                            session: _sessions[index],
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Book a Session Title & Filter Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Book a Session',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  FilterButton(
                    
                    isDark: isDark,
                    selectedSort: _selectedSort,
                    onSelected: (val) {
                      setState(() {
                        _selectedSort = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Categories Horizontal List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return CategoryPill(
                      category: cat,
                      isSelected: cat == _selectedCategory,
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ),
          ),

          // Therapist List
          if (filteredTherapists.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.person_crop_circle_badge_exclam,
                        size: 48,
                        color: textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No experts available",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Try selecting a different filter category.",
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final therapist = filteredTherapists[index];
                  return TherapistCard(
                    therapist: therapist,
                    isDark: isDark,
                    onBookTap: () => _openBookingSheet(context, therapist),
                  );
                },
                childCount: filteredTherapists.length,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}

class CategoryPill extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const CategoryPill({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : borderCol,
            width: 0.8,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final bool isDark;
  final String selectedSort;
  final ValueChanged<String> onSelected;

  const FilterButton({
    super.key,
    required this.isDark,
    required this.selectedSort,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: isDark ? AppColors.darkSurface2 : AppColors.surface,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return {'Rating', 'Experience', 'Price'}.map((String choice) {
          final isSelected = choice == selectedSort;
          return PopupMenuItem<String>(
            value: choice,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  choice,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                        : textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 16,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        width: 160,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 15,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sort: $selectedSort',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class TherapistCard extends StatelessWidget {
  final Therapist therapist;
  final bool isDark;
  final VoidCallback onBookTap;

  const TherapistCard({
    super.key,
    required this.therapist,
    required this.isDark,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final initials = therapist.name
        .split(' ')
        .where((part) => part.isNotEmpty && part != 'Dr.')
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          therapist.avatarColor,
                          therapist.avatarColor.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials.isEmpty ? 'TX' : initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkSurface : AppColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      therapist.name,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      therapist.role,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${therapist.rating} (${therapist.reviewsCount} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '•  ${therapist.experience}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
            child: Text(
              therapist.biography,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.35,
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: therapist.expertiseTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Price',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${therapist.startingPrice}/hr',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                onPressed: onBookTap,
                child: const Text(
                  'Book Slot',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SessionCard extends StatelessWidget {
  final Session session;
  final bool isDark;

  const SessionCard({
    super.key,
    required this.session,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final isUpcoming = session.status == 'Upcoming';
    final formattedDate = _formatSessionDateTime(session.dateTime);

    IconData typeIcon;
    switch (session.type) {
      case 'Voice':
        typeIcon = CupertinoIcons.phone_fill;
        break;
      case 'Chat':
        typeIcon = CupertinoIcons.chat_bubble_fill;
        break;
      case 'Video':
      default:
        typeIcon = CupertinoIcons.videocam_fill;
        break;
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isUpcoming
                  ? primaryColor.withValues(alpha: 0.1)
                  : (isDark ? AppColors.darkSurface2 : AppColors.border),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                typeIcon,
                size: 24,
                color: isUpcoming ? primaryColor : textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  session.therapistName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight)
                            : (isDark ? AppColors.darkSurface2 : AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        session.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isUpcoming
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                              : textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      session.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isUpcoming ? primaryColor : textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSessionDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final checkDate = DateTime(dt.year, dt.month, dt.day);

    String dateStr;
    if (checkDate == today) {
      dateStr = 'Today';
    } else if (checkDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      dateStr = '${dt.day} ${months[dt.month - 1]}';
    }

    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$dateStr, $displayHour:$minute $ampm';
  }
}

class BookingSheet extends StatefulWidget {
  final Therapist therapist;
  final Function(DateTime date, String slot, String medium) onBookingConfirmed;

  const BookingSheet({
    super.key,
    required this.therapist,
    required this.onBookingConfirmed,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  late DateTime _selectedDate;
  late String _selectedSlot;
  String _selectedMedium = 'Video';
  bool _isConfirming = false;

  final List<DateTime> _dates = [];

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.therapist.availableSlots.first;
    for (int i = 0; i < 3; i++) {
      _dates.add(DateTime.now().add(Duration(days: i)));
    }
    _selectedDate = _dates.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book a Session',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'with ${widget.therapist.name}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      widget.therapist.rating.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.border, height: 1),
          const SizedBox(height: 20),
          Text(
            'Select Date',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _dates.map((date) {
              final isSelected = date.day == _selectedDate.day;
              final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final weekday = weekdays[date.weekday - 1];
              final dayStr = date.day.toString();

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? AppColors.darkBackground : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? primaryColor : borderCol,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekday,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayStr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Available Time Slots',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.therapist.availableSlots.map((slot) {
              final isSelected = slot == _selectedSlot;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSlot = slot;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? AppColors.darkBackground : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? primaryColor : borderCol,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Session Mode',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMediumButton(
                mode: 'Video',
                icon: CupertinoIcons.videocam_fill,
                primaryColor: primaryColor,
                isDark: isDark,
                textPrimary: textPrimary,
                borderCol: borderCol,
              ),
              const SizedBox(width: 8),
              _buildMediumButton(
                mode: 'Voice',
                icon: CupertinoIcons.phone_fill,
                primaryColor: primaryColor,
                isDark: isDark,
                textPrimary: textPrimary,
                borderCol: borderCol,
              ),
              const SizedBox(width: 8),
              _buildMediumButton(
                mode: 'Chat',
                icon: CupertinoIcons.chat_bubble_fill,
                primaryColor: primaryColor,
                isDark: isDark,
                textPrimary: textPrimary,
                borderCol: borderCol,
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              color: primaryColor,
              borderRadius: BorderRadius.circular(16),
              onPressed: _isConfirming
                  ? null
                  : () async {
                      setState(() {
                        _isConfirming = true;
                      });
                      await Future.delayed(const Duration(milliseconds: 800));
                      if (context.mounted) {
                        widget.onBookingConfirmed(_selectedDate, _selectedSlot, _selectedMedium);
                        Navigator.pop(context);
                      }
                    },
              child: _isConfirming
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Text(
                      'Confirm Booking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumButton({
    required String mode,
    required IconData icon,
    required Color primaryColor,
    required bool isDark,
    required Color textPrimary,
    required Color borderCol,
  }) {
    final isSelected = mode == _selectedMedium;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMedium = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark ? AppColors.darkBackground : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : borderCol,
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkPrimary : AppColors.primary),
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                mode,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
