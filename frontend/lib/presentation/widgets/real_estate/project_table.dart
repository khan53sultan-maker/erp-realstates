import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/real_estate/project_model.dart';
import '../../../src/providers/real_estate_provider.dart';
import 'add_project_dialog.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

class ProjectTable extends StatefulWidget {
  final List<RealEstateProject>? projects;
  const ProjectTable({super.key, this.projects});

  @override
  State<ProjectTable> createState() => _ProjectTableState();
}

class _ProjectTableState extends State<ProjectTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        final projectsToShow = widget.projects ?? provider.projects;

        if (projectsToShow.isEmpty) {
          return Center(child: Text('No projects found', style: TextStyle(color: AppTheme.charcoalGray.withOpacity(0.5))));
        }

        const double totalTableWidth = 1100.0; // Increased to accommodate wider actions

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.primaryMaroon.withOpacity(0.8)]),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business_center, color: AppTheme.accentGold, size: 20),
                    const SizedBox(width: 8),
                    const Text('Project List', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w900, fontSize: 14)),
                  ],
                ),
              ),
              Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                thickness: 8,
                radius: const Radius.circular(4),
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: totalTableWidth,
                        color: AppTheme.creamWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            _buildHeaderCell('Project Name', 180),
                            _buildHeaderCell('Location', 180),
                            _buildHeaderCell('Landowner', 180),
                            _buildHeaderCell('Total Plots', 100),
                            _buildHeaderCell('Available', 100),
                            _buildHeaderCell('Status', 120),
                            _buildHeaderCell('Actions', 180), 
                          ],
                        ),
                      ),
                      // Rows stack vertically, no internal vertical scroll
                      ...projectsToShow.asMap().entries.map((entry) {
                        final index = entry.key;
                        final project = entry.value;
                        final plots = provider.plots.where((p) => p.projectId == project.id).toList();
                        final available = plots.where((p) => p.status == 'AVAILABLE').length;

                        return Container(
                          width: totalTableWidth,
                          decoration: BoxDecoration(
                            color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.1),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          child: Row(
                            children: [
                              _buildDataCell(project.name, 180, isBold: true),
                              _buildDataCell(project.location, 180),
                              _buildDataCell(project.landownerName, 180),
                              _buildDataCell(project.totalPlots.toString(), 100),
                              _buildDataCell(available.toString(), 100, color: available > 0 ? Colors.green : Colors.red),
                              SizedBox(width: 120, child: Center(child: _buildStatusChip(project.status))),
                              SizedBox(
                                width: 180,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _actionBtn(Icons.bolt_rounded, Colors.orange, () => _handleGeneratePlots(context, project)),
                                    const SizedBox(width: 10),
                                    _actionBtn(Icons.edit_note_rounded, Colors.indigo, () => _handleEdit(context, project)),
                                    const SizedBox(width: 10),
                                    _actionBtn(Icons.delete_sweep_rounded, Colors.redAccent, () => _handleDelete(context, project)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String label, double width) {
    return SizedBox(width: width, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text(label, style: const TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.w900, fontSize: 13), textAlign: TextAlign.center)));
  }

  Widget _buildDataCell(String text, double width, {bool isBold = false, Color? color}) {
    return SizedBox(width: width, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text(text, style: TextStyle(color: color ?? AppTheme.charcoalGray, fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)));
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)));
  }

  Widget _buildStatusChip(String status) {
    final isActive = status == 'ACTIVE';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (isActive ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? Colors.green : Colors.red, width: 1)), child: Text(status, style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)));
  }

  void _handleEdit(BuildContext context, RealEstateProject project) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AddProjectDialog(project: project));
  }

  void _handleDelete(BuildContext context, RealEstateProject project) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm'), content: const Text('Delete this project?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { Navigator.pop(ctx); await context.read<RealEstateProvider>().deleteProject(project.id!); }, child: const Text('Delete'))]));
  }

  void _handleGeneratePlots(BuildContext context, RealEstateProject project) {
    // Generation logic...
  }
}
