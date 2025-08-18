// lib/widgets/material_configuration_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_strings.dart';
import '../models/course.dart';
import '../services/auth_service.dart';

class MaterialConfigurationBar extends StatelessWidget {
  final List<Course> courses;
  final bool isLoadingCourses;
  final String? errorMessage;
  final String? selectedCourseId;
  final String? selectedMaterialType;
  final TextEditingController titleController;
  final String? generatedMaterial;
  final bool showAssignmentPreview;
  final String? currentAssignmentContext;
  final VoidCallback onLoadCourses;
  final Function(String?) onCourseSelected;
  final Function(String?) onMaterialTypeSelected;
  final VoidCallback? onStartFresh;
  final VoidCallback? onExportMaterial;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onTogglePreview;
  final bool isLoading;

  const MaterialConfigurationBar({
    super.key,
    required this.courses,
    required this.isLoadingCourses,
    this.errorMessage,
    required this.selectedCourseId,
    required this.selectedMaterialType,
    required this.titleController,
    this.generatedMaterial,
    required this.showAssignmentPreview,
    this.currentAssignmentContext,
    required this.onLoadCourses,
    required this.onCourseSelected,
    required this.onMaterialTypeSelected,
    this.onStartFresh,
    this.onExportMaterial,
    this.onSaveDraft,
    this.onTogglePreview,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          _buildHeaderRow(context),
          
          const SizedBox(height: 20),
          
          // Configuration Row
          _buildConfigurationRow(),
          
          // Status Row
          if (_shouldShowStatusRow())
            Column(
              children: [
                const SizedBox(height: 16),
                _buildStatusRow(context),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome, color: Colors.purple[700], size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.materialGeneratorTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            Text(
              AppStrings.materialGeneratorSubtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Action Buttons
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
  return Row(
    children: [
      // Start Fresh button - show when there's any activity to reset
      if (_hasActivityToReset())
        OutlinedButton.icon(
          onPressed: isLoading ? null : onStartFresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text(AppStrings.startFresh),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange[700],
            side: BorderSide(color: Colors.orange[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      
      // Add spacing if start fresh is showing
      if (_hasActivityToReset()) const SizedBox(width: 8),
      
      // Refresh courses button
      IconButton(
        onPressed: isLoadingCourses ? null : onLoadCourses,
        icon: isLoadingCourses 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        tooltip: AppStrings.refreshCourses,
        style: IconButton.styleFrom(
          backgroundColor: Colors.grey[100],
        ),
      ),
      
      const SizedBox(width: 8),
      
      // Export button - only show when there's material to export
      if (generatedMaterial != null && showAssignmentPreview && onExportMaterial != null)
        ElevatedButton.icon(
          onPressed: isLoading ? null : onExportMaterial,
          icon: isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.upload, size: 18),
          label: Text(isLoading ? 'Exporting...' : AppStrings.export),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 2,
          ),
        ),
      
      // Add spacing if export is showing
      if (generatedMaterial != null && showAssignmentPreview) const SizedBox(width: 8),
      
      // Save Draft button - only show when there's material to save
      if (generatedMaterial != null && showAssignmentPreview && onSaveDraft != null)
        OutlinedButton.icon(
          onPressed: onSaveDraft,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text(AppStrings.saveDraft),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green[700],
            side: BorderSide(color: Colors.green[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
    ],
  );
}

bool _hasActivityToReset() {
  return currentAssignmentContext != null ||
         generatedMaterial != null ||
         selectedCourseId != null ||
         selectedMaterialType != null ||
         titleController.text.isNotEmpty;
}



  Widget _buildConfigurationRow() {
    return Row(
      children: [
        // Course Selection
        Expanded(
          flex: 3,
          child: _buildCourseSelectionField(),
        ),
        
        const SizedBox(width: 16),
        
        // Material Type Selection
        Expanded(
          flex: 2,
          child: _buildMaterialTypeField(),
        ),
        
        const SizedBox(width: 16),
        
        // Title Input
        Expanded(
          flex: 3,
          child: _buildTitleField(),
        ),
      ],
    );
  }

  Widget _buildCourseSelectionField() {
    if (isLoadingCourses) {
      return Container(
        height: 56,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(AppStrings.loadingCourses),
          ],
        ),
      );
    } else if (courses.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: selectedCourseId,
        decoration: const InputDecoration(
          labelText: AppStrings.selectCourseLabel,
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.school),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: courses.map((course) {
          return DropdownMenuItem<String>(
            value: course.id,
            child: Text(
              course.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onCourseSelected,
      );
    } else if (errorMessage != null) {
      return Container(
        height: 56,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text(AppStrings.loadingCoursesError, style: TextStyle(fontSize: 14))),
            TextButton(
              onPressed: onLoadCourses,
              child: const Text(AppStrings.retryButton, style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 56,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text(AppStrings.noCoursesFound, style: TextStyle(fontSize: 14))),
            TextButton(
              onPressed: onLoadCourses,
              child: const Text(AppStrings.loadButton, style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMaterialTypeField() {
    return DropdownButtonFormField<String>(
      value: selectedMaterialType,
      decoration: const InputDecoration(
        labelText: AppStrings.materialTypeLabel,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: AppStrings.materialTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: onMaterialTypeSelected,
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: titleController,
      decoration: const InputDecoration(
        labelText: AppStrings.materialTitleLabel,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  bool _shouldShowStatusRow() {
    return selectedMaterialType != null || 
           errorMessage != null || 
           generatedMaterial != null || 
           currentAssignmentContext != null;
  }

  Widget _buildStatusRow(BuildContext context) {
    return Row(
      children: [
        // Context awareness status
        if (currentAssignmentContext != null) ...[
          _buildStatusChip(
            icon: Icons.assignment,
            text: '${AppStrings.workingOnPrefix} ${selectedMaterialType?.toLowerCase() ?? 'assignment'} ${AppStrings.workingOnSuffix}',
            color: Colors.green,
          ),
          const SizedBox(width: 12),
        ],
        
        // Configuration status
        if (selectedMaterialType != null && currentAssignmentContext == null) ...[
          _buildStatusChip(
            icon: Icons.info,
            text: '${AppStrings.readyToCreatePrefix} ${selectedMaterialType!.toLowerCase()}${_buildCourseContextText()}',
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
        ],
        
        // Error status
        if (errorMessage != null) ...[
          _buildStatusChip(
            icon: Icons.error,
            text: AppStrings.loadingCoursesError,
            color: Colors.red,
          ),
          const SizedBox(width: 12),
        ],
        
        // Generated material status
        if (generatedMaterial != null && currentAssignmentContext == null) ...[
          _buildStatusChip(
            icon: Icons.check_circle,
            text: '✅ ${selectedMaterialType?.toLowerCase() ?? 'Material'} ${AppStrings.materialGeneratedSuccessfully}',
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          // Preview Toggle Button
          if (onTogglePreview != null)
            TextButton.icon(
              onPressed: onTogglePreview,
              icon: Icon(
                showAssignmentPreview ? Icons.visibility_off : Icons.visibility,
                size: 16,
              ),
              label: Text(
                showAssignmentPreview ? AppStrings.hidePreview : AppStrings.showPreview,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
        
        const Spacer(),
        
        // Connection Status
        _buildConnectionStatus(context),
      ],
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color is MaterialColor ? color.shade700 : color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color is MaterialColor ? color[800] : color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser!;
        final platform = user.lmsType.toString().split('.').last.toUpperCase();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                user.lmsType.toString().contains('google') ? Icons.class_ : Icons.account_balance,
                size: 14,
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              Text(
                '$platform ${AppStrings.platformConnected}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildCourseContextText() {
    if (selectedCourseId != null && courses.isNotEmpty) {
      try {
        final course = courses.firstWhere((c) => c.id == selectedCourseId);
        return ' ${AppStrings.readyToCreateSuffix} ${course.name}';
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  void _showStartFreshDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.refresh, color: Colors.orange),
          SizedBox(width: 8),
          Text(AppStrings.startFreshConfirmTitle),
        ],
      ),
      content: const Text(
        '${AppStrings.startFreshConfirmMessage}\n\n'
        'This will clear:\n'
        '• Generated materials and previews\n'
        '• Chat conversation history\n'
        '• Selected course and material type\n'
        '• Title and form fields',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onStartFresh != null) {
              onStartFresh!();
              // Remove the extra snackbar since the parent will handle it
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text(AppStrings.startFresh),
        ),
      ],
    ),
  );
}
}