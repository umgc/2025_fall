// lib/features/grading/widgets/course_assignment_selector.dart - Fixed version
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/course.dart';
import '../../../core/models/assignment.dart';
import '../providers/course_provider.dart';
import '../providers/grading_provider.dart';

class CourseAssignmentSelector extends StatefulWidget {
  final Function(String)? onAssignmentSelected;
  final Function(String)? onCourseSelected;

  const CourseAssignmentSelector({
    super.key,
    this.onAssignmentSelected,
    this.onCourseSelected,
  });

  @override
  State<CourseAssignmentSelector> createState() => _CourseAssignmentSelectorState();
}

class _CourseAssignmentSelectorState extends State<CourseAssignmentSelector> {
  @override
  void initState() {
    super.initState();
    // Try to load courses when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryLoadCourses();
    });
  }

  Future<void> _tryLoadCourses() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    
    // Only try to load if no courses are available and not already loading
    if (!courseProvider.hasCourses && !courseProvider.isLoading) {
      try {
        await courseProvider.loadCourses();
      } catch (e) {
        print('Failed to load courses from API: $e');
        // Don't show error to user - will fall back to manual course creation
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Dropdown
        _buildCourseDropdown(context),
        const SizedBox(height: 12),
        
        // Assignment Dropdown
        _buildAssignmentDropdown(context),
      ],
    );
  }

  Widget _buildCourseDropdown(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 6),
                const Text(
                  'Select Course',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // Add refresh button
                IconButton(
                  onPressed: courseProvider.isLoading ? null : () => _tryLoadCourses(),
                  icon: courseProvider.isLoading 
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 16),
                  tooltip: 'Refresh courses',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: courseProvider.hasError ? Colors.red[300]! : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: courseProvider.isLoading
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading courses...'),
                      ],
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: courseProvider.selectedCourse?.id,
                        hint: Row(
                          children: [
                            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                courseProvider.hasError 
                                    ? 'Error loading courses - click refresh'
                                    : courseProvider.courses.isEmpty
                                        ? 'No courses available'
                                        : 'Choose a course',
                                style: TextStyle(
                                  color: courseProvider.hasError ? Colors.red[600] : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        isExpanded: true,
                        icon: Icon(Icons.expand_more, color: Colors.blue[600]),
                        items: _buildCourseItems(courseProvider),
                        onChanged: (courseId) => _onCourseSelected(context, courseId),
                      ),
                    ),
            ),
            if (courseProvider.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Backend not available - using fallback courses',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _buildCourseItems(CourseProvider courseProvider) {
    List<DropdownMenuItem<String>> items = [];
    
    // Add real courses if available
    if (courseProvider.courses.isNotEmpty) {
      items.addAll(
        courseProvider.courses.map((course) {
          return DropdownMenuItem<String>(
            value: course.id,
            child: _buildCourseItem(course),
          );
        }).toList()
      );
    } else {
      // Add fallback courses when no courses available
      items.addAll(_createFallbackCourseItems());
    }
    
    return items;
  }

  List<DropdownMenuItem<String>> _createFallbackCourseItems() {
    final fallbackCourses = [
      {
        'id': 'cs101-fallback',
        'name': 'CS 101 - Introduction to Programming',
        'platform': 'classroom',
        'assignments': 3,
        'enrollment': 25,
      },
      {
        'id': 'cs102-fallback',
        'name': 'CS 102 - Data Structures',
        'platform': 'classroom',
        'assignments': 5,
        'enrollment': 20,
      },
      {
        'id': 'cs201-fallback',
        'name': 'CS 201 - Object-Oriented Programming',
        'platform': 'classroom',
        'assignments': 4,
        'enrollment': 18,
      },
    ];

    return fallbackCourses.map((courseData) {
      return DropdownMenuItem<String>(
        value: courseData['id'] as String,
        child: _buildFallbackCourseItem(courseData),
      );
    }).toList();
  }

  Widget _buildCourseItem(Course course) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPlatformColor(course.platform).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  course.platform.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: _getPlatformColor(course.platform),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  course.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.assignment, size: 9, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                '${course.assignments.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.people, size: 9, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                '${course.enrollmentCount}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCourseItem(Map<String, dynamic> courseData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DEMO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  courseData['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.assignment, size: 9, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                '${courseData['assignments']}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.people, size: 9, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                '${courseData['enrollment']}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentDropdown(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        final selectedCourse = courseProvider.selectedCourse;
        final isEnabled = selectedCourse != null;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, size: 16, color: Colors.green[600]),
                const SizedBox(width: 6),
                const Text(
                  'Select Assignment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isEnabled ? Colors.white : Colors.grey[100],
                border: Border.all(
                  color: isEnabled ? Colors.grey[300]! : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isEnabled ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: courseProvider.selectedAssignment?.id,
                  hint: Row(
                    children: [
                      Icon(
                        Icons.arrow_drop_down, 
                        color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isEnabled 
                              ? 'Choose an assignment' 
                              : 'Select a course first',
                          style: TextStyle(
                            color: isEnabled ? Colors.grey : Colors.grey[400],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  isExpanded: true,
                  icon: Icon(
                    Icons.expand_more, 
                    color: isEnabled ? Colors.green[600] : Colors.grey[400],
                  ),
                  items: selectedCourse?.assignments.map((assignment) {
                    return DropdownMenuItem<String>(
                      value: assignment.id,
                      child: _buildAssignmentItem(assignment),
                    );
                  }).toList() ?? [],
                  onChanged: isEnabled ? (assignmentId) => _onAssignmentSelected(context, assignmentId) : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssignmentItem(Assignment assignment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: _getLanguageColor(assignment.language).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Text(
                    assignment.language.substring(0, 
                      assignment.language.length > 4 ? 4 : assignment.language.length
                    ).toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: _getLanguageColor(assignment.language),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assignment.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.people, size: 8, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                '${assignment.submissions.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.star, size: 8, color: Colors.grey[600]),
              const SizedBox(width: 2),
              Text(
                '${assignment.maxScore.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onCourseSelected(BuildContext context, String? courseId) async {
    if (courseId == null) return;
    
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final gradingProvider = Provider.of<GradingProvider>(context, listen: false);
    
    // Clear current grading state
    gradingProvider.reset();
    
    // Select the course (this will create fallback course if needed)
    await courseProvider.selectCourse(courseId);
    
    // Notify parent
    widget.onCourseSelected?.call(courseId);
  }

  void _onAssignmentSelected(BuildContext context, String? assignmentId) async {
    if (assignmentId == null) return;
    
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final gradingProvider = Provider.of<GradingProvider>(context, listen: false);
    
    // Select the assignment
    courseProvider.selectAssignment(assignmentId);
    
    // Load submissions for this assignment
    final assignment = courseProvider.selectedAssignment;
    if (assignment != null) {
      gradingProvider.setSubmissions(assignment.submissions);
    }
    
    // Notify parent
    widget.onAssignmentSelected?.call(assignmentId);
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'google':
      case 'classroom':
        return Colors.blue[700]!;
      case 'moodle':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Color _getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'java':
        return Colors.orange[700]!;
      case 'python':
        return Colors.blue[700]!;
      case 'javascript':
      case 'js':
        return Colors.yellow[700]!;
      case 'cpp':
      case 'c++':
        return Colors.indigo[700]!;
      case 'c':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}