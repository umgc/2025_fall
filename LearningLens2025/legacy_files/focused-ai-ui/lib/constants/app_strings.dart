class AppStrings {
  // ===== EXISTING LOGIN PROJECT STRINGS =====
  // General UI
  static const String appName = 'FocusEd AI';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String loading = 'Loading...';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String connectionError = 'No internet connection. Check your network settings.';

  // Authentication
  static const String appWelcome = 'Welcome to FocusEd AI!';
  static const String loginTitle = 'Login';
  static const String loginDirections = 'For Moodle, please log in with your Moodle URL, username, and password. For Google Classroom, please sign in with Google below.';
  static const String moodleUrlLabel = 'Moodle URL';
  static const String moodleUrlHint = 'https://[Moodle domain]/moodle';
  static const String usernameLabel = 'Moodle Username';
  static const String usernameHint = 'Moodle User';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Your password';
  static const String signInWithMoodleButton = 'Sign in with Moodle';
  static const String orContinueWith = 'Google Classroom';
  static const String googleButton = 'Continue with Google';
  static const String termsAndPrivacyText = 'By clicking continue, you agree to our Terms of Service and Privacy Policy';
  static const String loginFailed = 'Login failed';
  static const String googleSignInFailed = 'Google Sign-in failed';

  // Validation Errors (used in LoginScreen's TextFormField validators)
  static const String moodleUrlEmptyError = 'Please enter your Moodle URL';
  static const String moodleUrlValidityError = 'Please enter a valid URL starting with http:// or https://';
  static const String usernameEmptyError = 'Email cannot be empty.';
  static const String passwordEmptyError = 'Password cannot be empty.';

  // Home Screen (examples)
  static const String homeWelcomeMessage = 'Welcome, ';
  static const String teacherDashboardTitle = 'Teacher Dashboard';
  static const String studentDashboardTitle = 'Student Dashboard';
  static const String logoutButton = 'Logout';

  // Other App Specific Strings
  static const String appVersion = '1.0.0';
  static const String defaultUserDisplayName = 'Guest User';

  // ===== INTEGRATED CAILA STRINGS =====
  // App Title with CAILA branding
  static const String appTitle = 'FocusEd AI with CAILA';
  static const String cailaSubtitle = 'AI Teaching Assistant';
  
  // CAILA Dashboard
  static const String materialGenerator = 'Material Generator';
  static const String chatHistory = 'Chat History';
  static const String studentLogs = 'Student Logs';
  static const String connectToLMS = 'Connect to LMS';
  static const String selectCourse = 'Select Course';
  static const String generateMaterial = 'Generate Material';
  static const String chatWithCaila = 'Chat with CAILA';
  
  // CAILA Features
  static const String cailaAssistant = 'CAILA - AI Assistant';
  static const String materialGeneration = 'Material Generation';
  static const String assignmentHelp = 'Assignment Help';
  static const String aiTutoring = 'AI Tutoring';
  static const String teacherTools = 'Teacher Tools';
  static const String studentSupport = 'Student Support';
  
  // CAILA Status Messages
  static const String loadingText = 'Loading...';
  static const String errorText = 'An error occurred';
  static const String noDataText = 'No data available';
  static const String cailaConnected = 'CAILA Connected';
  static const String cailaDisconnected = 'CAILA Disconnected';
  static const String conversationLogged = 'Conversation logged for teacher review';
  
  // CAILA Actions
  static const String startChatting = 'Start chatting with CAILA!';
  static const String askQuestion = 'Ask CAILA for help...';
  static const String generateContent = 'Generate educational content';
  static const String viewHistory = 'View conversation history';
  static const String exportMaterial = 'Export to LMS';
  
  // CAILA Material Types
  static const String assignment = 'Assignment';
  static const String quiz = 'Quiz';
  static const String lessonPlan = 'Lesson Plan';
  static const String rubric = 'Rubric';
  static const String worksheet = 'Worksheet';
  static const String projectInstructions = 'Project Instructions';
  static const String studyGuide = 'Study Guide';
  static const String essay = 'Essay';
  
  // Available material types list
  static const List<String> materialTypes = [
    quiz,
    assignment, 
    rubric,
    essay,
  ];
  
  // CAILA Error Messages
  static const String cailaError = 'CAILA encountered an error';
  static const String authenticationRequired = 'Authentication required to use CAILA';
  static const String materialGenerationFailed = 'Failed to generate material';
  static const String exportFailed = 'Failed to export to LMS';
  static const String chatFailed = 'Failed to send message to CAILA';
  
  // CAILA Success Messages
  static const String materialGenerated = 'Material generated successfully!';
  static const String materialExported = 'Material exported to LMS successfully!';
  static const String conversationSaved = 'Conversation saved';
  static const String workSaved = 'Work saved successfully';
  static const String assignmentSubmitted = 'Assignment submitted successfully!';
  
  // CAILA Navigation
  static const String backToHome = 'Back to Home';
  static const String selectAssignment = 'Select Assignment';
  static const String viewSubmissions = 'View Submissions';
  static const String manageMaterials = 'Manage Materials';
  
  // CAILA Platform Integration
  static const String googleClassroomIntegration = 'Google Classroom Integration';
  static const String moodleIntegration = 'Moodle Integration';
  static const String platformConnected = 'Platform Connected';
  static const String readyToUseCAILA = 'Ready to use CAILA features';
  
  // CAILA Help and Info
  static const String cailaHelp = 'CAILA Help';
  static const String aboutCaila = 'About CAILA';
  static const String cailaDescription = 'CAILA is your AI teaching assistant that helps create educational content and provides student support.';
  static const String getFeedback = 'Get AI Feedback';
  static const String askForHelp = 'Ask for Help';

  // ===== NEW MATERIAL GENERATION STRINGS =====
  // Configuration Bar
  static const String materialGeneratorTitle = 'Material Generator';
  static const String materialGeneratorSubtitle = 'Create educational materials with CAILA AI';
  static const String selectCourseLabel = 'Select Course';
  static const String materialTypeLabel = 'Material Type';
  static const String materialTitleLabel = 'Material Title (Optional)';
  static const String refreshCourses = 'Refresh Courses';
  static const String startFresh = 'Start Fresh';
  static const String startFreshConfirmTitle = 'Start Fresh?';
  static const String startFreshConfirmMessage = 'This will clear your current assignment and start over. Are you sure?';
  static const String saveDraft = 'Save Draft';
  static const String export = 'Export';
  
  // Chat Interface
  static const String chatWithCailaTitle = 'Chat with CAILA';
  static const String noChatHistory = 'Start chatting with CAILA!';
  static const String noChatHistorySubtitle = 'Ask me to revise any part of your assignment';
  static const String noChatHistorySubtitleCreate = 'Ask me to create a assignment or ask questions about it';
  static const String noChatHistorySubtitleGeneral = 'Select a material type and ask me to create educational content';
  
  // Chat Hints
  static const String chatHintRevision = 'Ask me to revise any part of your assignment...';
  static const String chatHintCreate = 'Ask me to create a assignment...';
  static const String chatHintGeneral = 'Ask CAILA to help create educational materials...';
  
  // Status Messages
  static const String loadingCourses = 'Loading courses...';
  static const String loadingCoursesError = 'Failed to load courses';
  static const String noCoursesFound = 'No courses found';
  static const String retryButton = 'Retry';
  static const String loadButton = 'Load';
  
  // Context Status
  static const String workingOnPrefix = 'Working on:';
  static const String workingOnSuffix = '- revisions will be applied to current version';
  static const String readyToCreatePrefix = 'Ready to create';
  static const String readyToCreateSuffix = 'for';
  static const String editingPrefix = 'Editing:';
  static const String creatingPrefix = 'Creating:';
  
  // Material Status
  static const String materialGeneratedSuccessfully = 'generated successfully!';
  static const String revisionCompleted = 'Revision completed successfully!';
  static const String showPreview = 'Show Preview';
  static const String hidePreview = 'Hide Preview';
  static const String viewPreview = 'View Preview';
  
  // Progress Messages
  static const String creatingMaterial = 'Creating your material...';
  static const String revisingMaterial = 'Revising your assignment...';
  static const String progressSubtitle = 'This may take 1-3 minutes depending on complexity. Please wait while I craft something great for you! ⏳';
  static const String revisionSubtitle = 'I\'m working on your specific revision request while keeping the rest of the assignment intact! ✏️';
  
  // Working Messages
  static const String cailaWorking = 'CAILA is working...';
  static const String processingRevision = 'Processing your revision request...';
  static const String creatingMaterialProgress = 'Creating material (this may take 1-3 minutes)';
  static const String thinkingAndPreparing = 'Thinking and preparing response...';
  
  // Action Messages
  static const String revisionTip = 'Tip: I\'ll revise just this section while keeping the rest of your assignment unchanged!';
  static const String readyToCreateNew = 'Ready to create a new assignment!';
  
  // Connection Status
  static const String googleConnected = 'GOOGLE Connected';
  static const String moodleConnected = 'MOODLE Connected';
  
  // Export Messages
  static const String exportingTo = 'Exporting to';
  static const String exportSuccessful = 'Successfully exported to';
  static const String exportFailedMessage = 'Export failed:';
  static const String draftSaved = 'Draft saved successfully!';
  
  // Time Formatting
  static const String justNow = 'Just now';
  static const String minutesAgo = 'm ago';
  static const String hoursAgo = 'h ago';
  static const String daysAgo = 'd ago';
  
  // General Navigation
  static const String generalChat = 'General Chat';
  static const String generalChatSubtitle = 'General conversation with CAILA';
  static const String historySubtitle = 'Your conversation history will appear here';
}