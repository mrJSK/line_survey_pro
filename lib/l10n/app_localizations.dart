import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Line Survey Pro'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Line Survey Pro!'**
  String get welcomeMessage;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue using the app.'**
  String get signInPrompt;

  /// No description provided for @surveyDashboard.
  ///
  /// In en, this message translates to:
  /// **'Survey Dashboard'**
  String get surveyDashboard;

  /// No description provided for @exportRecords.
  ///
  /// In en, this message translates to:
  /// **'Export Records'**
  String get exportRecords;

  /// No description provided for @realtimeTasks.
  ///
  /// In en, this message translates to:
  /// **'Real-Time Tasks'**
  String get realtimeTasks;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @manageTransmissionLines.
  ///
  /// In en, this message translates to:
  /// **'Manage Transmission Lines'**
  String get manageTransmissionLines;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @accountPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Account Pending Approval'**
  String get accountPendingApproval;

  /// No description provided for @awaitingApprovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is awaiting approval from an administrator. Once approved, you will gain full access to the app features.'**
  String get awaitingApprovalMessage;

  /// No description provided for @accountRejected.
  ///
  /// In en, this message translates to:
  /// **'Account Rejected'**
  String get accountRejected;

  /// No description provided for @rejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, your account has been rejected by an administrator. Please contact support for more information.'**
  String get rejectedMessage;

  /// No description provided for @recheckStatus.
  ///
  /// In en, this message translates to:
  /// **'Re-check Status (Requires Sign Out)'**
  String get recheckStatus;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'Oops! No Internet Connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'It seems you\'re offline. Please check your network settings and try again.'**
  String get noInternetMessage;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @yourAssignedTasks.
  ///
  /// In en, this message translates to:
  /// **'Your Assigned Tasks:'**
  String get yourAssignedTasks;

  /// No description provided for @allTasks.
  ///
  /// In en, this message translates to:
  /// **'All Tasks:'**
  String get allTasks;

  /// No description provided for @assignNewTask.
  ///
  /// In en, this message translates to:
  /// **'Assign New Task'**
  String get assignNewTask;

  /// No description provided for @uploadUnsyncedDetails.
  ///
  /// In en, this message translates to:
  /// **'Upload Unsynced Details'**
  String get uploadUnsyncedDetails;

  /// No description provided for @noTasksAssigned.
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned to you yet.'**
  String get noTasksAssigned;

  /// No description provided for @noTasksAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tasks available.'**
  String get noTasksAvailable;

  /// No description provided for @line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// No description provided for @tower.
  ///
  /// In en, this message translates to:
  /// **'Tower'**
  String get tower;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @patrolledStatus.
  ///
  /// In en, this message translates to:
  /// **'Patrolled'**
  String get patrolledStatus;

  /// No description provided for @inProgressUploadedStatus.
  ///
  /// In en, this message translates to:
  /// **'In Progress (Uploaded)'**
  String get inProgressUploadedStatus;

  /// No description provided for @inProgressLocalStatus.
  ///
  /// In en, this message translates to:
  /// **'In Progress (Local)'**
  String get inProgressLocalStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @continueSurvey.
  ///
  /// In en, this message translates to:
  /// **'Continue Survey for this Task'**
  String get continueSurvey;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @towers.
  ///
  /// In en, this message translates to:
  /// **'Towers'**
  String get towers;

  /// No description provided for @patrolledCount.
  ///
  /// In en, this message translates to:
  /// **'Patrolled'**
  String get patrolledCount;

  /// No description provided for @uploadedCount.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadedCount;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @taskOptions.
  ///
  /// In en, this message translates to:
  /// **'Task Options'**
  String get taskOptions;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @deleteTaskConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the task for Line: {lineName}, Towers: {towerRange}? This will also delete any associated survey progress in the app for this task. This action cannot be undone.'**
  String deleteTaskConfirmation(Object lineName, Object towerRange);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} record details uploaded successfully!'**
  String uploadSuccess(Object count);

  /// No description provided for @noUnsyncedRecords.
  ///
  /// In en, this message translates to:
  /// **'No unsynced records to upload.'**
  String get noUnsyncedRecords;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied.'**
  String get cameraPermissionDenied;

  /// No description provided for @errorInitializingCamera.
  ///
  /// In en, this message translates to:
  /// **'Error initializing camera: {error}'**
  String errorInitializingCamera(Object error);

  /// No description provided for @noCamerasFound.
  ///
  /// In en, this message translates to:
  /// **'No cameras found.'**
  String get noCamerasFound;

  /// No description provided for @errorCapturingPicture.
  ///
  /// In en, this message translates to:
  /// **'Error capturing picture: {error}'**
  String errorCapturingPicture(Object error);

  /// No description provided for @noPhotoCaptured.
  ///
  /// In en, this message translates to:
  /// **'No photo captured to save.'**
  String get noPhotoCaptured;

  /// No description provided for @photoSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Photo and record saved locally!'**
  String get photoSavedLocally;

  /// No description provided for @cameraCaptureCancelled.
  ///
  /// In en, this message translates to:
  /// **'Camera capture cancelled or failed. Data not saved.'**
  String get cameraCaptureCancelled;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @lineDetails.
  ///
  /// In en, this message translates to:
  /// **'Line: {lineName}'**
  String lineDetails(Object lineName);

  /// No description provided for @towerDetails.
  ///
  /// In en, this message translates to:
  /// **'Tower: {towerNumber}'**
  String towerDetails(Object towerNumber);

  /// No description provided for @lat.
  ///
  /// In en, this message translates to:
  /// **'Lat'**
  String get lat;

  /// No description provided for @lon.
  ///
  /// In en, this message translates to:
  /// **'Lon'**
  String get lon;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @reviewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Review Photo'**
  String get reviewPhoto;

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found or corrupted.'**
  String get imageNotFound;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them to get GPS coordinates.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied. Please enable them from your device\'s app settings.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @errorGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location stream: {error}'**
  String errorGettingLocation(Object error);

  /// No description provided for @fetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching location'**
  String get fetchingLocation;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @requiredAccuracyAchieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved: {accuracy}m (Required < {requiredAccuracy}m)'**
  String requiredAccuracyAchieved(Object accuracy, Object requiredAccuracy);

  /// No description provided for @currentAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Current: {accuracy}m (Required < {requiredAccuracy}m)'**
  String currentAccuracy(Object accuracy, Object requiredAccuracy);

  /// No description provided for @timeoutReached.
  ///
  /// In en, this message translates to:
  /// **'Timeout reached. {message}'**
  String timeoutReached(Object message);

  /// No description provided for @noLocationObtained.
  ///
  /// In en, this message translates to:
  /// **'No location obtained.'**
  String get noLocationObtained;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Survey Progress'**
  String get overallProgress;

  /// No description provided for @totalManagers.
  ///
  /// In en, this message translates to:
  /// **'Total Managers:'**
  String get totalManagers;

  /// No description provided for @totalWorkers.
  ///
  /// In en, this message translates to:
  /// **'Total Workers:'**
  String get totalWorkers;

  /// No description provided for @totalLines.
  ///
  /// In en, this message translates to:
  /// **'Total Lines:'**
  String get totalLines;

  /// No description provided for @totalTowersInSystem.
  ///
  /// In en, this message translates to:
  /// **'Total Towers in System:'**
  String get totalTowersInSystem;

  /// No description provided for @pendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals:'**
  String get pendingApprovals;

  /// No description provided for @latestPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Latest Pending Requests'**
  String get latestPendingRequests;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests.'**
  String get noPendingRequests;

  /// No description provided for @managersAndAssignments.
  ///
  /// In en, this message translates to:
  /// **'Managers & Their Assignments'**
  String get managersAndAssignments;

  /// No description provided for @noManagersFound.
  ///
  /// In en, this message translates to:
  /// **'No managers found.'**
  String get noManagersFound;

  /// No description provided for @progressByWorker.
  ///
  /// In en, this message translates to:
  /// **'Progress by Worker:'**
  String get progressByWorker;

  /// No description provided for @noWorkerProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No worker profiles found or assigned tasks to track.'**
  String get noWorkerProfilesFound;

  /// No description provided for @linesAssigned.
  ///
  /// In en, this message translates to:
  /// **'Lines Assigned'**
  String get linesAssigned;

  /// No description provided for @linesPatrolled.
  ///
  /// In en, this message translates to:
  /// **'Lines Patrolled'**
  String get linesPatrolled;

  /// No description provided for @linesWorkingPending.
  ///
  /// In en, this message translates to:
  /// **'Lines Working/Pending'**
  String get linesWorkingPending;

  /// No description provided for @linesUnderSupervision.
  ///
  /// In en, this message translates to:
  /// **'Lines under your supervision:'**
  String get linesUnderSupervision;

  /// No description provided for @noLinesOrTasksAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lines or tasks available for your role within your assigned areas.'**
  String get noLinesOrTasksAvailable;

  /// No description provided for @assignedTaskDetails.
  ///
  /// In en, this message translates to:
  /// **'Assigned Task Details:'**
  String get assignedTaskDetails;

  /// No description provided for @lineNameField.
  ///
  /// In en, this message translates to:
  /// **'Line Name'**
  String get lineNameField;

  /// No description provided for @assignedTowers.
  ///
  /// In en, this message translates to:
  /// **'Assigned Towers'**
  String get assignedTowers;

  /// No description provided for @dueDateField.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDateField;

  /// No description provided for @addNewSurveyRecord.
  ///
  /// In en, this message translates to:
  /// **'Add New Survey Record'**
  String get addNewSurveyRecord;

  /// No description provided for @towerNumberField.
  ///
  /// In en, this message translates to:
  /// **'Tower Number'**
  String get towerNumberField;

  /// No description provided for @enterTowerNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter tower number'**
  String get enterTowerNumber;

  /// No description provided for @gpsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Current GPS Coordinates:'**
  String get gpsCoordinates;

  /// No description provided for @refreshLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh Location'**
  String get refreshLocation;

  /// No description provided for @continueToPatrollingDetails.
  ///
  /// In en, this message translates to:
  /// **'Continue to Patrolling Details'**
  String get continueToPatrollingDetails;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting Location...'**
  String get gettingLocation;

  /// No description provided for @requiredAccuracyNotMet.
  ///
  /// In en, this message translates to:
  /// **'Required Accuracy Not Met'**
  String get requiredAccuracyNotMet;

  /// No description provided for @soilCondition.
  ///
  /// In en, this message translates to:
  /// **'Soil Condition'**
  String get soilCondition;

  /// No description provided for @selectSoilCondition.
  ///
  /// In en, this message translates to:
  /// **'Select soil condition'**
  String get selectSoilCondition;

  /// No description provided for @stubCopingLeg.
  ///
  /// In en, this message translates to:
  /// **'Stub / Coping Leg'**
  String get stubCopingLeg;

  /// No description provided for @selectStubCopingLegStatus.
  ///
  /// In en, this message translates to:
  /// **'Select stub/coping leg status'**
  String get selectStubCopingLegStatus;

  /// No description provided for @earthing.
  ///
  /// In en, this message translates to:
  /// **'Earthing'**
  String get earthing;

  /// No description provided for @selectEarthingStatus.
  ///
  /// In en, this message translates to:
  /// **'Select earthing status'**
  String get selectEarthingStatus;

  /// No description provided for @conditionOfTowerParts.
  ///
  /// In en, this message translates to:
  /// **'Condition of Tower Parts'**
  String get conditionOfTowerParts;

  /// No description provided for @selectConditionOfTowerParts.
  ///
  /// In en, this message translates to:
  /// **'Select condition of tower parts'**
  String get selectConditionOfTowerParts;

  /// No description provided for @statusOfInsulator.
  ///
  /// In en, this message translates to:
  /// **'Status of Insulator'**
  String get statusOfInsulator;

  /// No description provided for @selectInsulatorStatus.
  ///
  /// In en, this message translates to:
  /// **'Select insulator status'**
  String get selectInsulatorStatus;

  /// No description provided for @jumperStatus.
  ///
  /// In en, this message translates to:
  /// **'Jumper Status'**
  String get jumperStatus;

  /// No description provided for @selectJumperStatus.
  ///
  /// In en, this message translates to:
  /// **'Select jumper status'**
  String get selectJumperStatus;

  /// No description provided for @hotSpots.
  ///
  /// In en, this message translates to:
  /// **'Hot Spots'**
  String get hotSpots;

  /// No description provided for @selectHotSpotStatus.
  ///
  /// In en, this message translates to:
  /// **'Select hot spot status'**
  String get selectHotSpotStatus;

  /// No description provided for @numberPlate.
  ///
  /// In en, this message translates to:
  /// **'Number Plate'**
  String get numberPlate;

  /// No description provided for @selectNumberPlateStatus.
  ///
  /// In en, this message translates to:
  /// **'Select number plate status'**
  String get selectNumberPlateStatus;

  /// No description provided for @dangerBoard.
  ///
  /// In en, this message translates to:
  /// **'Danger Board'**
  String get dangerBoard;

  /// No description provided for @selectDangerBoardStatus.
  ///
  /// In en, this message translates to:
  /// **'Select danger board status'**
  String get selectDangerBoardStatus;

  /// No description provided for @phasePlate.
  ///
  /// In en, this message translates to:
  /// **'Phase Plate'**
  String get phasePlate;

  /// No description provided for @selectPhasePlateStatus.
  ///
  /// In en, this message translates to:
  /// **'Select phase plate status'**
  String get selectPhasePlateStatus;

  /// No description provided for @nutAndBoltCondition.
  ///
  /// In en, this message translates to:
  /// **'Nut and Bolt Condition'**
  String get nutAndBoltCondition;

  /// No description provided for @selectNutAndBoltCondition.
  ///
  /// In en, this message translates to:
  /// **'Select nut and bolt condition'**
  String get selectNutAndBoltCondition;

  /// No description provided for @antiClimbingDevice.
  ///
  /// In en, this message translates to:
  /// **'Anti Climbing Device'**
  String get antiClimbingDevice;

  /// No description provided for @selectAntiClimbingDeviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Select anti-climbing device status'**
  String get selectAntiClimbingDeviceStatus;

  /// No description provided for @wildGrowth.
  ///
  /// In en, this message translates to:
  /// **'Wild Growth'**
  String get wildGrowth;

  /// No description provided for @selectWildGrowthStatus.
  ///
  /// In en, this message translates to:
  /// **'Select wild growth status'**
  String get selectWildGrowthStatus;

  /// No description provided for @birdGuard.
  ///
  /// In en, this message translates to:
  /// **'Bird Guard'**
  String get birdGuard;

  /// No description provided for @selectBirdGuardStatus.
  ///
  /// In en, this message translates to:
  /// **'Select bird guard status'**
  String get selectBirdGuardStatus;

  /// No description provided for @birdNest.
  ///
  /// In en, this message translates to:
  /// **'Bird Nest'**
  String get birdNest;

  /// No description provided for @selectBirdNestStatus.
  ///
  /// In en, this message translates to:
  /// **'Select bird nest status'**
  String get selectBirdNestStatus;

  /// No description provided for @archingHorn.
  ///
  /// In en, this message translates to:
  /// **'Arching Horn'**
  String get archingHorn;

  /// No description provided for @selectArchingHornStatus.
  ///
  /// In en, this message translates to:
  /// **'Select arching horn status'**
  String get selectArchingHornStatus;

  /// No description provided for @coronaRing.
  ///
  /// In en, this message translates to:
  /// **'Corona Ring'**
  String get coronaRing;

  /// No description provided for @selectCoronaRingStatus.
  ///
  /// In en, this message translates to:
  /// **'Select corona ring status'**
  String get selectCoronaRingStatus;

  /// No description provided for @insulatorType.
  ///
  /// In en, this message translates to:
  /// **'Insulator Type'**
  String get insulatorType;

  /// No description provided for @selectInsulatorType.
  ///
  /// In en, this message translates to:
  /// **'Select insulator type'**
  String get selectInsulatorType;

  /// No description provided for @opgwJointBox.
  ///
  /// In en, this message translates to:
  /// **'OPGW Joint Box'**
  String get opgwJointBox;

  /// No description provided for @selectOpgwJointBoxStatus.
  ///
  /// In en, this message translates to:
  /// **'Select OPGW Joint Box status'**
  String get selectOpgwJointBoxStatus;

  /// No description provided for @missingTowerParts.
  ///
  /// In en, this message translates to:
  /// **'Missing Tower Parts'**
  String get missingTowerParts;

  /// No description provided for @continueToLineSurvey.
  ///
  /// In en, this message translates to:
  /// **'Continue to Line Survey'**
  String get continueToLineSurvey;

  /// No description provided for @enterDetailedObservations.
  ///
  /// In en, this message translates to:
  /// **'Enter detailed patrolling observations for Tower {towerNumber} on {lineName}.'**
  String enterDetailedObservations(Object lineName, Object towerNumber);

  /// No description provided for @generalNotes.
  ///
  /// In en, this message translates to:
  /// **'General Observations/Notes'**
  String get generalNotes;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @tree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get tree;

  /// No description provided for @numberOfTrees.
  ///
  /// In en, this message translates to:
  /// **'Number of Trees'**
  String get numberOfTrees;

  /// No description provided for @conditionOfOpgw.
  ///
  /// In en, this message translates to:
  /// **'Condition of OPGW'**
  String get conditionOfOpgw;

  /// No description provided for @conditionOfEarthWire.
  ///
  /// In en, this message translates to:
  /// **'Condition of Earth Wire'**
  String get conditionOfEarthWire;

  /// No description provided for @conditionOfConductor.
  ///
  /// In en, this message translates to:
  /// **'Condition of Conductor'**
  String get conditionOfConductor;

  /// No description provided for @midSpanJoint.
  ///
  /// In en, this message translates to:
  /// **'Mid Span Joint'**
  String get midSpanJoint;

  /// No description provided for @newConstruction.
  ///
  /// In en, this message translates to:
  /// **'New Construction'**
  String get newConstruction;

  /// No description provided for @objectOnConductor.
  ///
  /// In en, this message translates to:
  /// **'Object on Conductor'**
  String get objectOnConductor;

  /// No description provided for @objectOnEarthwire.
  ///
  /// In en, this message translates to:
  /// **'Object on Earthwire'**
  String get objectOnEarthwire;

  /// No description provided for @spacers.
  ///
  /// In en, this message translates to:
  /// **'Spacers'**
  String get spacers;

  /// No description provided for @vibrationDamper.
  ///
  /// In en, this message translates to:
  /// **'Vibration Damper'**
  String get vibrationDamper;

  /// No description provided for @roadCrossing.
  ///
  /// In en, this message translates to:
  /// **'Road Crossing'**
  String get roadCrossing;

  /// No description provided for @riverCrossing.
  ///
  /// In en, this message translates to:
  /// **'River Crossing'**
  String get riverCrossing;

  /// No description provided for @electricalLine.
  ///
  /// In en, this message translates to:
  /// **'Electrical Line'**
  String get electricalLine;

  /// No description provided for @railwayCrossing.
  ///
  /// In en, this message translates to:
  /// **'Railway Crossing'**
  String get railwayCrossing;

  /// No description provided for @saveDetailsAndGoToCamera.
  ///
  /// In en, this message translates to:
  /// **'Save Details & Go to Camera'**
  String get saveDetailsAndGoToCamera;

  /// No description provided for @lineSurveyDetails.
  ///
  /// In en, this message translates to:
  /// **'Line Survey Details'**
  String get lineSurveyDetails;

  /// No description provided for @noRecordsToExport.
  ///
  /// In en, this message translates to:
  /// **'No records to export to CSV.'**
  String get noRecordsToExport;

  /// No description provided for @allRecordsExported.
  ///
  /// In en, this message translates to:
  /// **'All records exported to CSV and share dialog shown.'**
  String get allRecordsExported;

  /// No description provided for @failedToGenerateCsv.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate CSV file.'**
  String get failedToGenerateCsv;

  /// No description provided for @errorExportingCsv.
  ///
  /// In en, this message translates to:
  /// **'Error exporting CSV: {error}'**
  String errorExportingCsv(Object error);

  /// No description provided for @selectImagesToShare.
  ///
  /// In en, this message translates to:
  /// **'Select Images to Share'**
  String get selectImagesToShare;

  /// No description provided for @noImagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No images available locally to share.'**
  String get noImagesAvailable;

  /// No description provided for @selectLine.
  ///
  /// In en, this message translates to:
  /// **'Select Line'**
  String get selectLine;

  /// No description provided for @searchTowerNumber.
  ///
  /// In en, this message translates to:
  /// **'Search Tower Number'**
  String get searchTowerNumber;

  /// No description provided for @noTowersFound.
  ///
  /// In en, this message translates to:
  /// **'No towers found matching search.'**
  String get noTowersFound;

  /// No description provided for @noImagesForLine.
  ///
  /// In en, this message translates to:
  /// **'No images for this line available locally.'**
  String get noImagesForLine;

  /// No description provided for @shareSelected.
  ///
  /// In en, this message translates to:
  /// **'Share Selected ({count})'**
  String shareSelected(Object count);

  /// No description provided for @noValidImagesForShare.
  ///
  /// In en, this message translates to:
  /// **'No valid images with overlays found for selected records to share.'**
  String get noValidImagesForShare;

  /// No description provided for @selectedImagesShared.
  ///
  /// In en, this message translates to:
  /// **'Selected images and details shared.'**
  String get selectedImagesShared;

  /// No description provided for @errorSharingImages.
  ///
  /// In en, this message translates to:
  /// **'Error sharing images: {error}'**
  String errorSharingImages(Object error);

  /// No description provided for @deleteRecordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete record for Tower {towerNumber} on {lineName}? This action cannot be undone.'**
  String deleteRecordConfirmation(Object lineName, Object towerNumber);

  /// No description provided for @recordDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Record for Tower {towerNumber} deleted successfully.'**
  String recordDeletedSuccessfully(Object towerNumber);

  /// No description provided for @errorDeletingRecord.
  ///
  /// In en, this message translates to:
  /// **'Error deleting record: {error}'**
  String errorDeletingRecord(Object error);

  /// No description provided for @imageNotAvailableLocally.
  ///
  /// In en, this message translates to:
  /// **'Image not available locally for this record. Only details are synced.'**
  String get imageNotAvailableLocally;

  /// No description provided for @closeMenu.
  ///
  /// In en, this message translates to:
  /// **'Close Menu'**
  String get closeMenu;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @shareImages.
  ///
  /// In en, this message translates to:
  /// **'Share Images'**
  String get shareImages;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @noRecordsFoundConductSurvey.
  ///
  /// In en, this message translates to:
  /// **'No survey records found. Conduct a survey first and save/upload it!'**
  String get noRecordsFoundConductSurvey;

  /// No description provided for @localRecordsPresentUpload.
  ///
  /// In en, this message translates to:
  /// **'You have local records. Upload them to the cloud for full sync!'**
  String get localRecordsPresentUpload;

  /// No description provided for @viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View Photo'**
  String get viewPhoto;

  /// No description provided for @assignToWorker.
  ///
  /// In en, this message translates to:
  /// **'Assign to Worker'**
  String get assignToWorker;

  /// No description provided for @selectWorker.
  ///
  /// In en, this message translates to:
  /// **'Select a worker'**
  String get selectWorker;

  /// No description provided for @selectTransmissionLine.
  ///
  /// In en, this message translates to:
  /// **'Select a transmission line'**
  String get selectTransmissionLine;

  /// No description provided for @fromTowerNumber.
  ///
  /// In en, this message translates to:
  /// **'From Tower Number (e.g., 10)'**
  String get fromTowerNumber;

  /// No description provided for @toTowerNumber.
  ///
  /// In en, this message translates to:
  /// **'To Tower Number (e.g., 30, leave empty for single tower)'**
  String get toTowerNumber;

  /// No description provided for @selectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select Due Date'**
  String get selectDueDate;

  /// No description provided for @assignTask.
  ///
  /// In en, this message translates to:
  /// **'Assign Task'**
  String get assignTask;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @invalidTowerRange.
  ///
  /// In en, this message translates to:
  /// **'Invalid tower range. Please check From/To values.'**
  String get invalidTowerRange;

  /// No description provided for @numberOfTowersZero.
  ///
  /// In en, this message translates to:
  /// **'Number of towers to patrol cannot be zero. Check range or line total towers if \"All\" is selected.'**
  String get numberOfTowersZero;

  /// No description provided for @towersExceedLineTotal.
  ///
  /// In en, this message translates to:
  /// **'The total number of towers assigned to this line ({assigned}) exceeds the line\'s total towers ({total}). Please adjust the range.'**
  String towersExceedLineTotal(Object assigned, Object total);

  /// No description provided for @conflictOverlappingTask.
  ///
  /// In en, this message translates to:
  /// **'Conflict: A task for Line: {lineName}, Towers: {towerRange} (Assigned to: {assignedTo}, Status: {status}) overlaps with this assignment.'**
  String conflictOverlappingTask(Object assignedTo, Object lineName, Object status, Object towerRange);

  /// No description provided for @taskAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task assigned successfully!'**
  String get taskAssignedSuccessfully;

  /// No description provided for @taskUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task updated successfully!'**
  String get taskUpdatedSuccessfully;

  /// No description provided for @errorSavingTask.
  ///
  /// In en, this message translates to:
  /// **'Error saving task: {error}'**
  String errorSavingTask(Object error);

  /// No description provided for @cannotAssignEditTasks.
  ///
  /// In en, this message translates to:
  /// **'Cannot {action} tasks at this time.'**
  String cannotAssignEditTasks(Object action);

  /// No description provided for @possibleReasons.
  ///
  /// In en, this message translates to:
  /// **'Possible reasons: \n- Your account is not approved or you lack Manager/Admin role. \n- No worker accounts found. \n- No transmission lines loaded (or assigned to you if you are a Manager). (Add/Manage lines from \"Manage Lines\" in drawer)'**
  String get possibleReasons;

  /// No description provided for @retryLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Retry Loading Data'**
  String get retryLoadingData;

  /// No description provided for @manageTransmissionLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Transmission Lines'**
  String get manageTransmissionLinesTitle;

  /// No description provided for @addNewTransmissionLine.
  ///
  /// In en, this message translates to:
  /// **'Add New Transmission Line'**
  String get addNewTransmissionLine;

  /// No description provided for @editTransmissionLine.
  ///
  /// In en, this message translates to:
  /// **'Edit Transmission Line'**
  String get editTransmissionLine;

  /// No description provided for @voltageLevel.
  ///
  /// In en, this message translates to:
  /// **'Voltage Level'**
  String get voltageLevel;

  /// No description provided for @selectVoltageLevel.
  ///
  /// In en, this message translates to:
  /// **'Please select a voltage level'**
  String get selectVoltageLevel;

  /// No description provided for @lineBaseName.
  ///
  /// In en, this message translates to:
  /// **'Line Base Name (e.g., Shamli Aligarh)'**
  String get lineBaseName;

  /// No description provided for @enterLineName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a line name'**
  String get enterLineName;

  /// No description provided for @towerRangeFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Tower Range From'**
  String get towerRangeFromLabel;

  /// No description provided for @enterStartTower.
  ///
  /// In en, this message translates to:
  /// **'Enter start tower'**
  String get enterStartTower;

  /// No description provided for @towerRangeToLabel.
  ///
  /// In en, this message translates to:
  /// **'Tower Range To'**
  String get towerRangeToLabel;

  /// No description provided for @enterEndTower.
  ///
  /// In en, this message translates to:
  /// **'Enter end tower'**
  String get enterEndTower;

  /// No description provided for @validPositiveNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Valid positive number required'**
  String get validPositiveNumberRequired;

  /// No description provided for @towerRangeValuesPositive.
  ///
  /// In en, this message translates to:
  /// **'Tower range values must be positive.'**
  String get towerRangeValuesPositive;

  /// No description provided for @towerRangeFromGreaterThanTo.
  ///
  /// In en, this message translates to:
  /// **'Tower range \"From\" cannot be greater than \"To\".'**
  String get towerRangeFromGreaterThanTo;

  /// No description provided for @totalTowersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Towers'**
  String get totalTowersLabel;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @addLine.
  ///
  /// In en, this message translates to:
  /// **'Add Line'**
  String get addLine;

  /// No description provided for @updateLine.
  ///
  /// In en, this message translates to:
  /// **'Update Line'**
  String get updateLine;

  /// No description provided for @cancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel Edit'**
  String get cancelEdit;

  /// No description provided for @transmissionLineAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Transmission Line added successfully!'**
  String get transmissionLineAddedSuccessfully;

  /// No description provided for @transmissionLineUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Transmission Line updated successfully!'**
  String get transmissionLineUpdatedSuccessfully;

  /// No description provided for @errorSavingLine.
  ///
  /// In en, this message translates to:
  /// **'Error saving line: {error}'**
  String errorSavingLine(Object error);

  /// No description provided for @existingTransmissionLines.
  ///
  /// In en, this message translates to:
  /// **'Existing Transmission Lines'**
  String get existingTransmissionLines;

  /// No description provided for @noTransmissionLinesAdded.
  ///
  /// In en, this message translates to:
  /// **'No transmission lines added yet.'**
  String get noTransmissionLinesAdded;

  /// No description provided for @transmissionLineDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Transmission Line deleted successfully!'**
  String get transmissionLineDeletedSuccessfully;

  /// No description provided for @errorDeletingLine.
  ///
  /// In en, this message translates to:
  /// **'Error deleting line: {error}'**
  String errorDeletingLine(Object error);

  /// No description provided for @confirmDeletionText.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transmission line? This action cannot be undone.'**
  String get confirmDeletionText;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deleteOption.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteOption;

  /// No description provided for @assignLinesToManager.
  ///
  /// In en, this message translates to:
  /// **'Assign Lines to {managerName}'**
  String assignLinesToManager(Object managerName);

  /// No description provided for @searchLines.
  ///
  /// In en, this message translates to:
  /// **'Search Lines'**
  String get searchLines;

  /// No description provided for @noLinesAvailableToAssign.
  ///
  /// In en, this message translates to:
  /// **'No lines available to assign.'**
  String get noLinesAvailableToAssign;

  /// No description provided for @noLinesFoundSearch.
  ///
  /// In en, this message translates to:
  /// **'No lines found matching your search.'**
  String get noLinesFoundSearch;

  /// No description provided for @saveAssignments.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAssignments;

  /// No description provided for @cancelAssignments.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAssignments;

  /// No description provided for @noChangesToSave.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get noChangesToSave;

  /// No description provided for @linesAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Lines assigned to {managerName} successfully!'**
  String linesAssignedSuccessfully(Object managerName);

  /// No description provided for @failedToUpdateAssignedLines.
  ///
  /// In en, this message translates to:
  /// **'Failed to update assigned lines: {error}'**
  String failedToUpdateAssignedLines(Object error);

  /// No description provided for @userManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagementTitle;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search Users'**
  String get searchUsers;

  /// No description provided for @searchByNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get searchByNameOrEmail;

  /// No description provided for @noUserProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No user profiles found in the system.'**
  String get noUserProfilesFound;

  /// No description provided for @noUsersFoundMatchingFilters.
  ///
  /// In en, this message translates to:
  /// **'No users found matching current filters/search.'**
  String get noUsersFoundMatchingFilters;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @statusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusFilterLabel;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @assignLinesButton.
  ///
  /// In en, this message translates to:
  /// **'Assign Lines'**
  String get assignLinesButton;

  /// No description provided for @deleteProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfileButton;

  /// No description provided for @confirmRejectionDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Rejection and Deletion'**
  String get confirmRejectionDeletion;

  /// No description provided for @rejectDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to REJECT and DELETE this user\'s profile ({userEmail})? This action is irreversible.'**
  String rejectDeleteConfirmation(Object userEmail);

  /// No description provided for @userProfileRejectedDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User profile rejected and deleted successfully!'**
  String get userProfileRejectedDeletedSuccessfully;

  /// No description provided for @rejectionDeletionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Rejection/deletion cancelled.'**
  String get rejectionDeletionCancelled;

  /// No description provided for @userStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'User status updated to {newStatus}.'**
  String userStatusUpdated(Object newStatus);

  /// No description provided for @failedToUpdateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to update user: {error}'**
  String failedToUpdateUser(Object error);

  /// No description provided for @userProfileDeleted.
  ///
  /// In en, this message translates to:
  /// **'User profile for {userEmail} deleted.'**
  String userProfileDeleted(Object userEmail);

  /// No description provided for @managerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String managerEmail(Object email);

  /// No description provided for @managedLines.
  ///
  /// In en, this message translates to:
  /// **'Managed Lines:'**
  String get managedLines;

  /// No description provided for @noManagedLines.
  ///
  /// In en, this message translates to:
  /// **'This manager is not assigned to manage any transmission lines.'**
  String get noManagedLines;

  /// No description provided for @totalTowersManaged.
  ///
  /// In en, this message translates to:
  /// **'Total Towers Managed: {count}'**
  String totalTowersManaged(Object count);

  /// No description provided for @tasksAssignedBy.
  ///
  /// In en, this message translates to:
  /// **'Tasks Assigned by {managerName}:'**
  String tasksAssignedBy(Object managerName);

  /// No description provided for @noAssignedTasksManager.
  ///
  /// In en, this message translates to:
  /// **'This manager has not assigned any tasks yet.'**
  String get noAssignedTasksManager;

  /// No description provided for @assignedToUser.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedToUser;

  /// No description provided for @linePatrollingDetailsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'{lineName} Details'**
  String linePatrollingDetailsScreenTitle(Object lineName);

  /// No description provided for @searchTowerNumberOrDetails.
  ///
  /// In en, this message translates to:
  /// **'Search Tower Number or Details'**
  String get searchTowerNumberOrDetails;

  /// No description provided for @noSurveyRecordsFoundForLine.
  ///
  /// In en, this message translates to:
  /// **'No survey records found for this line.'**
  String get noSurveyRecordsFoundForLine;

  /// No description provided for @noRecordsFoundMatchingFiltersLine.
  ///
  /// In en, this message translates to:
  /// **'No records found matching current filters.'**
  String get noRecordsFoundMatchingFiltersLine;

  /// No description provided for @recordId.
  ///
  /// In en, this message translates to:
  /// **'Record ID'**
  String get recordId;

  /// No description provided for @lineNameDisplay.
  ///
  /// In en, this message translates to:
  /// **'Line Name'**
  String get lineNameDisplay;

  /// No description provided for @taskId.
  ///
  /// In en, this message translates to:
  /// **'Task ID'**
  String get taskId;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @overallIssueStatus.
  ///
  /// In en, this message translates to:
  /// **'Overall Issue Status'**
  String get overallIssueStatus;

  /// No description provided for @issueStatus.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueStatus;

  /// No description provided for @okStatus.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okStatus;

  /// No description provided for @filterRecords.
  ///
  /// In en, this message translates to:
  /// **'Filter Records'**
  String get filterRecords;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @accountRoleUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Your account role is not assigned or recognized.'**
  String get accountRoleUnassigned;

  /// No description provided for @accountRoleExplanation.
  ///
  /// In en, this message translates to:
  /// **'Please ensure your role (Worker, Manager, or Admin) is correctly assigned by an administrator in the Firebase Console.'**
  String get accountRoleExplanation;

  /// No description provided for @adminDashboardSummary.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard Summary'**
  String get adminDashboardSummary;

  /// No description provided for @totalManagersCount.
  ///
  /// In en, this message translates to:
  /// **'Total Managers:'**
  String get totalManagersCount;

  /// No description provided for @totalWorkersCount.
  ///
  /// In en, this message translates to:
  /// **'Total Workers:'**
  String get totalWorkersCount;

  /// No description provided for @totalLinesCount.
  ///
  /// In en, this message translates to:
  /// **'Total Lines:'**
  String get totalLinesCount;

  /// No description provided for @totalTowersInSystemCount.
  ///
  /// In en, this message translates to:
  /// **'Total Towers in System:'**
  String get totalTowersInSystemCount;

  /// No description provided for @pendingApprovalsCount.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals:'**
  String get pendingApprovalsCount;

  /// No description provided for @latestPendingRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest Pending Requests'**
  String get latestPendingRequestsTitle;

  /// No description provided for @noPendingRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending requests.'**
  String get noPendingRequestsTitle;

  /// No description provided for @managersAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Managers & Their Assignments'**
  String get managersAssignmentsTitle;

  /// No description provided for @noManagersFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No managers found.'**
  String get noManagersFoundTitle;

  /// No description provided for @progressByWorkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress by Worker:'**
  String get progressByWorkerTitle;

  /// No description provided for @noWorkerProfilesFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No worker profiles found or assigned tasks to track.'**
  String get noWorkerProfilesFoundTitle;

  /// No description provided for @linesAssignedManagerCount.
  ///
  /// In en, this message translates to:
  /// **'Lines Assigned: {count}'**
  String linesAssignedManagerCount(Object count);

  /// No description provided for @totalTowersAssignedManagerCount.
  ///
  /// In en, this message translates to:
  /// **'Total Towers Assigned: {count}'**
  String totalTowersAssignedManagerCount(Object count);

  /// No description provided for @tasksAssignedByThemCount.
  ///
  /// In en, this message translates to:
  /// **'Tasks Assigned by Them: {count}'**
  String tasksAssignedByThemCount(Object count);

  /// No description provided for @viewButton.
  ///
  /// In en, this message translates to:
  /// **'View >'**
  String get viewButton;

  /// No description provided for @accountNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Your account is not approved.'**
  String get accountNotApproved;

  /// No description provided for @accountApprovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait for administrator approval or contact support.'**
  String get accountApprovalMessage;

  /// No description provided for @accountStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Account Status Unknown'**
  String get accountStatusUnknown;

  /// No description provided for @unexpectedAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'An unexpected account status was encountered. Please contact support.'**
  String get unexpectedAccountStatus;

  /// No description provided for @unassignedRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account role is not assigned or recognized.'**
  String get unassignedRoleTitle;

  /// No description provided for @unassignedRoleMessage.
  ///
  /// In en, this message translates to:
  /// **'Please ensure your role (Worker, Manager, or Admin) is correctly assigned by an administrator in the Firebase Console.'**
  String get unassignedRoleMessage;

  /// No description provided for @surveyProgressOverview.
  ///
  /// In en, this message translates to:
  /// **'Survey Progress Overview'**
  String get surveyProgressOverview;

  /// No description provided for @patrollingTheFuture.
  ///
  /// In en, this message translates to:
  /// **'Patrolling the future...'**
  String get patrollingTheFuture;

  /// No description provided for @anUnexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String anUnexpectedErrorOccurred(Object error);

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In cancelled.'**
  String get googleSignInCancelled;

  /// No description provided for @userProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'User profile not found after sign-in. Please try again.'**
  String get userProfileNotFound;

  /// No description provided for @userNotFoundAfterSignIn.
  ///
  /// In en, this message translates to:
  /// **'User not found after sign-in.'**
  String get userNotFoundAfterSignIn;

  /// No description provided for @accountExistsWithDifferentCredential.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with different credentials.'**
  String get accountExistsWithDifferentCredential;

  /// No description provided for @invalidCredential.
  ///
  /// In en, this message translates to:
  /// **'The credential provided is invalid.'**
  String get invalidCredential;

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'The user associated with the given credential has been disabled.'**
  String get userDisabled;

  /// No description provided for @operationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not enabled for this project.'**
  String get operationNotAllowed;

  /// No description provided for @networkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'A network error occurred. Please check your internet connection.'**
  String get networkRequestFailed;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {error}'**
  String signInFailed(Object error);

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please connect and try again.'**
  String get noInternetConnection;

  /// No description provided for @errorCheckingConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Error checking connectivity: {error}'**
  String errorCheckingConnectivity(Object error);

  /// No description provided for @stillNoInternet.
  ///
  /// In en, this message translates to:
  /// **'Still no internet connection.'**
  String get stillNoInternet;

  /// No description provided for @internetRestored.
  ///
  /// In en, this message translates to:
  /// **'Internet connection restored!'**
  String get internetRestored;

  /// No description provided for @errorLoadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error loading users: {error}'**
  String errorLoadingUsers(Object error);

  /// No description provided for @errorInitiatingUserStream.
  ///
  /// In en, this message translates to:
  /// **'Error initiating user stream: {error}'**
  String errorInitiatingUserStream(Object error);

  /// No description provided for @errorLoadingManagerLines.
  ///
  /// In en, this message translates to:
  /// **'Error loading manager lines: {error}'**
  String errorLoadingManagerLines(Object error);

  /// No description provided for @errorLoadingManagerTasks.
  ///
  /// In en, this message translates to:
  /// **'Error loading manager tasks: {error}'**
  String errorLoadingManagerTasks(Object error);

  /// No description provided for @errorStreamingManagerLines.
  ///
  /// In en, this message translates to:
  /// **'Error streaming transmission lines: {error}'**
  String errorStreamingManagerLines(Object error);

  /// No description provided for @errorStreamingManagerTasks.
  ///
  /// In en, this message translates to:
  /// **'Error streaming all tasks: {error}'**
  String errorStreamingManagerTasks(Object error);

  /// No description provided for @errorStreamingSurveyRecords.
  ///
  /// In en, this message translates to:
  /// **'Error streaming all survey records: {error}'**
  String errorStreamingSurveyRecords(Object error);

  /// No description provided for @errorLoadingDashboardData.
  ///
  /// In en, this message translates to:
  /// **'Error loading dashboard data: {error}'**
  String errorLoadingDashboardData(Object error);

  /// No description provided for @errorStreamingLocalSurveyRecords.
  ///
  /// In en, this message translates to:
  /// **'Error streaming local survey records: {error}'**
  String errorStreamingLocalSurveyRecords(Object error);

  /// No description provided for @errorStreamingYourTasks.
  ///
  /// In en, this message translates to:
  /// **'Error streaming your tasks: {error}'**
  String errorStreamingYourTasks(Object error);

  /// No description provided for @errorStreamingYourSurveyRecords.
  ///
  /// In en, this message translates to:
  /// **'Error streaming your survey records: {error}'**
  String errorStreamingYourSurveyRecords(Object error);

  /// No description provided for @errorStreamingAllTasks.
  ///
  /// In en, this message translates to:
  /// **'Error streaming all tasks: {error}'**
  String errorStreamingAllTasks(Object error);

  /// No description provided for @errorStreamingAllSurveyRecords.
  ///
  /// In en, this message translates to:
  /// **'Error streaming all survey records: {error}'**
  String errorStreamingAllSurveyRecords(Object error);

  /// No description provided for @errorStreamingAllUsers.
  ///
  /// In en, this message translates to:
  /// **'Error streaming all users: {error}'**
  String errorStreamingAllUsers(Object error);

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String errorLoadingData(Object error);

  /// No description provided for @towerNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a tower number'**
  String get towerNumberInvalid;

  /// No description provided for @towerNumberPositive.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive number'**
  String get towerNumberPositive;

  /// No description provided for @towerOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Tower number {towerNumber} is outside the assigned range ({range}).'**
  String towerOutOfRange(Object range, Object towerNumber);

  /// No description provided for @towerSpecificRequired.
  ///
  /// In en, this message translates to:
  /// **'You are assigned to survey only Tower {towerNumber}.'**
  String towerSpecificRequired(Object towerNumber);

  /// No description provided for @accuracyLow.
  ///
  /// In en, this message translates to:
  /// **'Accuracy less than {requiredAccuracy}m. Please wait or move to an open area for better GPS signal.'**
  String accuracyLow(Object requiredAccuracy);

  /// No description provided for @towerAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A survey for Tower {towerNumber} at this location ({distance}m from previous record) already exists for Line {lineName}. Please ensure you are at a new tower or update the existing record if this is a re-survey.'**
  String towerAlreadyExists(Object distance, Object lineName, Object towerNumber);

  /// No description provided for @towerTooClose.
  ///
  /// In en, this message translates to:
  /// **'Another surveyed tower on Line {lineName} is too close ({distance}m from Tower {towerNumber}). All DIFFERENT survey points on the same line must be at least {minDistance} meters apart.'**
  String towerTooClose(Object distance, Object lineName, Object minDistance, Object towerNumber);

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in. Cannot save survey.'**
  String get userNotLoggedIn;

  /// No description provided for @errorProcessingDetails.
  ///
  /// In en, this message translates to:
  /// **'Error processing details: {error}'**
  String errorProcessingDetails(Object error);

  /// No description provided for @errorSavingPhotoAndRecordLocally.
  ///
  /// In en, this message translates to:
  /// **'Error saving photo and record locally: {error}'**
  String errorSavingPhotoAndRecordLocally(Object error);

  /// No description provided for @errorSavingLineSurveyDetails.
  ///
  /// In en, this message translates to:
  /// **'Error saving line survey details: {error}'**
  String errorSavingLineSurveyDetails(Object error);

  /// No description provided for @errorLoadingLines.
  ///
  /// In en, this message translates to:
  /// **'Error loading lines: {error}'**
  String errorLoadingLines(Object error);

  /// No description provided for @errorInitializingLineStream.
  ///
  /// In en, this message translates to:
  /// **'Error initializing line stream: {error}'**
  String errorInitializingLineStream(Object error);

  /// No description provided for @invalidTowerNumberInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid \"From\" tower number. Must be a whole number.'**
  String get invalidTowerNumberInput;

  /// No description provided for @invalidToTowerNumberInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid \"To\" tower number. Must be a whole number.'**
  String get invalidToTowerNumberInput;

  /// No description provided for @selectWorkerError.
  ///
  /// In en, this message translates to:
  /// **'Please select a worker.'**
  String get selectWorkerError;

  /// No description provided for @selectLineError.
  ///
  /// In en, this message translates to:
  /// **'Please select a line.'**
  String get selectLineError;

  /// No description provided for @selectDueDateError.
  ///
  /// In en, this message translates to:
  /// **'Please select a due date.'**
  String get selectDueDateError;

  /// No description provided for @allTowersRequiresLine.
  ///
  /// In en, this message translates to:
  /// **'\"All\" requires a selected line with defined towers.'**
  String get allTowersRequiresLine;

  /// No description provided for @allTowers.
  ///
  /// In en, this message translates to:
  /// **'All Towers'**
  String get allTowers;

  /// No description provided for @surveyEntry.
  ///
  /// In en, this message translates to:
  /// **'Survey Entry'**
  String get surveyEntry;

  /// No description provided for @moveToOpenArea.
  ///
  /// In en, this message translates to:
  /// **'Move to an open area.'**
  String get moveToOpenArea;

  /// No description provided for @couldNotGetLocationWithinSeconds.
  ///
  /// In en, this message translates to:
  /// **'Could not get any location within {seconds} seconds. Please try again.'**
  String couldNotGetLocationWithinSeconds(Object seconds);

  /// No description provided for @locationAcquired.
  ///
  /// In en, this message translates to:
  /// **'Location acquired with best available accuracy: {accuracy}m.'**
  String locationAcquired(Object accuracy);

  /// No description provided for @unexpectedErrorStartingLocation.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while starting location: {error}'**
  String unexpectedErrorStartingLocation(Object error);

  /// No description provided for @timeoutInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Timeout in {seconds}s'**
  String timeoutInSeconds(Object seconds);

  /// No description provided for @getCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Get Current Location'**
  String get getCurrentLocation;

  /// No description provided for @fillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields correctly.'**
  String get fillAllRequiredFields;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @backfillingRequired.
  ///
  /// In en, this message translates to:
  /// **'Backfilling Required'**
  String get backfillingRequired;

  /// No description provided for @revetmentWallRequired.
  ///
  /// In en, this message translates to:
  /// **'Revetment Wall Required'**
  String get revetmentWallRequired;

  /// No description provided for @excavationOfSoilRequired.
  ///
  /// In en, this message translates to:
  /// **'Excavation Of Soil Required'**
  String get excavationOfSoilRequired;

  /// No description provided for @rusted.
  ///
  /// In en, this message translates to:
  /// **'Rusted'**
  String get rusted;

  /// No description provided for @bent.
  ///
  /// In en, this message translates to:
  /// **'Bent'**
  String get bent;

  /// No description provided for @hanging.
  ///
  /// In en, this message translates to:
  /// **'Hanging'**
  String get hanging;

  /// No description provided for @damaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get damaged;

  /// No description provided for @cracked.
  ///
  /// In en, this message translates to:
  /// **'Cracked'**
  String get cracked;

  /// No description provided for @broken.
  ///
  /// In en, this message translates to:
  /// **'Broken'**
  String get broken;

  /// No description provided for @flashover.
  ///
  /// In en, this message translates to:
  /// **'Flashover'**
  String get flashover;

  /// No description provided for @dirty.
  ///
  /// In en, this message translates to:
  /// **'Dirty'**
  String get dirty;

  /// No description provided for @loose.
  ///
  /// In en, this message translates to:
  /// **'Loose'**
  String get loose;

  /// No description provided for @boltMissing.
  ///
  /// In en, this message translates to:
  /// **'Bolt Missing'**
  String get boltMissing;

  /// No description provided for @spacersMissing.
  ///
  /// In en, this message translates to:
  /// **'Spacers Missing'**
  String get spacersMissing;

  /// No description provided for @corroded.
  ///
  /// In en, this message translates to:
  /// **'Corroded'**
  String get corroded;

  /// No description provided for @faded.
  ///
  /// In en, this message translates to:
  /// **'Faded'**
  String get faded;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @leaking.
  ///
  /// In en, this message translates to:
  /// **'Leaking'**
  String get leaking;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @trimmingRequired.
  ///
  /// In en, this message translates to:
  /// **'Trimming Required'**
  String get trimmingRequired;

  /// No description provided for @loppingRequired.
  ///
  /// In en, this message translates to:
  /// **'Lopping Required'**
  String get loppingRequired;

  /// No description provided for @cuttingRequired.
  ///
  /// In en, this message translates to:
  /// **'Cutting Required'**
  String get cuttingRequired;

  /// No description provided for @minor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get minor;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @severe.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severe;

  /// No description provided for @intact.
  ///
  /// In en, this message translates to:
  /// **'Intact'**
  String get intact;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not Applicable'**
  String get notApplicable;

  /// No description provided for @taskAndAssociatedRecordsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task and associated local records deleted successfully!'**
  String get taskAndAssociatedRecordsDeleted;

  /// No description provided for @taskStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task status updated!'**
  String get taskStatusUpdated;

  /// No description provided for @errorUpdatingTask.
  ///
  /// In en, this message translates to:
  /// **'Error updating task: {error}'**
  String errorUpdatingTask(Object error);

  /// No description provided for @errorUploadingUnsyncedRecords.
  ///
  /// In en, this message translates to:
  /// **'Error uploading unsynced records: {error}'**
  String errorUploadingUnsyncedRecords(Object error);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {displayName} ({role})!'**
  String welcomeUser(Object displayName, Object role);

  /// No description provided for @toPatrol.
  ///
  /// In en, this message translates to:
  /// **'to patrol'**
  String get toPatrol;

  /// No description provided for @yourSurveyLogForThisTask.
  ///
  /// In en, this message translates to:
  /// **'Your Survey Log for this Task:'**
  String get yourSurveyLogForThisTask;

  /// No description provided for @noSurveysRecordedForThisTask.
  ///
  /// In en, this message translates to:
  /// **'No surveys recorded for this task yet.'**
  String get noSurveysRecordedForThisTask;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// No description provided for @recheckingAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'Re-checking account status...'**
  String get recheckingAccountStatus;

  /// No description provided for @errorLoadingLineRecords.
  ///
  /// In en, this message translates to:
  /// **'Error loading line records: {error}'**
  String errorLoadingLineRecords(Object error);

  /// No description provided for @nationalHighway.
  ///
  /// In en, this message translates to:
  /// **'National Highway'**
  String get nationalHighway;

  /// No description provided for @stateHighway.
  ///
  /// In en, this message translates to:
  /// **'State Highway'**
  String get stateHighway;

  /// No description provided for @chakkRoad.
  ///
  /// In en, this message translates to:
  /// **'Chakk road'**
  String get chakkRoad;

  /// No description provided for @overBridge.
  ///
  /// In en, this message translates to:
  /// **'Over Bridge'**
  String get overBridge;

  /// No description provided for @underpass.
  ///
  /// In en, this message translates to:
  /// **'Underpass'**
  String get underpass;

  /// No description provided for @voltage400kV.
  ///
  /// In en, this message translates to:
  /// **'400kV'**
  String get voltage400kV;

  /// No description provided for @voltage220kV.
  ///
  /// In en, this message translates to:
  /// **'220kV'**
  String get voltage220kV;

  /// No description provided for @voltage132kV.
  ///
  /// In en, this message translates to:
  /// **'132kV'**
  String get voltage132kV;

  /// No description provided for @voltage33kV.
  ///
  /// In en, this message translates to:
  /// **'33kV'**
  String get voltage33kV;

  /// No description provided for @voltage11kV.
  ///
  /// In en, this message translates to:
  /// **'11kV'**
  String get voltage11kV;

  /// No description provided for @privateTubeWell.
  ///
  /// In en, this message translates to:
  /// **'Private Tube Well'**
  String get privateTubeWell;

  /// No description provided for @notOkay.
  ///
  /// In en, this message translates to:
  /// **'NOT OKAY'**
  String get notOkay;

  /// No description provided for @unassignedRole.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassignedRole;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @patrollingDetails.
  ///
  /// In en, this message translates to:
  /// **'Patrolling Details'**
  String get patrollingDetails;

  /// No description provided for @switchToHindi.
  ///
  /// In en, this message translates to:
  /// **'Switch to Hindi'**
  String get switchToHindi;

  /// No description provided for @switchToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Switch to English'**
  String get switchToEnglish;

  /// No description provided for @errorDeletingTask.
  ///
  /// In en, this message translates to:
  /// **'Error deleting task: {error}'**
  String errorDeletingTask(Object error);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
