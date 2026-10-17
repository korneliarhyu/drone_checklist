
import 'package:flutter/material.dart';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/database/seed/sample_templates.dart';
import 'package:drone_checklist/theme/app_theme.dart';

class SampleTemplateView extends StatefulWidget {
  const SampleTemplateView({super.key});

  @override
  State<SampleTemplateView> createState() => _SampleTemplateViewState();
}

class _SampleTemplateViewState extends State<SampleTemplateView> {
  bool _isAdded = false;
  bool _isChecking = true;
  bool _isAdding = false;
  DateTime? _addedDate;

  @override
  void initState() {
    super.initState();
    _checkTemplate();
  }

  // Check whether the template already exists.
  Future<void> _checkTemplate() async {
    try {
      final templates = await DatabaseHelper.getAllTemplates();

      final matchingTemplates = templates.where(
            (template) => template['serverTemplateId'] == 900001,
      ).toList();

      final template = matchingTemplates.isNotEmpty
          ? matchingTemplates.first
          : null;

      final rawDate = template?['updatedDate'];
      final addedDate = rawDate is DateTime
          ? rawDate
          : rawDate == null
          ? null
          : DateTime.tryParse(rawDate.toString());

      if (!mounted) return;

      setState(() {
        _isAdded = template != null;
        _addedDate = addedDate;
        _isChecking = false;
      });
    } catch (e) {
      debugPrint('Error checking sample template: $e');

      if (!mounted) return;

      setState(() {
        _isChecking = false;
      });
    }
  }

  // Add sample template.
  Future<void> _addTemplate() async {
    if (_isAdded || _isAdding || _isChecking) return;

    setState(() {
      _isAdding = true;
    });

    try {
      await SampleTemplates.addDroneFlightChecklist();

      if (!mounted) return;

      setState(() {
        _isAdded = true;
        _addedDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Template added successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.forest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error adding template: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to add template. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // App bar
      appBar: AppBar(
        title: const Text('Sample Templates'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Page content
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header introduction
              Text(
                'Get started faster',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Use a ready-made template for your drone flight checklist.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.charcoal.withOpacity(0.75),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Template card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Template icon
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.softGreen,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.flight_takeoff_rounded,
                        size: 30,
                        color: AppColors.forest,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Template details and action
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drone Flight Checklist',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              color: AppColors.charcoal,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Loading while checking the database
                          if (_isChecking)
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.forest,
                              ),
                            )

                          // Template already added
                          else if (_isAdded)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_addedDate != null) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 15,
                                        color: AppColors.sage,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'Added on ${_formatDate(_addedDate!)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.charcoal.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.softGreen,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: AppColors.forest,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Added',
                                        style: TextStyle(
                                          color: AppColors.forest,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )

                          // Add template button
                          else
                            SizedBox(
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: _isAdding ? null : _addTemplate,
                                icon: _isAdding
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(
                                  Icons.add_rounded,
                                  size: 19,
                                ),
                                label: Text(
                                  _isAdding ? 'Adding...' : 'Add Template',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forest,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.sage,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
}
