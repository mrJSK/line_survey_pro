// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Line Survey Pro';

  @override
  String get welcomeMessage => 'Welcome to Line Survey Pro!';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInPrompt => 'Please sign in to continue using the app.';

  @override
  String get surveyDashboard => 'Survey Dashboard';

  @override
  String get exportRecords => 'Export Records';

  @override
  String get realtimeTasks => 'Real-Time Tasks';

  @override
  String get info => 'Info';

  @override
  String get userManagement => 'User Management';

  @override
  String get manageTransmissionLines => 'Manage Transmission Lines';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get accountPendingApproval => 'Account Pending Approval';

  @override
  String get awaitingApprovalMessage => 'Your account is awaiting approval from an administrator. Once approved, you will gain full access to the app features.';

  @override
  String get accountRejected => 'Account Rejected';

  @override
  String get rejectedMessage => 'Unfortunately, your account has been rejected by an administrator. Please contact support for more information.';

  @override
  String get recheckStatus => 'Re-check Status (Requires Sign Out)';

  @override
  String get noInternetTitle => 'Oops! No Internet Connection';

  @override
  String get noInternetMessage => 'It seems you\'re offline. Please check your network settings and try again.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get yourAssignedTasks => 'Your Assigned Tasks:';

  @override
  String get allTasks => 'All Tasks:';

  @override
  String get assignNewTask => 'Assign New Task';

  @override
  String get uploadUnsyncedDetails => 'Upload Unsynced Details';

  @override
  String get noTasksAssigned => 'No tasks assigned to you yet.';

  @override
  String get noTasksAvailable => 'No tasks available.';

  @override
  String get line => 'Line';

  @override
  String get tower => 'Tower';

  @override
  String get status => 'Status';

  @override
  String get patrolledStatus => 'Patrolled';

  @override
  String get inProgressUploadedStatus => 'In Progress (Uploaded)';

  @override
  String get inProgressLocalStatus => 'In Progress (Local)';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get continueSurvey => 'Continue Survey for this Task';

  @override
  String get task => 'Task';

  @override
  String get towers => 'Towers';

  @override
  String get patrolledCount => 'Patrolled';

  @override
  String get uploadedCount => 'Uploaded';

  @override
  String get due => 'Due';

  @override
  String get taskOptions => 'Task Options';

  @override
  String get editTask => 'Edit Task';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String deleteTaskConfirmation(Object lineName, Object towerRange) {
    return 'Are you sure you want to delete the task for Line: $lineName, Towers: $towerRange? This will also delete any associated survey progress in the app for this task. This action cannot be undone.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String uploadSuccess(Object count) {
    return '$count record details uploaded successfully!';
  }

  @override
  String get noUnsyncedRecords => 'No unsynced records to upload.';

  @override
  String get cameraPermissionDenied => 'Camera permission denied.';

  @override
  String errorInitializingCamera(Object error) {
    return 'Error initializing camera: $error';
  }

  @override
  String get noCamerasFound => 'No cameras found.';

  @override
  String errorCapturingPicture(Object error) {
    return 'Error capturing picture: $error';
  }

  @override
  String get noPhotoCaptured => 'No photo captured to save.';

  @override
  String get photoSavedLocally => 'Photo and record saved locally!';

  @override
  String get cameraCaptureCancelled => 'Camera capture cancelled or failed. Data not saved.';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get retake => 'Retake';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving...';

  @override
  String get back => 'Back';

  @override
  String lineDetails(Object lineName) {
    return 'Line: $lineName';
  }

  @override
  String towerDetails(Object towerNumber) {
    return 'Tower: $towerNumber';
  }

  @override
  String get lat => 'Lat';

  @override
  String get lon => 'Lon';

  @override
  String get time => 'Time';

  @override
  String get reviewPhoto => 'Review Photo';

  @override
  String get imageNotFound => 'Image not found or corrupted.';

  @override
  String get locationPermissionDenied => 'Location permission denied.';

  @override
  String get locationServiceDisabled => 'Location services are disabled. Please enable them to get GPS coordinates.';

  @override
  String get locationPermissionPermanentlyDenied => 'Location permissions are permanently denied. Please enable them from your device\'s app settings.';

  @override
  String errorGettingLocation(Object error) {
    return 'Error getting location stream: $error';
  }

  @override
  String get fetchingLocation => 'Fetching location';

  @override
  String get current => 'Current';

  @override
  String requiredAccuracyAchieved(Object accuracy, Object requiredAccuracy) {
    return 'Achieved: ${accuracy}m (Required < ${requiredAccuracy}m)';
  }

  @override
  String currentAccuracy(Object accuracy, Object requiredAccuracy) {
    return 'Current: ${accuracy}m (Required < ${requiredAccuracy}m)';
  }

  @override
  String timeoutReached(Object message) {
    return 'Timeout reached. $message';
  }

  @override
  String get noLocationObtained => 'No location obtained.';

  @override
  String get overallProgress => 'Overall Survey Progress';

  @override
  String get totalManagers => 'Total Managers:';

  @override
  String get totalWorkers => 'Total Workers:';

  @override
  String get totalLines => 'Total Lines:';

  @override
  String get totalTowersInSystem => 'Total Towers in System:';

  @override
  String get pendingApprovals => 'Pending Approvals:';

  @override
  String get latestPendingRequests => 'Latest Pending Requests';

  @override
  String get noPendingRequests => 'No pending requests.';

  @override
  String get managersAndAssignments => 'Managers & Their Assignments';

  @override
  String get noManagersFound => 'No managers found.';

  @override
  String get progressByWorker => 'Progress by Worker:';

  @override
  String get noWorkerProfilesFound => 'No worker profiles found or assigned tasks to track.';

  @override
  String get linesAssigned => 'Lines Assigned';

  @override
  String get linesPatrolled => 'Lines Patrolled';

  @override
  String get linesWorkingPending => 'Lines Working/Pending';

  @override
  String get linesUnderSupervision => 'Lines under your supervision:';

  @override
  String get noLinesOrTasksAvailable => 'No lines or tasks available for your role within your assigned areas.';

  @override
  String get assignedTaskDetails => 'Assigned Task Details:';

  @override
  String get lineNameField => 'Line Name';

  @override
  String get assignedTowers => 'Assigned Towers';

  @override
  String get dueDateField => 'Due Date';

  @override
  String get addNewSurveyRecord => 'Add New Survey Record';

  @override
  String get towerNumberField => 'Tower Number';

  @override
  String get enterTowerNumber => 'Enter tower number';

  @override
  String get gpsCoordinates => 'Current GPS Coordinates:';

  @override
  String get refreshLocation => 'Refresh Location';

  @override
  String get continueToPatrollingDetails => 'Continue to Patrolling Details';

  @override
  String get gettingLocation => 'Getting Location...';

  @override
  String get requiredAccuracyNotMet => 'Required Accuracy Not Met';

  @override
  String get soilCondition => 'Soil Condition';

  @override
  String get selectSoilCondition => 'Select soil condition';

  @override
  String get stubCopingLeg => 'Stub / Coping Leg';

  @override
  String get selectStubCopingLegStatus => 'Select stub/coping leg status';

  @override
  String get earthing => 'Earthing';

  @override
  String get selectEarthingStatus => 'Select earthing status';

  @override
  String get conditionOfTowerParts => 'Condition of Tower Parts';

  @override
  String get selectConditionOfTowerParts => 'Select condition of tower parts';

  @override
  String get statusOfInsulator => 'Status of Insulator';

  @override
  String get selectInsulatorStatus => 'Select insulator status';

  @override
  String get jumperStatus => 'Jumper Status';

  @override
  String get selectJumperStatus => 'Select jumper status';

  @override
  String get hotSpots => 'Hot Spots';

  @override
  String get selectHotSpotStatus => 'Select hot spot status';

  @override
  String get numberPlate => 'Number Plate';

  @override
  String get selectNumberPlateStatus => 'Select number plate status';

  @override
  String get dangerBoard => 'Danger Board';

  @override
  String get selectDangerBoardStatus => 'Select danger board status';

  @override
  String get phasePlate => 'Phase Plate';

  @override
  String get selectPhasePlateStatus => 'Select phase plate status';

  @override
  String get nutAndBoltCondition => 'Nut and Bolt Condition';

  @override
  String get selectNutAndBoltCondition => 'Select nut and bolt condition';

  @override
  String get antiClimbingDevice => 'Anti Climbing Device';

  @override
  String get selectAntiClimbingDeviceStatus => 'Select anti-climbing device status';

  @override
  String get wildGrowth => 'Wild Growth';

  @override
  String get selectWildGrowthStatus => 'Select wild growth status';

  @override
  String get birdGuard => 'Bird Guard';

  @override
  String get selectBirdGuardStatus => 'Select bird guard status';

  @override
  String get birdNest => 'Bird Nest';

  @override
  String get selectBirdNestStatus => 'Select bird nest status';

  @override
  String get archingHorn => 'Arching Horn';

  @override
  String get selectArchingHornStatus => 'Select arching horn status';

  @override
  String get coronaRing => 'Corona Ring';

  @override
  String get selectCoronaRingStatus => 'Select corona ring status';

  @override
  String get insulatorType => 'Insulator Type';

  @override
  String get selectInsulatorType => 'Select insulator type';

  @override
  String get opgwJointBox => 'OPGW Joint Box';

  @override
  String get selectOpgwJointBoxStatus => 'Select OPGW Joint Box status';

  @override
  String get missingTowerParts => 'Missing Tower Parts';

  @override
  String get continueToLineSurvey => 'Continue to Line Survey';

  @override
  String enterDetailedObservations(Object lineName, Object towerNumber) {
    return 'Enter detailed patrolling observations for Tower $towerNumber on $lineName.';
  }

  @override
  String get generalNotes => 'General Observations/Notes';

  @override
  String get building => 'Building';

  @override
  String get tree => 'Tree';

  @override
  String get numberOfTrees => 'Number of Trees';

  @override
  String get conditionOfOpgw => 'Condition of OPGW';

  @override
  String get conditionOfEarthWire => 'Condition of Earth Wire';

  @override
  String get conditionOfConductor => 'Condition of Conductor';

  @override
  String get midSpanJoint => 'Mid Span Joint';

  @override
  String get newConstruction => 'New Construction';

  @override
  String get objectOnConductor => 'Object on Conductor';

  @override
  String get objectOnEarthwire => 'Object on Earthwire';

  @override
  String get spacers => 'Spacers';

  @override
  String get vibrationDamper => 'Vibration Damper';

  @override
  String get roadCrossing => 'Road Crossing';

  @override
  String get riverCrossing => 'River Crossing';

  @override
  String get electricalLine => 'Electrical Line';

  @override
  String get railwayCrossing => 'Railway Crossing';

  @override
  String get saveDetailsAndGoToCamera => 'Save Details & Go to Camera';

  @override
  String get lineSurveyDetails => 'Line Survey Details';

  @override
  String get noRecordsToExport => 'No records to export to CSV.';

  @override
  String get allRecordsExported => 'All records exported to CSV and share dialog shown.';

  @override
  String get failedToGenerateCsv => 'Failed to generate CSV file.';

  @override
  String errorExportingCsv(Object error) {
    return 'Error exporting CSV: $error';
  }

  @override
  String get selectImagesToShare => 'Select Images to Share';

  @override
  String get noImagesAvailable => 'No images available locally to share.';

  @override
  String get selectLine => 'Select Line';

  @override
  String get searchTowerNumber => 'Search Tower Number';

  @override
  String get noTowersFound => 'No towers found matching search.';

  @override
  String get noImagesForLine => 'No images for this line available locally.';

  @override
  String shareSelected(Object count) {
    return 'Share Selected ($count)';
  }

  @override
  String get noValidImagesForShare => 'No valid images with overlays found for selected records to share.';

  @override
  String get selectedImagesShared => 'Selected images and details shared.';

  @override
  String errorSharingImages(Object error) {
    return 'Error sharing images: $error';
  }

  @override
  String deleteRecordConfirmation(Object lineName, Object towerNumber) {
    return 'Are you sure you want to delete record for Tower $towerNumber on $lineName? This action cannot be undone.';
  }

  @override
  String recordDeletedSuccessfully(Object towerNumber) {
    return 'Record for Tower $towerNumber deleted successfully.';
  }

  @override
  String errorDeletingRecord(Object error) {
    return 'Error deleting record: $error';
  }

  @override
  String get imageNotAvailableLocally => 'Image not available locally for this record. Only details are synced.';

  @override
  String get closeMenu => 'Close Menu';

  @override
  String get actions => 'Actions';

  @override
  String get shareImages => 'Share Images';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get noRecordsFoundConductSurvey => 'No survey records found. Conduct a survey first and save/upload it!';

  @override
  String get localRecordsPresentUpload => 'You have local records. Upload them to the cloud for full sync!';

  @override
  String get viewPhoto => 'View Photo';

  @override
  String get assignToWorker => 'Assign to Worker';

  @override
  String get selectWorker => 'Select a worker';

  @override
  String get selectTransmissionLine => 'Select a transmission line';

  @override
  String get fromTowerNumber => 'From Tower Number (e.g., 10)';

  @override
  String get toTowerNumber => 'To Tower Number (e.g., 30, leave empty for single tower)';

  @override
  String get selectDueDate => 'Select Due Date';

  @override
  String get assignTask => 'Assign Task';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get invalidTowerRange => 'Invalid tower range. Please check From/To values.';

  @override
  String get numberOfTowersZero => 'Number of towers to patrol cannot be zero. Check range or line total towers if \"All\" is selected.';

  @override
  String towersExceedLineTotal(Object assigned, Object total) {
    return 'The total number of towers assigned to this line ($assigned) exceeds the line\'s total towers ($total). Please adjust the range.';
  }

  @override
  String conflictOverlappingTask(Object assignedTo, Object lineName, Object status, Object towerRange) {
    return 'Conflict: A task for Line: $lineName, Towers: $towerRange (Assigned to: $assignedTo, Status: $status) overlaps with this assignment.';
  }

  @override
  String get taskAssignedSuccessfully => 'Task assigned successfully!';

  @override
  String get taskUpdatedSuccessfully => 'Task updated successfully!';

  @override
  String errorSavingTask(Object error) {
    return 'Error saving task: $error';
  }

  @override
  String cannotAssignEditTasks(Object action) {
    return 'Cannot $action tasks at this time.';
  }

  @override
  String get possibleReasons => 'Possible reasons: \n- Your account is not approved or you lack Manager/Admin role. \n- No worker accounts found. \n- No transmission lines loaded (or assigned to you if you are a Manager). (Add/Manage lines from \"Manage Lines\" in drawer)';

  @override
  String get retryLoadingData => 'Retry Loading Data';

  @override
  String get manageTransmissionLinesTitle => 'Manage Transmission Lines';

  @override
  String get addNewTransmissionLine => 'Add New Transmission Line';

  @override
  String get editTransmissionLine => 'Edit Transmission Line';

  @override
  String get voltageLevel => 'Voltage Level';

  @override
  String get selectVoltageLevel => 'Please select a voltage level';

  @override
  String get lineBaseName => 'Line Base Name (e.g., Shamli Aligarh)';

  @override
  String get enterLineName => 'Please enter a line name';

  @override
  String get towerRangeFromLabel => 'Tower Range From';

  @override
  String get enterStartTower => 'Enter start tower';

  @override
  String get towerRangeToLabel => 'Tower Range To';

  @override
  String get enterEndTower => 'Enter end tower';

  @override
  String get validPositiveNumberRequired => 'Valid positive number required';

  @override
  String get towerRangeValuesPositive => 'Tower range values must be positive.';

  @override
  String get towerRangeFromGreaterThanTo => 'Tower range \"From\" cannot be greater than \"To\".';

  @override
  String get totalTowersLabel => 'Total Towers';

  @override
  String get previewLabel => 'Preview';

  @override
  String get addLine => 'Add Line';

  @override
  String get updateLine => 'Update Line';

  @override
  String get cancelEdit => 'Cancel Edit';

  @override
  String get transmissionLineAddedSuccessfully => 'Transmission Line added successfully!';

  @override
  String get transmissionLineUpdatedSuccessfully => 'Transmission Line updated successfully!';

  @override
  String errorSavingLine(Object error) {
    return 'Error saving line: $error';
  }

  @override
  String get existingTransmissionLines => 'Existing Transmission Lines';

  @override
  String get noTransmissionLinesAdded => 'No transmission lines added yet.';

  @override
  String get transmissionLineDeletedSuccessfully => 'Transmission Line deleted successfully!';

  @override
  String errorDeletingLine(Object error) {
    return 'Error deleting line: $error';
  }

  @override
  String get confirmDeletionText => 'Are you sure you want to delete this transmission line? This action cannot be undone.';

  @override
  String get edit => 'Edit';

  @override
  String get deleteOption => 'Delete';

  @override
  String assignLinesToManager(Object managerName) {
    return 'Assign Lines to $managerName';
  }

  @override
  String get searchLines => 'Search Lines';

  @override
  String get noLinesAvailableToAssign => 'No lines available to assign.';

  @override
  String get noLinesFoundSearch => 'No lines found matching your search.';

  @override
  String get saveAssignments => 'Save';

  @override
  String get cancelAssignments => 'Cancel';

  @override
  String get noChangesToSave => 'No changes to save.';

  @override
  String linesAssignedSuccessfully(Object managerName) {
    return 'Lines assigned to $managerName successfully!';
  }

  @override
  String failedToUpdateAssignedLines(Object error) {
    return 'Failed to update assigned lines: $error';
  }

  @override
  String get userManagementTitle => 'User Management';

  @override
  String get searchUsers => 'Search Users';

  @override
  String get searchByNameOrEmail => 'Search by name or email';

  @override
  String get noUserProfilesFound => 'No user profiles found in the system.';

  @override
  String get noUsersFoundMatchingFilters => 'No users found matching current filters/search.';

  @override
  String get roleLabel => 'Role';

  @override
  String get statusFilterLabel => 'Status';

  @override
  String get manage => 'Manage';

  @override
  String get assignLinesButton => 'Assign Lines';

  @override
  String get deleteProfileButton => 'Delete Profile';

  @override
  String get confirmRejectionDeletion => 'Confirm Rejection and Deletion';

  @override
  String rejectDeleteConfirmation(Object userEmail) {
    return 'Are you sure you want to REJECT and DELETE this user\'s profile ($userEmail)? This action is irreversible.';
  }

  @override
  String get userProfileRejectedDeletedSuccessfully => 'User profile rejected and deleted successfully!';

  @override
  String get rejectionDeletionCancelled => 'Rejection/deletion cancelled.';

  @override
  String userStatusUpdated(Object newStatus) {
    return 'User status updated to $newStatus.';
  }

  @override
  String failedToUpdateUser(Object error) {
    return 'Failed to update user: $error';
  }

  @override
  String userProfileDeleted(Object userEmail) {
    return 'User profile for $userEmail deleted.';
  }

  @override
  String managerEmail(Object email) {
    return 'Email: $email';
  }

  @override
  String get managedLines => 'Managed Lines:';

  @override
  String get noManagedLines => 'This manager is not assigned to manage any transmission lines.';

  @override
  String totalTowersManaged(Object count) {
    return 'Total Towers Managed: $count';
  }

  @override
  String tasksAssignedBy(Object managerName) {
    return 'Tasks Assigned by $managerName:';
  }

  @override
  String get noAssignedTasksManager => 'This manager has not assigned any tasks yet.';

  @override
  String get assignedToUser => 'Assigned to';

  @override
  String linePatrollingDetailsScreenTitle(Object lineName) {
    return '$lineName Details';
  }

  @override
  String get searchTowerNumberOrDetails => 'Search Tower Number or Details';

  @override
  String get noSurveyRecordsFoundForLine => 'No survey records found for this line.';

  @override
  String get noRecordsFoundMatchingFiltersLine => 'No records found matching current filters.';

  @override
  String get recordId => 'Record ID';

  @override
  String get lineNameDisplay => 'Line Name';

  @override
  String get taskId => 'Task ID';

  @override
  String get userId => 'User ID';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get overallIssueStatus => 'Overall Issue Status';

  @override
  String get issueStatus => 'Issue';

  @override
  String get okStatus => 'OK';

  @override
  String get filterRecords => 'Filter Records';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get accountRoleUnassigned => 'Your account role is not assigned or recognized.';

  @override
  String get accountRoleExplanation => 'Please ensure your role (Worker, Manager, or Admin) is correctly assigned by an administrator in the Firebase Console.';

  @override
  String get adminDashboardSummary => 'Admin Dashboard Summary';

  @override
  String get totalManagersCount => 'Total Managers:';

  @override
  String get totalWorkersCount => 'Total Workers:';

  @override
  String get totalLinesCount => 'Total Lines:';

  @override
  String get totalTowersInSystemCount => 'Total Towers in System:';

  @override
  String get pendingApprovalsCount => 'Pending Approvals:';

  @override
  String get latestPendingRequestsTitle => 'Latest Pending Requests';

  @override
  String get noPendingRequestsTitle => 'No pending requests.';

  @override
  String get managersAssignmentsTitle => 'Managers & Their Assignments';

  @override
  String get noManagersFoundTitle => 'No managers found.';

  @override
  String get progressByWorkerTitle => 'Progress by Worker:';

  @override
  String get noWorkerProfilesFoundTitle => 'No worker profiles found or assigned tasks to track.';

  @override
  String linesAssignedManagerCount(Object count) {
    return 'Lines Assigned: $count';
  }

  @override
  String totalTowersAssignedManagerCount(Object count) {
    return 'Total Towers Assigned: $count';
  }

  @override
  String tasksAssignedByThemCount(Object count) {
    return 'Tasks Assigned by Them: $count';
  }

  @override
  String get viewButton => 'View >';

  @override
  String get accountNotApproved => 'Your account is not approved.';

  @override
  String get accountApprovalMessage => 'Please wait for administrator approval or contact support.';

  @override
  String get accountStatusUnknown => 'Account Status Unknown';

  @override
  String get unexpectedAccountStatus => 'An unexpected account status was encountered. Please contact support.';

  @override
  String get unassignedRoleTitle => 'Your account role is not assigned or recognized.';

  @override
  String get unassignedRoleMessage => 'Please ensure your role (Worker, Manager, or Admin) is correctly assigned by an administrator in the Firebase Console.';

  @override
  String get surveyProgressOverview => 'Survey Progress Overview';

  @override
  String get patrollingTheFuture => 'Patrolling the future...';

  @override
  String anUnexpectedErrorOccurred(Object error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String get googleSignInCancelled => 'Google Sign-In cancelled.';

  @override
  String get userProfileNotFound => 'User profile not found after sign-in. Please try again.';

  @override
  String get userNotFoundAfterSignIn => 'User not found after sign-in.';

  @override
  String get accountExistsWithDifferentCredential => 'An account already exists with different credentials.';

  @override
  String get invalidCredential => 'The credential provided is invalid.';

  @override
  String get userDisabled => 'The user associated with the given credential has been disabled.';

  @override
  String get operationNotAllowed => 'Google Sign-In is not enabled for this project.';

  @override
  String get networkRequestFailed => 'A network error occurred. Please check your internet connection.';

  @override
  String signInFailed(Object error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get noInternetConnection => 'No internet connection. Please connect and try again.';

  @override
  String errorCheckingConnectivity(Object error) {
    return 'Error checking connectivity: $error';
  }

  @override
  String get stillNoInternet => 'Still no internet connection.';

  @override
  String get internetRestored => 'Internet connection restored!';

  @override
  String errorLoadingUsers(Object error) {
    return 'Error loading users: $error';
  }

  @override
  String errorInitiatingUserStream(Object error) {
    return 'Error initiating user stream: $error';
  }

  @override
  String errorLoadingManagerLines(Object error) {
    return 'Error loading manager lines: $error';
  }

  @override
  String errorLoadingManagerTasks(Object error) {
    return 'Error loading manager tasks: $error';
  }

  @override
  String errorStreamingManagerLines(Object error) {
    return 'Error streaming transmission lines: $error';
  }

  @override
  String errorStreamingManagerTasks(Object error) {
    return 'Error streaming all tasks: $error';
  }

  @override
  String errorStreamingSurveyRecords(Object error) {
    return 'Error streaming all survey records: $error';
  }

  @override
  String errorLoadingDashboardData(Object error) {
    return 'Error loading dashboard data: $error';
  }

  @override
  String errorStreamingLocalSurveyRecords(Object error) {
    return 'Error streaming local survey records: $error';
  }

  @override
  String errorStreamingYourTasks(Object error) {
    return 'Error streaming your tasks: $error';
  }

  @override
  String errorStreamingYourSurveyRecords(Object error) {
    return 'Error streaming your survey records: $error';
  }

  @override
  String errorStreamingAllTasks(Object error) {
    return 'Error streaming all tasks: $error';
  }

  @override
  String errorStreamingAllSurveyRecords(Object error) {
    return 'Error streaming all survey records: $error';
  }

  @override
  String errorStreamingAllUsers(Object error) {
    return 'Error streaming all users: $error';
  }

  @override
  String errorLoadingData(Object error) {
    return 'Error loading data: $error';
  }

  @override
  String get towerNumberInvalid => 'Please enter a tower number';

  @override
  String get towerNumberPositive => 'Please enter a valid positive number';

  @override
  String towerOutOfRange(Object range, Object towerNumber) {
    return 'Tower number $towerNumber is outside the assigned range ($range).';
  }

  @override
  String towerSpecificRequired(Object towerNumber) {
    return 'You are assigned to survey only Tower $towerNumber.';
  }

  @override
  String accuracyLow(Object requiredAccuracy) {
    return 'Accuracy less than ${requiredAccuracy}m. Please wait or move to an open area for better GPS signal.';
  }

  @override
  String towerAlreadyExists(Object distance, Object lineName, Object towerNumber) {
    return 'A survey for Tower $towerNumber at this location (${distance}m from previous record) already exists for Line $lineName. Please ensure you are at a new tower or update the existing record if this is a re-survey.';
  }

  @override
  String towerTooClose(Object distance, Object lineName, Object minDistance, Object towerNumber) {
    return 'Another surveyed tower on Line $lineName is too close (${distance}m from Tower $towerNumber). All DIFFERENT survey points on the same line must be at least $minDistance meters apart.';
  }

  @override
  String get userNotLoggedIn => 'User not logged in. Cannot save survey.';

  @override
  String errorProcessingDetails(Object error) {
    return 'Error processing details: $error';
  }

  @override
  String errorSavingPhotoAndRecordLocally(Object error) {
    return 'Error saving photo and record locally: $error';
  }

  @override
  String errorSavingLineSurveyDetails(Object error) {
    return 'Error saving line survey details: $error';
  }

  @override
  String errorLoadingLines(Object error) {
    return 'Error loading lines: $error';
  }

  @override
  String errorInitializingLineStream(Object error) {
    return 'Error initializing line stream: $error';
  }

  @override
  String get invalidTowerNumberInput => 'Invalid \"From\" tower number. Must be a whole number.';

  @override
  String get invalidToTowerNumberInput => 'Invalid \"To\" tower number. Must be a whole number.';

  @override
  String get selectWorkerError => 'Please select a worker.';

  @override
  String get selectLineError => 'Please select a line.';

  @override
  String get selectDueDateError => 'Please select a due date.';

  @override
  String get allTowersRequiresLine => '\"All\" requires a selected line with defined towers.';

  @override
  String get allTowers => 'All Towers';

  @override
  String get surveyEntry => 'Survey Entry';

  @override
  String get moveToOpenArea => 'Move to an open area.';

  @override
  String couldNotGetLocationWithinSeconds(Object seconds) {
    return 'Could not get any location within $seconds seconds. Please try again.';
  }

  @override
  String locationAcquired(Object accuracy) {
    return 'Location acquired with best available accuracy: ${accuracy}m.';
  }

  @override
  String unexpectedErrorStartingLocation(Object error) {
    return 'An unexpected error occurred while starting location: $error';
  }

  @override
  String timeoutInSeconds(Object seconds) {
    return 'Timeout in ${seconds}s';
  }

  @override
  String get getCurrentLocation => 'Get Current Location';

  @override
  String get fillAllRequiredFields => 'Please fill all required fields correctly.';

  @override
  String get good => 'Good';

  @override
  String get backfillingRequired => 'Backfilling Required';

  @override
  String get revetmentWallRequired => 'Revetment Wall Required';

  @override
  String get excavationOfSoilRequired => 'Excavation Of Soil Required';

  @override
  String get rusted => 'Rusted';

  @override
  String get bent => 'Bent';

  @override
  String get hanging => 'Hanging';

  @override
  String get damaged => 'Damaged';

  @override
  String get cracked => 'Cracked';

  @override
  String get broken => 'Broken';

  @override
  String get flashover => 'Flashover';

  @override
  String get dirty => 'Dirty';

  @override
  String get loose => 'Loose';

  @override
  String get boltMissing => 'Bolt Missing';

  @override
  String get spacersMissing => 'Spacers Missing';

  @override
  String get corroded => 'Corroded';

  @override
  String get faded => 'Faded';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get open => 'Open';

  @override
  String get leaking => 'Leaking';

  @override
  String get present => 'Present';

  @override
  String get trimmingRequired => 'Trimming Required';

  @override
  String get loppingRequired => 'Lopping Required';

  @override
  String get cuttingRequired => 'Cutting Required';

  @override
  String get minor => 'Minor';

  @override
  String get moderate => 'Moderate';

  @override
  String get severe => 'Severe';

  @override
  String get intact => 'Intact';

  @override
  String get notApplicable => 'Not Applicable';

  @override
  String get taskAndAssociatedRecordsDeleted => 'Task and associated local records deleted successfully!';

  @override
  String get taskStatusUpdated => 'Task status updated!';

  @override
  String errorUpdatingTask(Object error) {
    return 'Error updating task: $error';
  }

  @override
  String errorUploadingUnsyncedRecords(Object error) {
    return 'Error uploading unsynced records: $error';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String welcomeUser(Object displayName, Object role) {
    return 'Welcome, $displayName ($role)!';
  }

  @override
  String get toPatrol => 'to patrol';

  @override
  String get yourSurveyLogForThisTask => 'Your Survey Log for this Task:';

  @override
  String get noSurveysRecordedForThisTask => 'No surveys recorded for this task yet.';

  @override
  String get at => 'at';

  @override
  String get recheckingAccountStatus => 'Re-checking account status...';

  @override
  String errorLoadingLineRecords(Object error) {
    return 'Error loading line records: $error';
  }

  @override
  String get nationalHighway => 'National Highway';

  @override
  String get stateHighway => 'State Highway';

  @override
  String get chakkRoad => 'Chakk road';

  @override
  String get overBridge => 'Over Bridge';

  @override
  String get underpass => 'Underpass';

  @override
  String get voltage400kV => '400kV';

  @override
  String get voltage220kV => '220kV';

  @override
  String get voltage132kV => '132kV';

  @override
  String get voltage33kV => '33kV';

  @override
  String get voltage11kV => '11kV';

  @override
  String get privateTubeWell => 'Private Tube Well';

  @override
  String get notOkay => 'NOT OKAY';

  @override
  String get unassignedRole => 'Unassigned';

  @override
  String get missing => 'Missing';

  @override
  String get patrollingDetails => 'Patrolling Details';

  @override
  String get switchToHindi => 'Switch to Hindi';

  @override
  String get switchToEnglish => 'Switch to English';

  @override
  String errorDeletingTask(Object error) {
    return 'Error deleting task: $error';
  }
}
