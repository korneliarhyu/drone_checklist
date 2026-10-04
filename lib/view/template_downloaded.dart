import 'package:drone_checklist/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'form_create.dart';

// THEME
import 'package:drone_checklist/theme/app_theme.dart';

class TemplateDownloaded extends StatefulWidget {
  const TemplateDownloaded({super.key});

  @override
  _TemplateDownloadedState createState() => _TemplateDownloadedState();
}

class _TemplateDownloadedState extends State<TemplateDownloaded> {

  late Future<List<Map<String, dynamic>>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = _getAllTemplates();
  }

  Future<List<Map<String, dynamic>>> _getAllTemplates() async {
    return await DatabaseHelper.getAllTemplates();
  }

  Future<void> _deleteTemplate(int templateId) async {
    await DatabaseHelper.deleteTemplate(templateId);

    //refresh list
    setState(() {
      _templatesFuture = _getAllTemplates();
    });
  }

  Widget _buildTemplateCard(
      BuildContext context,
      Map<String, dynamic> chosenTemp,
      ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormCreate(
                templateId: chosenTemp['templateId'],
              ),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.forest,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  chosenTemp['templateName'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.charcoal,
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteTemplate(
                      chosenTemp['templateId'],
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,

        title: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Choose Template',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ),

        // ATUR POSISI ARROW BACK
        leading: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
        ),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            );
          }

          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const _EmptyTemplateState();
          }

          final templates = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Select a template to create your checklist.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.charcoal.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 20),

              ...List.generate(
                templates.length,
                    (index) {
                  final chosenTemp = templates[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildTemplateCard(context, chosenTemp,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// EMPTY STATE
class _EmptyTemplateState extends StatelessWidget {
  const _EmptyTemplateState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.softGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.forest,
                size: 36,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No templates available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add or download a template first before creating a checklist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.charcoal.withValues(
                  alpha: 0.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}