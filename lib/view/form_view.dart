import 'package:drone_checklist/database/database_helper.dart';
import 'package:drone_checklist/view/form_fill.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:drone_checklist/view/template_view.dart';
import 'package:drone_checklist/view/template_downloaded.dart';
import 'package:drone_checklist/services/api_service.dart';

// THEME RELATED FILES
import 'package:drone_checklist/theme/app_theme.dart';

// LOCAL TEMPLATE
import 'package:drone_checklist/view/sample_template_view.dart';

class FormView extends StatefulWidget {
  const FormView({super.key});

  @override
  _FormViewState createState() => _FormViewState();
}

class _FormViewState extends State<FormView> {
  List<Map<String, dynamic>> _formList = [];

  // bool selectedForm = false;
  int? selectedFormIndex;
  int selectedFilter = 0;
  String searchQuery = '';

  void _callData() async {
    var listData = await DatabaseHelper.getAllForms();
    _formList = listData.map((element) {
      return {
        'formId': element['formId'],
        'formName': element['formName'],
        'isChecked': false,
        'syncStatus': element['syncStatus'],
      };
    }).toList();
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    _callData();
    super.initState();
  }

  // DELETE FORM NEW
  Future<void> _deleteForm(int formId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Checklist?'),
          content: const Text(
            'This checklist will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await DatabaseHelper.deleteForm(formId);

    setState(() {
      _formList.removeWhere(
            (form) => form['formId'] == formId,
      );

      if (selectedFormIndex == formId) {
        selectedFormIndex = null;
      }
    });
  }



  // CREATE FILTERS
  List<dynamic> get filteredForms {
    return _formList.where((form) {
      final formName =
      form['formName'].toString().toLowerCase();

      final matchesSearch =
      formName.contains(searchQuery.toLowerCase());

      final syncStatus = form['syncStatus'];

      final matchesFilter = switch(selectedFilter) {
        1 => syncStatus == 1,
        2 => syncStatus != 1,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _navigateToCreateForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TemplateDownloaded(),
      ),
    );
    _callData();
  }

  // USE THIS ONE INSTEAD TO NAVIGATE TO SAMPLE TEMPLATE LIST
  void _navigateToTemplatesList() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SampleTemplateView(),
      ),
    );
  }

  // ERROR DUE TO API EXPIRED
  void _sync() async {
    int? selectedForm = selectedFormIndex;

    //debug ambil id yang dipilih
    print("Syncing ID(s): $selectedForm");

    // Check apakah ada form yang dipilih
    if (selectedForm == null) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("No Form Selected"),
              content: const Text("Please select at least one form to sync."),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          });
      return;
    } else {
      bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Sync"),
              content:
                  const Text("Are you sure you want to sync selected form?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Yes"),
                ),
              ],
            );
          });

      if (confirm) {
        try {
          var getForm = await DatabaseHelper.getFormById(selectedForm);
          if (getForm == null) {
            print("Valid form data not found or missing templateId for: $selectedForm");
            return;
          }

          var dio = Dio();

          dio.interceptors.add(LogInterceptor(
            requestHeader: true,
            requestBody: true,
            responseBody: true,
            responseHeader: true,
          ));

          var apiService = ApiService(dio);

          FormData sync = FormData.fromMap({
            "submissionName": getForm['formName'].toString(),
            "templateId": getForm['serverTemplateId'].toString(),
            "submittedBy": "User",
            "submittedDate":DateTime.now().toString(),
            "formData": getForm['formData'].toString(),
          });

          final response = await dio.post(
            "http://103.102.152.249/webdrone/class/database/syncData.php",
            data: sync
          );

          print("response result : $response");

          //update syncStatus in DB
          await DatabaseHelper.updateSyncStatus(selectedForm, 1);

          //update UI
          setState(() {
            _formList.firstWhere((form) => form['formId'] == selectedForm)['syncStatus'] =1;
            selectedFormIndex = null;
          });

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Sync Successful'),
                content: Text('Sync response: ${response.toString()}'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );

        } catch (e) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Sync Failed'),
                content: Text('Error: $e'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        // Jika user memilih "No"
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sync Cancelled'),
              content: const Text('Sync process was cancelled.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // STYLING
  @override
  Widget build(BuildContext context) {
    final forms = filteredForms;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 28),

                          _buildSearchBar(),
                          const SizedBox(height: 16),

                          _buildFilters(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  if (_formList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Transform.translate(
                        offset: const Offset(0, -60),
                        child: const _EmptyFormState(),
                      ),
                    )
                  else if (forms.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No matching checklist found.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.sage,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList.separated(
                        itemCount: forms.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildFormCard(forms[index]);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'createForm',
        onPressed: _navigateToCreateForm,
        child: const Icon(
          Icons.add_rounded,
          size: 30,
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        height: 72,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.softGreen,

        onDestinationSelected: (index) {
          if (index == 1) {
            _navigateToTemplatesList();
          }
          if (index == 2) {
            _sync();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: AppColors.forest,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_upload_outlined),
            label: 'Sync',
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(dynamic form) {
    final bool isSynced = form['syncStatus'] == 1;
    final int formId = form['formId'];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormFill(
                formId: formId,
              ),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
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
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          form['formName'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          isSynced
                              ? 'Checklist successfully synced.'
                              : 'Checklist stored locally.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.charcoal.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                    ),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _deleteForm(
                          formId,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete_outline, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text('Delete', style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSynced ? AppColors.sage : Colors.orangeAccent,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    isSynced
                        ? 'Synced'
                        : 'Not synced',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.charcoal.withValues(alpha: 0.6),
                    ),
                  ),

                  const Spacer(),

                  if (!isSynced) ...[
                    Text(
                      'Select to sync',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.charcoal.withValues(alpha: 0.5),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Checkbox(
                      value: selectedFormIndex == formId,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedFormIndex = formId;
                          } else {
                            selectedFormIndex = null;
                          }
                        });
                      },
                    ),
                  ] else
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: AppColors.forest,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Synced',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.forest,
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

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning,',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.charcoal.withValues(
                    alpha: 0.65,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              const Text(
                'Ready to fly?',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search checklists...',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.charcoal.withValues(
            alpha: 0.55,
          ),
        ),
        hintStyle: TextStyle(
          color: AppColors.charcoal.withValues(
            alpha: 0.4,
          ),
        ),
        fillColor: AppColors.surface,
      ),
    );
  }

  // DESIGN FOR THE FILTERS
  Widget _buildFilters() {
    const filters = [
      'All',
      'Synced',
      'Not Synced',
    ];

    return Row(
      children: List.generate(filters.length, (index) {
        final selected = selectedFilter == index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == filters.length - 1 ? 0 : 10,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                setState(() {
                  selectedFilter = index;
                  selectedFilter = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.forest
                      : AppColors.softGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  filters[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : AppColors.charcoal,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyFormState extends StatelessWidget {
  const _EmptyFormState();

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
              'No checklists yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first checklist to start preparing for your next flight.',
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