// lib/widgets/caila_chat_interface.dart - Enhanced version
import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../services/caila_service.dart';

class CailaChatInterface extends StatelessWidget {
  final TextEditingController chatController;
  final List<Map<String, String>> currentConversation;
  final String? selectedMaterialType;
  final String? currentAssignmentContext;
  final bool isLoading;
  final VoidCallback onSendMessage;

  const CailaChatInterface({
    super.key,
    required this.chatController,
    required this.currentConversation,
    this.selectedMaterialType,
    this.currentAssignmentContext,
    required this.isLoading,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            // Chat Header
            _buildChatHeader(),
            
            // Chat Messages
            Expanded(
              child: _buildChatMessages(context),
            ),
            
            // Chat Input
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.purple[700]),
          const SizedBox(width: 8),
          Text(
            AppStrings.chatWithCailaTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple[700],
            ),
          ),
          const Spacer(),
          // Context status in header
          _buildHeaderStatus(),
        ],
      ),
    );
  }

  Widget _buildHeaderStatus() {
    if (currentAssignmentContext != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${AppStrings.editingPrefix} ${selectedMaterialType ?? 'Assignment'}',
          style: TextStyle(
            fontSize: 10,
            color: Colors.green[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (selectedMaterialType != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${AppStrings.creatingPrefix} ${selectedMaterialType!}',
          style: TextStyle(
            fontSize: 10,
            color: Colors.purple[700],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildChatMessages(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: currentConversation.isEmpty
          ? _buildEnhancedEmptyState()
          : ListView.builder(
              itemCount: currentConversation.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == currentConversation.length && isLoading) {
                  return _buildLoadingMessage();
                }
                return _buildChatMessage(currentConversation[index]);
              },
            ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Icon and Title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: Colors.purple[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getEmptyStateTitle(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _getEmptyStateSubtitle(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Quick Tips Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Tips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._getTipsForCurrentState().map((tip) => _buildTipItem(tip)),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Example prompts based on state
              if (selectedMaterialType != null) _buildExamplePrompts(),
            ],
          ),
        ),
      ),
    );
  }

  String _getEmptyStateTitle() {
    if (currentAssignmentContext != null) {
      return 'Ready to Revise!';
    } else if (selectedMaterialType != null) {
      return 'Let\'s Create Your $selectedMaterialType!';
    } else {
      return 'Ready to Get Started!';
    }
  }

  String _getEmptyStateSubtitle() {
    if (currentAssignmentContext != null) {
      return 'Ask me to revise or improve any part of your ${selectedMaterialType?.toLowerCase() ?? 'material'}';
    } else if (selectedMaterialType != null) {
      return 'Tell me what kind of ${selectedMaterialType!.toLowerCase()} you\'d like to create';
    } else {
      return 'Select a material type above, then start chatting to create amazing educational content!';
    }
  }

  List<String> _getTipsForCurrentState() {
    if (currentAssignmentContext != null) {
      return [
        'Ask for specific changes: "Make question 3 easier"',
        'Request additions: "Add more practice problems"',
        'Modify difficulty: "Make this more challenging"',
        'Update content: "Change the topic to fractions"',
      ];
    } else if (selectedMaterialType != null) {
      switch (selectedMaterialType!.toLowerCase()) {
        case 'quiz':
          return [
            'Specify the topic and grade level',
            'Mention how many questions you want',
            'Include question types (multiple choice, short answer)',
            'Add learning objectives or standards',
          ];
        case 'assignment':
          return [
            'Describe the subject and learning goals',
            'Mention the grade level and duration',
            'Include any specific requirements',
            'Specify assessment criteria needed',
          ];
        case 'essay':
          return [
            'Provide the essay topic or prompt',
            'Specify length and format requirements',
            'Include any source or citation needs',
            'Mention the grade level and subject',
          ];
        default:
          return [
            'Be specific about your topic and grade level',
            'Include learning objectives',
            'Mention any special requirements',
            'Specify duration or length needed',
          ];
      }
    } else {
      return [
        'Select a course and material type first',
        'Be specific about grade level and subject',
        'Include learning objectives when possible',
        'Ask for revisions anytime - I\'m here to help!',
      ];
    }
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.blue[600], size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blue[700], 
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplePrompts() {
    final examples = _getExamplePrompts();
    if (examples.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Try asking:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...examples.map((example) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Text(
                '"$example"',
                style: TextStyle(
                  color: Colors.green[800],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  List<String> _getExamplePrompts() {
    if (selectedMaterialType == null) return [];

    switch (selectedMaterialType!.toLowerCase()) {
      case 'quiz':
        return [
          'Create a 10-question quiz on 5th grade fractions',
          'Make a multiple choice quiz about the solar system for middle school',
        ];
      case 'assignment':
        return [
          'Create a math assignment on algebra for 8th graders',
          'Make a research project about climate change for high school',
        ];
      case 'essay':
        return [
          'Create an essay prompt about democracy for 11th grade',
          'Make a persuasive writing assignment for middle school',
        ];
      case 'worksheet':
        return [
          'Create practice problems for 4th grade multiplication',
          'Make a grammar worksheet for ESL students',
        ];
      default:
        return [
          'Create a ${selectedMaterialType!.toLowerCase()} for [grade level] about [topic]',
        ];
    }
  }

  Widget _buildChatMessage(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final isGeneratedMaterial = !isUser && CailaService.isGeneratedMaterial(message['content'] ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isGeneratedMaterial ? Colors.green : Colors.purple,
              child: Icon(
                isGeneratedMaterial ? Icons.auto_awesome : Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Colors.purple[100] 
                    : isGeneratedMaterial 
                        ? Colors.green[50]
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: isGeneratedMaterial 
                    ? Border.all(color: Colors.green[300]!, width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isGeneratedMaterial)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '✨ GENERATED MATERIAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SelectableText(
                    CailaService.cleanMarkdownForDisplay(message['content'] ?? ''),
                    style: TextStyle(
                      color: isUser ? Colors.purple[700] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CailaService.formatTimestamp(message['timestamp'] ?? ''),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.purple[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.purple,
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.cailaWorking,
                  style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _getLoadingSubtitle(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLoadingSubtitle() {
    if (currentAssignmentContext != null) {
      return AppStrings.processingRevision;
    } else if (selectedMaterialType != null) {
      return AppStrings.creatingMaterialProgress.replaceFirst('material', selectedMaterialType!.toLowerCase());
    } else {
      return AppStrings.thinkingAndPreparing;
    }
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: chatController,
              decoration: InputDecoration(
                hintText: _getChatHint(),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => onSendMessage(),
              enabled: !isLoading,
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isLoading ? null : onSendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _getChatHint() {
    if (currentAssignmentContext != null) {
      return AppStrings.chatHintRevision.replaceFirst('assignment', selectedMaterialType?.toLowerCase() ?? 'assignment');
    } else if (selectedMaterialType != null) {
      return AppStrings.chatHintCreate.replaceFirst('assignment', selectedMaterialType!.toLowerCase());
    } else {
      return AppStrings.chatHintGeneral;
    }
  }
}