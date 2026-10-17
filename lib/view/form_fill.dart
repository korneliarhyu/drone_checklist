import 'dart:convert';
import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/widgets/success_dialog.dart';
import 'package:drone_checklist/theme/app_theme.dart';
import 'package:flutter/material.dart';

class FormFill extends StatefulWidget {
  final int formId;
  const FormFill({super.key, required this.formId});

  @override
  State<FormFill> createState() => _FormFillState();
}

class _FormFillState extends State<FormFill> {
  static const List<String> _sections = [
    'assessment',
    'pre',
    'post',
  ];

  static const List<String> _titles = [
    'Assessment',
    'Pre-Flight',
    'Post-Flight',
  ];

  static const List<String> _descriptions = [
    'Evaluate your drone before the flight.',
    'Complete the pre-flight checklist.',
    'Record your post-flight observations.',
  ];

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, Set<String>> _checkedOptions = {};
  final Map<String, bool> _templateRequired = {};
  final Set<String> _requiredKeys = {};
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _formData = [];

  String _formName = 'Drone Flight Checklist';
  String? _loadError;

  int _currentStep = 0;

  bool _loading = true;
  bool _saving = false;
  bool _showErrors = false;
  bool _addPreFlight = false;
  bool _addPostFlight = false;

  String get _currentSection => _sections[_currentStep];

  double get _progress => (_currentStep + 1) / 3;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================
  // HELPERS
  // ==========================================
  String _key(
      String section,
      int flightNumber,
      int questionIndex,
      ) {
    return '$section|$flightNumber|$questionIndex';
  }

  List<dynamic> _asList(dynamic value) {
    return value is List ? value : <dynamic>[];
  }

  String _timestamp() {
    return DateTime.now()
        .toString()
        .split('.')
        .first
        .replaceAll('-', '/');
  }

  Map<String, dynamic>? _sectionData(String section) {
    for (final item in _formData) {
      if (item['type'] == section) {
        return item;
      }
    }
    return null;
  }

  void _registerQuestion(
      String section,
      int flightNumber,
      int questionIndex,
      Map<String, dynamic> question,
      ) {
    final key = _key(
      section,
      flightNumber,
      questionIndex,
    );

    final answer = question['answer']?.toString() ?? '';
    final lookup =
        '$section|${question['questionName']}|${question['qType']}';

    if (question['required'] == true ||
        _templateRequired[lookup] == true) {
      _requiredKeys.add(key);
    }

    _controllers.putIfAbsent(
      key,
          () => TextEditingController(text: answer),
    );

    if (question['qType'] == 'checklist') {
      _checkedOptions.putIfAbsent(
        key,
            () => answer.isEmpty
            ? <String>{}
            : answer
            .split(', ')
            .where((item) => item.isNotEmpty)
            .toSet(),
      );
    }
  }

  // ==========================================
  // LOAD TEMPLATE VALIDATION
  // ==========================================

  Future<void> _loadTemplateRules(dynamic templateId) async {
    if (templateId == null) return;

    try {
      final id = templateId is num
          ? templateId.toInt()
          : int.tryParse(templateId.toString());

      if (id == null) return;

      final template =
      await DatabaseHelper.getTemplateById(id);

      final raw = template['templateFormData'];

      final data = raw is String
          ? jsonDecode(raw)
          : raw;

      if (data is! Map) return;

      for (final section in _sections) {
        final questions = data[section];

        if (questions is! Map) continue;

        for (final question in questions.values) {
          if (question is! Map) continue;

          final lookup =
              '$section|${question['question']}|${question['type']}';

          _templateRequired[lookup] =
              question['required'] == true;
        }
      }
    } catch (e) {
      debugPrint('Template validation unavailable: $e');
    }
  }

  // ==========================================
  // LOAD FORM DATA
  // ==========================================

  Future<void> _loadFormData() async {
    try {
      final form =
      await DatabaseHelper.getFormById(widget.formId);

      if (form == null) {
        if (!mounted) return;

        setState(() {
          _loadError = 'Form not found.';
          _loading = false;
        });

        return;
      }

      await _loadTemplateRules(form['templateId']);

      final raw =
          form['updatedFormData'] ?? form['formData'];

      final decoded =
      raw is String ? jsonDecode(raw) : raw;

      final sections = _asList(decoded)
          .map(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

      for (final section in sections) {
        final type = section['type']?.toString() ?? '';

        final answers = _asList(section['answer']);

        if (type == 'assessment') {
          for (var i = 0; i < answers.length; i++) {
            _registerQuestion(
              type,
              0,
              i,
              Map<String, dynamic>.from(
                answers[i] as Map,
              ),
            );
          }
        } else if (type == 'pre' || type == 'post') {
          for (final flight in answers) {
            final flightMap =
            Map<String, dynamic>.from(flight as Map);

            final number =
                (flightMap['flightNum'] as num?)
                    ?.toInt() ??
                    1;

            final questions =
            _asList(flightMap['data']);

            for (var i = 0; i < questions.length; i++) {
              _registerQuestion(
                type,
                number,
                i,
                Map<String, dynamic>.from(
                  questions[i] as Map,
                ),
              );
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _formName =
            form['formName']?.toString() ??
                'Drone Flight Checklist';

        _formData = sections;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Failed to load form: $e';
        _loading = false;
      });
    }
  }

  // ==========================================
  // VALIDATION
  // ==========================================

  bool _questionValid(
      String key,
      Map<String, dynamic> question,
      ) {
    if (!_requiredKeys.contains(key)) {
      return true;
    }

    if (question['qType'] == 'checklist') {
      return _checkedOptions[key]?.isNotEmpty ?? false;
    }

    return _controllers[key]
        ?.text
        .trim()
        .isNotEmpty ??
        false;
  }

  bool _validateStep() {
    final section = _sectionData(_currentSection);

    if (section == null) return true;

    bool valid = true;

    void inspect(
        int flightNumber,
        List<dynamic> questions,
        ) {
      for (var i = 0; i < questions.length; i++) {
        final question =
        Map<String, dynamic>.from(
          questions[i] as Map,
        );

        final key = _key(
          _currentSection,
          flightNumber,
          i,
        );

        if (!_questionValid(key, question)) {
          valid = false;
        }
      }
    }

    if (_currentSection == 'assessment') {
      inspect(
        0,
        _asList(section['answer']),
      );
    } else {
      for (final item in _asList(section['answer'])) {
        final flight =
        Map<String, dynamic>.from(item as Map);

        inspect(
          (flight['flightNum'] as num?)?.toInt() ?? 1,
          _asList(flight['data']),
        );
      }
    }

    setState(() {
      _showErrors = !valid;
    });

    return valid;
  }

  // ==========================================
  // NAVIGATION
  // ==========================================

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.jumpTo(0);
  }

  void _next() {
    if (!_validateStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete the required fields first.',
          ),
        ),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    if (_currentStep == 2) {
      _save();
      return;
    }

    setState(() {
      _currentStep++;
      _showErrors = false;
    });

    _scrollToTop();
  }

  void _back() {
    if (_currentStep == 0) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _currentStep--;
      _showErrors = false;
    });

    _scrollToTop();
  }

  // ==========================================
  // UPDATE ANSWERS
  // ==========================================

  void _writeAnswers(
      String section,
      int flightNumber,
      List<dynamic> questions,
      ) {
    for (var i = 0; i < questions.length; i++) {
      final item = questions[i] as Map;

      final key = _key(
        section,
        flightNumber,
        i,
      );

      final type = item['qType']?.toString() ?? '';

      if (type == 'checklist') {
        item['answer'] =
            (_checkedOptions[key] ?? <String>{})
                .join(', ');
      } else {
        item['answer'] =
            _controllers[key]?.text ??
                item['answer']?.toString() ??
                '';
      }

      item['dataChanged'] = _timestamp();
    }
  }

  // ==========================================
  // ADD NEW FLIGHT
  // ==========================================

  void _appendFlightIfRequested(
      Map<String, dynamic> section,
      ) {
    final type = section['type'];

    final requested =
        (type == 'pre' && _addPreFlight) ||
            (type == 'post' && _addPostFlight);

    if (!requested) return;

    final flights = _asList(section['answer']);

    if (flights.isEmpty) return;

    final last =
    Map<String, dynamic>.from(flights.last as Map);

    final nextNumber = flights
        .map(
          (flight) =>
      ((flight as Map)['flightNum'] as num?)
          ?.toInt() ??
          0,
    )
        .fold<int>(
      0,
          (highest, number) =>
      number > highest ? number : highest,
    ) +
        1;

    final copiedQuestions =
    _asList(last['data'])
        .map(
          (question) =>
      Map<String, dynamic>.from(
        question as Map,
      ),
    )
        .toList();

    flights.add({
      'flightNum': nextNumber,
      'data': copiedQuestions,
    });

    section['answer'] = flights;
  }

  // ==========================================
  // SAVE FORM
  // ==========================================
  Future<void> _save() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final updated =
      (jsonDecode(jsonEncode(_formData)) as List)
          .map(
            (item) => Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();

      for (final section in updated) {
        final type = section['type']?.toString() ?? '';

        if (type == 'assessment') {
          _writeAnswers(
            type,
            0,
            _asList(section['answer']),
          );
        } else if (type == 'pre' || type == 'post') {
          for (final item
          in _asList(section['answer'])) {
            final flight = item as Map;

            _writeAnswers(
              type,
              (flight['flightNum'] as num?)
                  ?.toInt() ??
                  1,
              _asList(flight['data']),
            );
          }

          _appendFlightIfRequested(section);
        }
      }

      final encoded = jsonEncode(updated);

      await DatabaseHelper.updateForm(
        widget.formId,
        encoded,
        encoded,
      );

      if (!mounted) return;

      setState(() {
        _formData = updated;
        _addPreFlight = false;
        _addPostFlight = false;
        _saving = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const SuccessDialog(
          title: 'Updated!',
          message: 'Your changes have been saved.',
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save changes: $e'),
        ),
      );
    }
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _formName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _loadError != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError!,
            textAlign: TextAlign.center,
          ),
        ),
      )
          : Column(
        children: [
          _buildHeader(),

          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24,
              ),
              children: _buildCurrentStep(),
            ),
          ),

          _buildFooter(),
        ],
      ),
    );
  }

  // ==========================================
  // PROGRESS HEADER
  // ==========================================

  Widget _buildHeader() {
    final percent = (_progress * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentStep + 1} of 3',
            style: const TextStyle(
              color: AppColors.sage,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              Expanded(
                child: Text(
                  _titles[_currentStep],
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
                  const Text(
                    'completed',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.sage,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            _descriptions[_currentStep],
            style: const TextStyle(
              color: AppColors.sage,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 9,
              backgroundColor: AppColors.softGreen,
              color: AppColors.forest,
            ),
          ),

          const SizedBox(height: 18),

          _buildStepIndicator(),
        ],
      ),
    );
  }

  // ==========================================
  // STEP INDICATOR
  // ==========================================

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final active = index == _currentStep;
        final finished = index < _currentStep;

        return Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 200,
                ),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.forest
                      : finished
                      ? AppColors.softGreen
                      : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? AppColors.forest
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: finished
                      ? const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.forest,
                  )
                      : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? Colors.white
                          : AppColors.charcoal,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 7),

              Text(
                _titles[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: active
                      ? AppColors.forest
                      : AppColors.charcoal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ==========================================
  // CURRENT STEP CONTENT
  // ==========================================

  List<Widget> _buildCurrentStep() {
    final section = _sectionData(_currentSection);

    if (section == null) {
      return [
        _buildCard(
          child: const Text(
            'No questions in this section.',
          ),
        ),
      ];
    }

    if (_currentSection == 'assessment') {
      return [
        _buildCard(
          child: _buildQuestions(
            _currentSection,
            0,
            _asList(section['answer']),
          ),
        ),
      ];
    }

    final flights = _asList(section['answer']);

    final widgets = <Widget>[];

    if (flights.isEmpty) {
      widgets.add(
        _buildCard(
          child: const Text(
            'No flights in this section.',
          ),
        ),
      );
    }

    for (final item in flights) {
      final flight =
      Map<String, dynamic>.from(item as Map);

      final flightNumber =
          (flight['flightNum'] as num?)?.toInt() ?? 1;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCard(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flight_takeoff_rounded,
                      color: AppColors.forest,
                      size: 20,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      'Flight $flightNumber',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildQuestions(
                  _currentSection,
                  flightNumber,
                  _asList(flight['data']),
                ),
              ],
            ),
          ),
        ),
      );
    }

    widgets.add(
      _buildCard(
        child: SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Add new flight',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: const Text(
            'Create another flight record when saving.',
          ),
          activeThumbColor: AppColors.forest,
          activeTrackColor: AppColors.softGreen,
          value: _currentSection == 'pre'
              ? _addPreFlight
              : _addPostFlight,
          onChanged: (value) {
            setState(() {
              if (_currentSection == 'pre') {
                _addPreFlight = value;
              } else {
                _addPostFlight = value;
              }
            });
          },
        ),
      ),
    );

    return widgets;
  }

  // ==========================================
  // DYNAMIC QUESTIONS
  // ==========================================

  Widget _buildQuestions(
      String section,
      int flightNumber,
      List<dynamic> questions,
      ) {
    if (questions.isEmpty) {
      return const Text(
        'No questions available.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < questions.length; i++) ...[
          if (i > 0)
            const SizedBox(height: 23),

          _buildQuestion(
            section,
            flightNumber,
            i,
            Map<String, dynamic>.from(
              questions[i] as Map,
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // QUESTION FIELD
  // ==========================================

  Widget _buildQuestion(
      String section,
      int flightNumber,
      int index,
      Map<String, dynamic> question,
      ) {
    final key = _key(
      section,
      flightNumber,
      index,
    );

    final controller = _controllers[key]!;

    final type =
        question['qType']?.toString() ?? '';

    final options = _asList(question['option'])
        .map((e) => e.toString())
        .toList();

    final required = _requiredKeys.contains(key);

    final invalid =
        _showErrors && !_questionValid(key, question);

    Widget input;

    switch (type) {
    // TEXT & LONGTEXT
      case 'text':
      case 'longtext':
        input = TextFormField(
          controller: controller,
          maxLines: type == 'longtext' ? 4 : 1,
          minLines: type == 'longtext' ? 3 : 1,
          onChanged: (_) {
            if (_showErrors) {
              setState(() {});
            }
          },
          decoration: InputDecoration(
            hintText: type == 'longtext'
                ? 'Write your notes...'
                : 'Answer',
            errorText: invalid
                ? 'This field is required'
                : null,
          ),
        );
        break;

    // DROPDOWN
      case 'dropdown':
        final selection =
        options.contains(controller.text) &&
            controller.text.isNotEmpty
            ? controller.text
            : null;

        input = DropdownButtonFormField<String>(
          key: ValueKey(
            'dropdown:$key:$selection',
          ),
          initialValue: selection,
          isExpanded: true,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              controller.text = value ?? '';
            });
          },
          decoration: InputDecoration(
            hintText: 'Select one',
            errorText: invalid
                ? 'Please select an option'
                : null,
          ),
        );
        break;

    // SINGLE CHOICE (RADIO)
      case 'multiple':
        input = Column(
          children: options.map((option) {
            return _buildOptionTile(
              label: option,
              selected: controller.text == option,
              checkbox: false,
              onTap: () {
                setState(() {
                  controller.text = option;
                });
              },
            );
          }).toList(),
        );
        break;

    // CHECKLIST
      case 'checklist':
        input = Column(
          children: options.map((option) {
            return _buildOptionTile(
              label: option,
              selected:
              _checkedOptions[key]?.contains(option) ??
                  false,
              checkbox: true,
              onTap: () {
                setState(() {
                  final values =
                  _checkedOptions.putIfAbsent(
                    key,
                        () => <String>{},
                  );

                  if (!values.add(option)) {
                    values.remove(option);
                  }
                });
              },
            );
          }).toList(),
        );
        break;

      default:
        input = const Text(
          'Unsupported question type.',
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['questionName']?.toString() ??
              'Question',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),

        if (required) ...[
          const SizedBox(height: 4),
          const Text(
            'Required',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.sage,
            ),
          ),
        ],

        const SizedBox(height: 10),

        input,

        if (invalid &&
            (type == 'multiple' ||
                type == 'checklist'))
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Text(
              'Please select at least one option',
              style: TextStyle(
                color: Color(0xFFC94444),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // CUSTOM OPTION TILE
  // ==========================================

  Widget _buildOptionTile({
    required String label,
    required bool selected,
    required bool checkbox,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.softGreen
            : AppColors.background,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? AppColors.sage
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  checkbox
                      ? selected
                      ? Icons.check_box_rounded
                      : Icons
                      .check_box_outline_blank_rounded
                      : selected
                      ? Icons
                      .radio_button_checked_rounded
                      : Icons
                      .radio_button_off_rounded,
                  color: selected
                      ? AppColors.forest
                      : AppColors.charcoal,
                  size: 22,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CARD STYLE
  // ==========================================

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION
  // ==========================================

  Widget _buildFooter() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _back,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  backgroundColor: AppColors.softGreen,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text('Back'),
              ),
            ),

            const SizedBox(width: 12),
          ],

          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: FilledButton.icon(
              onPressed: _saving ? null : _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(
                _currentStep == 2
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                _saving ? 'Saving...' : _currentStep == 2 ? 'Finish & Save' : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }
}