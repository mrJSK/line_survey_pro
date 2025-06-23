// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'लाइन सर्वे प्रो';

  @override
  String get welcomeMessage => 'लाइन सर्वे प्रो में आपका स्वागत है!';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signInWithGoogle => 'गूगल से साइन इन करें';

  @override
  String get signInPrompt => 'कृपया ऐप का उपयोग जारी रखने के लिए साइन इन करें।';

  @override
  String get surveyDashboard => 'सर्वेक्षण डैशबोर्ड';

  @override
  String get exportRecords => 'रिकॉर्ड निर्यात करें';

  @override
  String get realtimeTasks => 'वास्तविक समय कार्य';

  @override
  String get info => 'जानकारी';

  @override
  String get userManagement => 'उपयोगकर्ता प्रबंधन';

  @override
  String get manageTransmissionLines => 'ट्रांसमिशन लाइनें प्रबंधित करें';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get accountPendingApproval => 'खाता अनुमोदन लंबित है';

  @override
  String get awaitingApprovalMessage => 'आपका खाता एक प्रशासक से अनुमोदन की प्रतीक्षा कर रहा है। एक बार अनुमोदित होने के बाद, आपको ऐप सुविधाओं तक पूर्ण पहुंच प्राप्त होगी।';

  @override
  String get accountRejected => 'खाता अस्वीकृत';

  @override
  String get rejectedMessage => 'दुर्भाग्य से, आपका खाता एक प्रशासक द्वारा अस्वीकृत कर दिया गया है। अधिक जानकारी के लिए कृपया सहायता से संपर्क करें।';

  @override
  String get recheckStatus => 'स्थिति पुनः जांचें (साइन आउट की आवश्यकता है)';

  @override
  String get noInternetTitle => 'क्षमा करें! कोई इंटरनेट कनेक्शन नहीं है';

  @override
  String get noInternetMessage => 'ऐसा लगता है कि आप ऑफ़लाइन हैं। कृपया अपनी नेटवर्क सेटिंग्स जांचें और पुनः प्रयास करें।';

  @override
  String get tryAgain => 'पुनः प्रयास करें';

  @override
  String get yourAssignedTasks => 'आपके असाइन किए गए कार्य:';

  @override
  String get allTasks => 'सभी कार्य:';

  @override
  String get assignNewTask => 'नया कार्य असाइन करें';

  @override
  String get uploadUnsyncedDetails => 'असिंक्रनाइज़ किए गए विवरण अपलोड करें';

  @override
  String get noTasksAssigned => 'अभी तक आपको कोई कार्य असाइन नहीं किया गया है।';

  @override
  String get noTasksAvailable => 'कोई कार्य उपलब्ध नहीं है।';

  @override
  String get line => 'लाइन';

  @override
  String get tower => 'टॉवर';

  @override
  String get status => 'स्थिति';

  @override
  String get patrolledStatus => 'गश्त की गई';

  @override
  String get inProgressUploadedStatus => 'प्रगति में (अपलोड किया गया)';

  @override
  String get inProgressLocalStatus => 'प्रगति में (स्थानीय)';

  @override
  String get pendingStatus => 'लंबित';

  @override
  String get continueSurvey => 'इस कार्य के लिए सर्वेक्षण जारी रखें';

  @override
  String get task => 'कार्य';

  @override
  String get towers => 'टॉवर';

  @override
  String get patrolledCount => 'गश्त की गई';

  @override
  String get uploadedCount => 'अपलोड किया गया';

  @override
  String get due => 'देय';

  @override
  String get taskOptions => 'कार्य विकल्प';

  @override
  String get editTask => 'कार्य संपादित करें';

  @override
  String get deleteTask => 'कार्य मिटाएँ';

  @override
  String get confirmDeletion => 'पुष्टि करें हटाना';

  @override
  String deleteTaskConfirmation(Object lineName, Object towerRange) {
    return 'क्या आप लाइन: $lineName, टावरों: $towerRange के लिए कार्य को हटाना चाहते हैं? इससे इस कार्य के लिए ऐप में किसी भी संबंधित सर्वेक्षण प्रगति को भी हटा दिया जाएगा। यह कार्रवाई पूर्ववत नहीं की जा सकती।';
  }

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String uploadSuccess(Object count) {
    return '$count रिकॉर्ड विवरण सफलतापूर्वक अपलोड किए गए!';
  }

  @override
  String get noUnsyncedRecords => 'अपलोड करने के लिए कोई असिंक्रनाइज़ किए गए रिकॉर्ड नहीं हैं।';

  @override
  String get cameraPermissionDenied => 'कैमरा अनुमति अस्वीकृत।';

  @override
  String errorInitializingCamera(Object error) {
    return 'कैमरा प्रारंभ करने में त्रुटि: $error';
  }

  @override
  String get noCamerasFound => 'कोई कैमरा नहीं मिला।';

  @override
  String errorCapturingPicture(Object error) {
    return 'चित्र कैप्चर करने में त्रुटि: $error';
  }

  @override
  String get noPhotoCaptured => 'सहेजने के लिए कोई फोटो कैप्चर नहीं किया गया।';

  @override
  String get photoSavedLocally => 'फोटो और रिकॉर्ड स्थानीय रूप से सहेजा गया!';

  @override
  String get cameraCaptureCancelled => 'कैमरा कैप्चर रद्द या विफल हो गया। डेटा सहेजा नहीं गया।';

  @override
  String get takePhoto => 'फोटो लें';

  @override
  String get retake => 'पुनः लें';

  @override
  String get save => 'सहेजें';

  @override
  String get saving => 'सहेजा जा रहा है...';

  @override
  String get back => 'वापस';

  @override
  String lineDetails(Object lineName) {
    return 'लाइन: $lineName';
  }

  @override
  String towerDetails(Object towerNumber) {
    return 'टॉवर: $towerNumber';
  }

  @override
  String get lat => 'अक्षांश';

  @override
  String get lon => 'देशांतर';

  @override
  String get time => 'समय';

  @override
  String get reviewPhoto => 'फोटो की समीक्षा करें';

  @override
  String get imageNotFound => 'छवि नहीं मिली या दूषित है।';

  @override
  String get locationPermissionDenied => 'स्थान अनुमति अस्वीकृत।';

  @override
  String get locationServiceDisabled => 'स्थान सेवाएं अक्षम हैं। जीपीएस निर्देशांक प्राप्त करने के लिए कृपया उन्हें सक्षम करें।';

  @override
  String get locationPermissionPermanentlyDenied => 'स्थान अनुमतियाँ स्थायी रूप से अस्वीकृत हैं। कृपया उन्हें अपनी डिवाइस की ऐप सेटिंग्स से सक्षम करें।';

  @override
  String errorGettingLocation(Object error) {
    return 'स्थान स्ट्रीम प्राप्त करने में त्रुटि: $error';
  }

  @override
  String get fetchingLocation => 'स्थान प्राप्त कर रहा है';

  @override
  String get current => 'वर्तमान';

  @override
  String requiredAccuracyAchieved(Object accuracy, Object requiredAccuracy) {
    return 'प्राप्त: $accuracyमी (आवश्यक < $requiredAccuracyमी)';
  }

  @override
  String currentAccuracy(Object accuracy, Object requiredAccuracy) {
    return 'वर्तमान: $accuracyमी (आवश्यक < $requiredAccuracyमी)';
  }

  @override
  String timeoutReached(Object message) {
    return 'समय समाप्त। $message';
  }

  @override
  String get noLocationObtained => 'कोई स्थान प्राप्त नहीं हुआ।';

  @override
  String get overallProgress => 'समग्र सर्वेक्षण प्रगति';

  @override
  String get totalManagers => 'कुल प्रबंधक:';

  @override
  String get totalWorkers => 'कुल कार्यकर्ता:';

  @override
  String get totalLines => 'कुल लाइनें:';

  @override
  String get totalTowersInSystem => 'सिस्टम में कुल टावर:';

  @override
  String get pendingApprovals => 'लंबित अनुमोदन:';

  @override
  String get latestPendingRequests => 'नवीनतम लंबित अनुरोध';

  @override
  String get noPendingRequests => 'कोई लंबित अनुरोध नहीं।';

  @override
  String get managersAndAssignments => 'प्रबंधक और उनके असाइनमेंट';

  @override
  String get noManagersFound => 'कोई प्रबंधक नहीं मिला।';

  @override
  String get progressByWorker => 'कार्यकर्ता द्वारा प्रगति:';

  @override
  String get noWorkerProfilesFound => 'कोई कार्यकर्ता प्रोफ़ाइल नहीं मिली या ट्रैक करने के लिए कार्य असाइन नहीं किए गए।';

  @override
  String get linesAssigned => 'असाइन की गई लाइनें';

  @override
  String get linesPatrolled => 'गश्त की गई लाइनें';

  @override
  String get linesWorkingPending => 'कार्यरत/लंबित लाइनें';

  @override
  String get linesUnderSupervision => 'आपकी निगरानी में लाइनें:';

  @override
  String get noLinesOrTasksAvailable => 'आपकी भूमिका के लिए आपके असाइन किए गए क्षेत्रों में कोई लाइन या कार्य उपलब्ध नहीं है।';

  @override
  String get assignedTaskDetails => 'असाइन किए गए कार्य विवरण:';

  @override
  String get lineNameField => 'लाइन का नाम';

  @override
  String get assignedTowers => 'असाइन किए गए टावर';

  @override
  String get dueDateField => 'देय तिथि';

  @override
  String get addNewSurveyRecord => 'नया सर्वेक्षण रिकॉर्ड जोड़ें';

  @override
  String get towerNumberField => 'टॉवर संख्या';

  @override
  String get enterTowerNumber => 'टॉवर संख्या दर्ज करें';

  @override
  String get gpsCoordinates => 'वर्तमान जीपीएस निर्देशांक:';

  @override
  String get refreshLocation => 'स्थान रीफ्रेश करें';

  @override
  String get continueToPatrollingDetails => 'गश्त विवरण पर जारी रखें';

  @override
  String get gettingLocation => 'स्थान प्राप्त कर रहा है...';

  @override
  String get requiredAccuracyNotMet => 'आवश्यक सटीकता पूरी नहीं हुई';

  @override
  String get soilCondition => 'मिट्टी की स्थिति';

  @override
  String get selectSoilCondition => 'मिट्टी की स्थिति चुनें';

  @override
  String get stubCopingLeg => 'स्टब / कॉपिंग लेग';

  @override
  String get selectStubCopingLegStatus => 'स्टब/कॉपिंग लेग स्थिति चुनें';

  @override
  String get earthing => 'अर्थिंग';

  @override
  String get selectEarthingStatus => 'अर्थिंग स्थिति चुनें';

  @override
  String get conditionOfTowerParts => 'टॉवर भागों की स्थिति';

  @override
  String get selectConditionOfTowerParts => 'टॉवर भागों की स्थिति चुनें';

  @override
  String get statusOfInsulator => 'इन्सुलेटर की स्थिति';

  @override
  String get selectInsulatorStatus => 'इन्सुलेटर स्थिति चुनें';

  @override
  String get jumperStatus => 'जम्पर स्थिति';

  @override
  String get selectJumperStatus => 'जम्पर स्थिति चुनें';

  @override
  String get hotSpots => 'हॉट स्पॉट';

  @override
  String get selectHotSpotStatus => 'हॉट स्पॉट स्थिति चुनें';

  @override
  String get numberPlate => 'नंबर प्लेट';

  @override
  String get selectNumberPlateStatus => 'नंबर प्लेट स्थिति चुनें';

  @override
  String get dangerBoard => 'खतरा बोर्ड';

  @override
  String get selectDangerBoardStatus => 'खतरा बोर्ड स्थिति चुनें';

  @override
  String get phasePlate => 'फेज प्लेट';

  @override
  String get selectPhasePlateStatus => 'फेज प्लेट स्थिति चुनें';

  @override
  String get nutAndBoltCondition => 'नट और बोल्ट की स्थिति';

  @override
  String get selectNutAndBoltCondition => 'नट और बोल्ट की स्थिति चुनें';

  @override
  String get antiClimbingDevice => 'एंटी क्लाइंबिंग डिवाइस';

  @override
  String get selectAntiClimbingDeviceStatus => 'एंटी-क्लाइंबिंग डिवाइस स्थिति चुनें';

  @override
  String get wildGrowth => 'जंगली विकास';

  @override
  String get selectWildGrowthStatus => 'जंगली विकास स्थिति चुनें';

  @override
  String get birdGuard => 'बर्ड गार्ड';

  @override
  String get selectBirdGuardStatus => 'बर्ड गार्ड स्थिति चुनें';

  @override
  String get birdNest => 'पक्षी का घोंसला';

  @override
  String get selectBirdNestStatus => 'पक्षी घोंसला स्थिति चुनें';

  @override
  String get archingHorn => 'आर्किंग हॉर्न';

  @override
  String get selectArchingHornStatus => 'आर्किंग हॉर्न स्थिति चुनें';

  @override
  String get coronaRing => 'कोरोना रिंग';

  @override
  String get selectCoronaRingStatus => 'कोरोना रिंग स्थिति चुनें';

  @override
  String get insulatorType => 'इन्सुलेटर प्रकार';

  @override
  String get selectInsulatorType => 'इन्सुलेटर प्रकार चुनें';

  @override
  String get opgwJointBox => 'ओपीजीडब्ल्यू जॉइंट बॉक्स';

  @override
  String get selectOpgwJointBoxStatus => 'ओपीजीडब्ल्यू जॉइंट बॉक्स स्थिति चुनें';

  @override
  String get missingTowerParts => 'गुम हुए टॉवर पार्ट्स';

  @override
  String get continueToLineSurvey => 'लाइन सर्वेक्षण पर जारी रखें';

  @override
  String enterDetailedObservations(Object lineName, Object towerNumber) {
    return 'लाइन $lineName पर टॉवर $towerNumber के लिए विस्तृत गश्त अवलोकन दर्ज करें।';
  }

  @override
  String get generalNotes => 'सामान्य अवलोकन/नोट्स';

  @override
  String get building => 'भवन';

  @override
  String get tree => 'वृक्ष';

  @override
  String get numberOfTrees => 'वृक्षों की संख्या';

  @override
  String get conditionOfOpgw => 'ओपीजीडब्ल्यू की स्थिति';

  @override
  String get conditionOfEarthWire => 'अर्थ वायर की स्थिति';

  @override
  String get conditionOfConductor => 'कंडक्टर की स्थिति';

  @override
  String get midSpanJoint => 'मिड स्पैन जॉइंट';

  @override
  String get newConstruction => 'नया निर्माण';

  @override
  String get objectOnConductor => 'कंडक्टर पर वस्तु';

  @override
  String get objectOnEarthwire => 'अर्थवायर पर वस्तु';

  @override
  String get spacers => 'स्पेसर्स';

  @override
  String get vibrationDamper => 'वाइब्रेशन डैम्पर';

  @override
  String get roadCrossing => 'सड़क क्रॉसिंग';

  @override
  String get riverCrossing => 'नदी क्रॉसिंग';

  @override
  String get electricalLine => 'विद्युत लाइन';

  @override
  String get railwayCrossing => 'रेलवे क्रॉसिंग';

  @override
  String get saveDetailsAndGoToCamera => 'विवरण सहेजें और कैमरे पर जाएं';

  @override
  String get lineSurveyDetails => 'लाइन सर्वेक्षण विवरण';

  @override
  String get lineSurveyDetailsSaved => 'लाइन सर्वेक्षण विवरण सफलतापूर्वक सहेजे गए!';

  @override
  String get selectBottomConductor => 'तल कंडक्टर चुनें';

  @override
  String get selectTopConductor => 'शीर्ष कंडक्टर चुनें';

  @override
  String get noRecordsToExport => 'निर्यात करने के लिए कोई रिकॉर्ड नहीं।';

  @override
  String get allRecordsExported => 'सभी रिकॉर्ड CSV में निर्यात किए गए और शेयर डायलॉग दिखाया गया।';

  @override
  String get failedToGenerateCsv => 'CSV फ़ाइल बनाने में विफल।';

  @override
  String errorExportingCsv(Object error) {
    return 'CSV निर्यात करने में त्रुटि: $error';
  }

  @override
  String get selectImagesToShare => 'साझा करने के लिए छवियां चुनें';

  @override
  String get noImagesAvailable => 'साझा करने के लिए स्थानीय रूप से कोई छवियां उपलब्ध नहीं हैं।';

  @override
  String get selectLine => 'लाइन चुनें';

  @override
  String get searchTowerNumber => 'टॉवर संख्या खोजें';

  @override
  String get noTowersFound => 'खोज से मेल खाने वाले कोई टॉवर नहीं मिले।';

  @override
  String get noImagesForLine => 'इस लाइन के लिए स्थानीय रूप से कोई छवियां उपलब्ध नहीं हैं।';

  @override
  String shareSelected(Object count) {
    return 'चयनित साझा करें ($count)';
  }

  @override
  String get noValidImagesForShare => 'चयनित रिकॉर्ड साझा करने के लिए ओवरले के साथ कोई वैध छवियां नहीं मिलीं।';

  @override
  String get selectedImagesShared => 'चयनित छवियां और विवरण साझा किए गए।';

  @override
  String errorSharingImages(Object error) {
    return 'छवियां साझा करने में त्रुटि: $error';
  }

  @override
  String deleteRecordConfirmation(Object lineName, Object towerNumber) {
    return 'क्या आप लाइन $lineName पर टॉवर $towerNumber के लिए रिकॉर्ड हटाना चाहते हैं? यह कार्रवाई पूर्ववत नहीं की जा सकती।';
  }

  @override
  String recordDeletedSuccessfully(Object towerNumber) {
    return 'टॉवर $towerNumber के लिए रिकॉर्ड सफलतापूर्वक हटा दिया गया।';
  }

  @override
  String errorDeletingRecord(Object error) {
    return 'रिकॉर्ड हटाने में त्रुटि: $error';
  }

  @override
  String get imageNotAvailableLocally => 'यह छवि इस रिकॉर्ड के लिए स्थानीय रूप से उपलब्ध नहीं है। केवल विवरण सिंक्रनाइज़ किए गए हैं।';

  @override
  String get closeMenu => 'मेनू बंद करें';

  @override
  String get actions => 'कार्य';

  @override
  String get shareImages => 'छवियां साझा करें';

  @override
  String get exportCsv => 'CSV निर्यात करें';

  @override
  String get noRecordsFoundConductSurvey => 'कोई सर्वेक्षण रिकॉर्ड नहीं मिला। पहले एक सर्वेक्षण करें और उसे सहेजें/अपलोड करें!';

  @override
  String get localRecordsPresentUpload => 'आपके पास स्थानीय रिकॉर्ड हैं। पूर्ण सिंक के लिए उन्हें क्लाउड पर अपलोड करें!';

  @override
  String get viewPhoto => 'फोटो देखें';

  @override
  String get assignToWorker => 'कार्यकर्ता को असाइन करें';

  @override
  String get selectWorker => 'एक कार्यकर्ता चुनें';

  @override
  String get selectTransmissionLine => 'एक ट्रांसमिशन लाइन चुनें';

  @override
  String get fromTowerNumber => 'टॉवर संख्या से (उदाहरण के लिए, 10)';

  @override
  String get toTowerNumber => 'टॉवर संख्या तक (उदाहरण के लिए, 30, एकल टॉवर के लिए खाली छोड़ें)';

  @override
  String get selectDueDate => 'देय तिथि चुनें';

  @override
  String get assignTask => 'कार्य असाइन करें';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get invalidTowerRange => 'अवैध टॉवर सीमा। कृपया से/तक मान जांचें।';

  @override
  String get numberOfTowersZero => 'गश्त करने के लिए टावरों की संख्या शून्य नहीं हो सकती। यदि \"सभी\" चुना गया है तो सीमा या लाइन के कुल टावर जांचें।';

  @override
  String towersExceedLineTotal(Object assigned, Object total) {
    return 'इस लाइन को असाइन किए गए टावरों की कुल संख्या ($assigned) लाइन के कुल टावरों ($total) से अधिक है। कृपया सीमा समायोजित करें।';
  }

  @override
  String conflictOverlappingTask(Object assignedTo, Object lineName, Object status, Object towerRange) {
    return 'टकराव: लाइन: $lineName, टावरों: $towerRange (असाइन किए गए: $assignedTo, स्थिति: $status) के लिए एक कार्य इस असाइनमेंट के साथ ओवरलैप होता है।';
  }

  @override
  String get taskAssignedSuccessfully => 'कार्य सफलतापूर्वक असाइन किया गया!';

  @override
  String get taskUpdatedSuccessfully => 'कार्य सफलतापूर्वक अपडेट किया गया!';

  @override
  String errorSavingTask(Object error) {
    return 'कार्य सहेजने में त्रुटि: $error';
  }

  @override
  String cannotAssignEditTasks(Object action) {
    return 'इस समय कार्य $action नहीं कर सकते।';
  }

  @override
  String get possibleReasons => 'संभावित कारण: \n- आपका खाता अनुमोदित नहीं है या आपके पास प्रबंधक/प्रशासक भूमिका नहीं है। \n- कोई कार्यकर्ता खाते नहीं मिले। \n- कोई ट्रांसमिशन लाइन लोड नहीं हुई (या यदि आप प्रबंधक हैं तो आपको असाइन की गई)। (ड्रॉअर में \"लाइनें प्रबंधित करें\" से लाइनें जोड़ें/प्रबंधित करें)';

  @override
  String get retryLoadingData => 'डेटा पुनः लोड करें';

  @override
  String get manageTransmissionLinesTitle => 'ट्रांसमिशन लाइनें प्रबंधित करें';

  @override
  String get addNewTransmissionLine => 'नई ट्रांसमिशन लाइन जोड़ें';

  @override
  String get editTransmissionLine => 'ट्रांसमिशन लाइन संपादित करें';

  @override
  String get voltageLevel => 'वोल्टेज स्तर';

  @override
  String get selectVoltageLevel => 'कृपया एक वोल्टेज स्तर चुनें';

  @override
  String get lineBaseName => 'लाइन आधार नाम (उदाहरण के लिए, शामली अलीगढ़)';

  @override
  String get enterLineName => 'कृपया एक लाइन नाम दर्ज करें';

  @override
  String get towerRangeFromLabel => 'टॉवर रेंज से';

  @override
  String get enterStartTower => 'प्रारंभिक टॉवर दर्ज करें';

  @override
  String get towerRangeToLabel => 'टॉवर रेंज तक';

  @override
  String get enterEndTower => 'अंतिम टॉवर दर्ज करें';

  @override
  String get validPositiveNumberRequired => 'मान्य धनात्मक संख्या आवश्यक है';

  @override
  String get towerRangeValuesPositive => 'टॉवर रेंज मान धनात्मक होने चाहिए।';

  @override
  String get towerRangeFromGreaterThanTo => 'टॉवर रेंज \"से\" \"तक\" से अधिक नहीं हो सकती।';

  @override
  String get totalTowersLabel => 'कुल टावर';

  @override
  String get previewLabel => 'पूर्वावलोकन';

  @override
  String get addLine => 'लाइन जोड़ें';

  @override
  String get updateLine => 'लाइन अपडेट करें';

  @override
  String get cancelEdit => 'संपादन रद्द करें';

  @override
  String get transmissionLineAddedSuccessfully => 'ट्रांसमिशन लाइन सफलतापूर्वक जोड़ी गई!';

  @override
  String get transmissionLineUpdatedSuccessfully => 'ट्रांसमिशन लाइन सफलतापूर्वक अपडेट की गई!';

  @override
  String errorSavingLine(Object error) {
    return 'लाइन सहेजने में त्रुटि: $error';
  }

  @override
  String get existingTransmissionLines => 'मौजूदा ट्रांसमिशन लाइनें';

  @override
  String get noTransmissionLinesAdded => 'अभी तक कोई ट्रांसमिशन लाइन नहीं जोड़ी गई है।';

  @override
  String get transmissionLineDeletedSuccessfully => 'ट्रांसमिशन लाइन सफलतापूर्वक हटाई गई!';

  @override
  String errorDeletingLine(Object error) {
    return 'लाइन हटाने में त्रुटि: $error';
  }

  @override
  String get confirmDeletionText => 'क्या आप इस ट्रांसमिशन लाइन को हटाना चाहते हैं? यह कार्रवाई पूर्ववत नहीं की जा सकती।';

  @override
  String get edit => 'संपादित करें';

  @override
  String get deleteOption => 'मिटाएँ';

  @override
  String assignLinesToManager(Object managerName) {
    return 'लाइनें असाइन करें $managerName को';
  }

  @override
  String get searchLines => 'लाइनें खोजें';

  @override
  String get noLinesAvailableToAssign => 'असाइन करने के लिए कोई लाइन उपलब्ध नहीं है।';

  @override
  String get noLinesFoundSearch => 'आपकी खोज से मेल खाने वाली कोई लाइन नहीं मिली।';

  @override
  String get saveAssignments => 'सहेजें';

  @override
  String get cancelAssignments => 'रद्द करें';

  @override
  String get noChangesToSave => 'सहेजने के लिए कोई परिवर्तन नहीं।';

  @override
  String linesAssignedSuccessfully(Object managerName) {
    return 'लाइनें $managerName को सफलतापूर्वक असाइन की गईं!';
  }

  @override
  String failedToUpdateAssignedLines(Object error) {
    return 'असाइन की गई लाइनें अपडेट करने में विफल: $error';
  }

  @override
  String get userManagementTitle => 'उपयोगकर्ता प्रबंधन';

  @override
  String get searchUsers => 'उपयोगकर्ता खोजें';

  @override
  String get searchByNameOrEmail => 'नाम या ईमेल द्वारा खोजें';

  @override
  String get noUserProfilesFound => 'सिस्टम में कोई उपयोगकर्ता प्रोफ़ाइल नहीं मिली।';

  @override
  String get noUsersFoundMatchingFilters => 'वर्तमान फ़िल्टर/खोज से मेल खाने वाले कोई उपयोगकर्ता नहीं मिले।';

  @override
  String get roleLabel => 'भूमिका';

  @override
  String get statusFilterLabel => 'स्थिति';

  @override
  String get manage => 'प्रबंधित करें';

  @override
  String get assignLinesButton => 'लाइनें असाइन करें';

  @override
  String get deleteProfileButton => 'प्रोफ़ाइल मिटाएँ';

  @override
  String get confirmRejectionDeletion => 'अस्वीकृति और विलोपन की पुष्टि करें';

  @override
  String rejectDeleteConfirmation(Object userEmail) {
    return 'क्या आप इस उपयोगकर्ता की प्रोफ़ाइल ($userEmail) को अस्वीकृत और हटाना चाहते हैं? यह कार्रवाई अपरिवर्तनीय है।';
  }

  @override
  String get userProfileRejectedDeletedSuccessfully => 'उपयोगकर्ता प्रोफ़ाइल सफलतापूर्वक अस्वीकृत और हटा दी गई!';

  @override
  String get rejectionDeletionCancelled => 'अस्वीकृति/विलोपन रद्द कर दिया गया।';

  @override
  String userStatusUpdated(Object newStatus) {
    return 'उपयोगकर्ता की स्थिति $newStatus पर अपडेट की गई।';
  }

  @override
  String failedToUpdateUser(Object error) {
    return 'उपयोगकर्ता को अपडेट करने में विफल: $error';
  }

  @override
  String userProfileDeleted(Object userEmail) {
    return 'उपयोगकर्ता प्रोफ़ाइल $userEmail हटा दी गई।';
  }

  @override
  String managerEmail(Object email) {
    return 'ईमेल: $email';
  }

  @override
  String get managedLines => 'प्रबंधित लाइनें:';

  @override
  String get noManagedLines => 'इस प्रबंधक को कोई ट्रांसमिशन लाइन प्रबंधित करने के लिए असाइन नहीं किया गया है।';

  @override
  String totalTowersManaged(Object count) {
    return 'कुल टावर प्रबंधित: $count';
  }

  @override
  String tasksAssignedBy(Object managerName) {
    return '$managerName द्वारा असाइन किए गए कार्य:';
  }

  @override
  String get noAssignedTasksManager => 'इस प्रबंधक ने अभी तक कोई कार्य असाइन नहीं किया है।';

  @override
  String get assignedToUser => 'असाइन किया गया:';

  @override
  String linePatrollingDetailsScreenTitle(Object lineName) {
    return '$lineName विवरण';
  }

  @override
  String get searchTowerNumberOrDetails => 'टॉवर संख्या या विवरण खोजें';

  @override
  String get noSurveyRecordsFoundForLine => 'इस लाइन के लिए कोई सर्वेक्षण रिकॉर्ड नहीं मिला।';

  @override
  String get noRecordsFoundMatchingFiltersLine => 'वर्तमान फ़िल्टर से मेल खाने वाले कोई रिकॉर्ड नहीं मिले।';

  @override
  String get recordId => 'रिकॉर्ड आईडी';

  @override
  String get lineNameDisplay => 'लाइन का नाम';

  @override
  String get taskId => 'कार्य आईडी';

  @override
  String get userId => 'उपयोगकर्ता आईडी';

  @override
  String get latitude => 'अक्षांश';

  @override
  String get longitude => 'देशांतर';

  @override
  String get overallIssueStatus => 'समग्र समस्या स्थिति';

  @override
  String get issueStatus => 'मुद्दा';

  @override
  String get okStatus => 'ठीक है';

  @override
  String get filterRecords => 'रिकॉर्ड फ़िल्टर करें';

  @override
  String get clearFilters => 'फ़िल्टर साफ़ करें';

  @override
  String get accountRoleUnassigned => 'आपकी खाता भूमिका असाइन या पहचानी नहीं गई है।';

  @override
  String get accountRoleExplanation => 'कृपया सुनिश्चित करें कि आपकी भूमिका (कार्यकर्ता, प्रबंधक, या प्रशासक) Firebase कंसोल में एक प्रशासक द्वारा सही ढंग से असाइन की गई है।';

  @override
  String get adminDashboardSummary => 'व्यवस्थापक डैशबोर्ड सारांश';

  @override
  String get totalManagersCount => 'कुल प्रबंधक:';

  @override
  String get totalWorkersCount => 'कुल कार्यकर्ता:';

  @override
  String get totalLinesCount => 'कुल लाइनें:';

  @override
  String get totalTowersInSystemCount => 'सिस्टम में कुल टावर:';

  @override
  String get pendingApprovalsCount => 'लंबित अनुमोदन:';

  @override
  String get latestPendingRequestsTitle => 'नवीनतम लंबित अनुरोध';

  @override
  String get noPendingRequestsTitle => 'कोई लंबित अनुरोध नहीं।';

  @override
  String get managersAssignmentsTitle => 'प्रबंधक और उनके असाइनमेंट';

  @override
  String get noManagersFoundTitle => 'कोई प्रबंधक नहीं मिला।';

  @override
  String get progressByWorkerTitle => 'कार्यकर्ता द्वारा प्रगति:';

  @override
  String get noWorkerProfilesFoundTitle => 'कोई कार्यकर्ता प्रोफ़ाइल नहीं मिली या ट्रैक करने के लिए कार्य असाइन नहीं किए गए।';

  @override
  String linesAssignedManagerCount(Object count) {
    return 'असाइन की गई लाइनें: $count';
  }

  @override
  String totalTowersAssignedManagerCount(Object count) {
    return 'कुल असाइन किए गए टावर: $count';
  }

  @override
  String tasksAssignedByThemCount(Object count) {
    return 'उनके द्वारा असाइन किए गए कार्य: $count';
  }

  @override
  String get viewButton => 'देखें >';

  @override
  String get accountNotApproved => 'आपका खाता अनुमोदित नहीं है।';

  @override
  String get accountApprovalMessage => 'कृपया प्रशासक अनुमोदन की प्रतीक्षा करें या सहायता से संपर्क करें।';

  @override
  String get accountStatusUnknown => 'खाता स्थिति अज्ञात';

  @override
  String get unexpectedAccountStatus => 'एक अप्रत्याशित खाता स्थिति का सामना करना पड़ा। कृपया सहायता से संपर्क करें।';

  @override
  String get unassignedRoleTitle => 'आपकी खाता भूमिका असाइन या पहचानी नहीं गई है।';

  @override
  String get unassignedRoleMessage => 'कृपया सुनिश्चित करें कि आपकी भूमिका (कार्यकर्ता, प्रबंधक, या प्रशासक) Firebase कंसोल में एक प्रशासक द्वारा सही ढंग से असाइन की गई है।';

  @override
  String get surveyProgressOverview => 'समग्र सर्वेक्षण प्रगति';

  @override
  String get patrollingTheFuture => 'भविष्य की गश्त...';

  @override
  String anUnexpectedErrorOccurred(Object error) {
    return 'एक अप्रत्याशित त्रुटि हुई: $error';
  }

  @override
  String get googleSignInCancelled => 'गूगल साइन-इन रद्द कर दिया गया।';

  @override
  String get userProfileNotFound => 'साइन-इन के बाद उपयोगकर्ता प्रोफ़ाइल नहीं मिली। कृपया पुनः प्रयास करें।';

  @override
  String get userNotFoundAfterSignIn => 'साइन-इन के बाद उपयोगकर्ता नहीं मिला।';

  @override
  String get accountExistsWithDifferentCredential => 'एक खाता पहले से ही विभिन्न क्रेडेंशियल्स के साथ मौजूद है।';

  @override
  String get invalidCredential => 'प्रदान की गई क्रेडेंशियल अमान्य है।';

  @override
  String get userDisabled => 'दिए गए क्रेडेंशियल से जुड़ा उपयोगकर्ता अक्षम कर दिया गया है।';

  @override
  String get operationNotAllowed => 'इस परियोजना के लिए गूगल साइन-इन सक्षम नहीं है।';

  @override
  String get networkRequestFailed => 'नेटवर्क त्रुटि हुई। कृपया अपना इंटरनेट कनेक्शन जांचें।';

  @override
  String signInFailed(Object error) {
    return 'साइन-इन विफल: $error';
  }

  @override
  String get noInternetConnection => 'कोई इंटरनेट कनेक्शन नहीं। कृपया कनेक्ट करें और पुनः प्रयास करें।';

  @override
  String errorCheckingConnectivity(Object error) {
    return 'कनेक्टिविटी जांचने में त्रुटि: $error';
  }

  @override
  String get stillNoInternet => 'अभी भी कोई इंटरनेट कनेक्शन नहीं।';

  @override
  String get internetRestored => 'इंटरनेट कनेक्शन बहाल!';

  @override
  String errorLoadingUsers(Object error) {
    return 'उपयोगकर्ता लोड करने में त्रुटि: $error';
  }

  @override
  String errorInitiatingUserStream(Object error) {
    return 'उपयोगकर्ता स्ट्रीम प्रारंभ करने में त्रुटि: $error';
  }

  @override
  String errorLoadingManagerLines(Object error) {
    return 'प्रबंधक लाइनें लोड करने में त्रुटि: $error';
  }

  @override
  String errorLoadingManagerTasks(Object error) {
    return 'प्रबंधक कार्य लोड करने में त्रुटि: $error';
  }

  @override
  String errorStreamingManagerLines(Object error) {
    return 'ट्रांसमिशन लाइनें स्ट्रीम करने में त्रुटि: $error';
  }

  @override
  String errorStreamingManagerTasks(Object error) {
    return 'सभी कार्य स्ट्रीम करने में त्रुटि: $error';
  }

  @override
  String errorStreamingSurveyRecords(Object error) {
    return 'सभी सर्वेक्षण रिकॉर्ड स्ट्रीम करने में त्रुटि: $error';
  }

  @override
  String errorLoadingDashboardData(Object error) {
    return 'डैशबोर्ड डेटा लोड करने में त्रुटि: $error';
  }

  @override
  String errorStreamingLocalSurveyRecords(Object error) {
    return 'स्थानीय सर्वेक्षण रिकॉर्ड स्ट्रीम करने में त्रुटि: $error';
  }

  @override
  String errorStreamingYourTasks(Object error) {
    return 'आपके कार्य स्ट्रीम करने में त्रुटि: $error';
  }

  @override
  String errorStreamingYourSurveyRecords(Object error) {
    return 'आपके सर्वेक्षण रिकॉर्ड स्ट्रीम करने में त्रुटि: $error';
  }

  @override
  String errorStreamingAllTasks(Object error) {
    return 'सभी कार्य स्ट्रीम करने में त्रुटि: $error';
  }

  @override
  String errorStreamingAllSurveyRecords(Object error) {
    return 'सभी सर्वेक्षण रिकॉर्ड स्ट्रीम करने में त्रुटि: $error';
  }

  @override
  String errorStreamingAllUsers(Object error) {
    return 'सभी उपयोगकर्ता स्ट्रीम करने में त्रुटि: $error';
  }

  @override
  String errorLoadingData(Object error) {
    return 'डेटा लोड करने में त्रुटि: $error';
  }

  @override
  String get towerNumberInvalid => 'कृपया एक टॉवर संख्या दर्ज करें';

  @override
  String get towerNumberPositive => 'कृपया एक मान्य धनात्मक संख्या दर्ज करें';

  @override
  String towerOutOfRange(Object range, Object towerNumber) {
    return 'टॉवर संख्या $towerNumber सीमा ($range) से बाहर है।';
  }

  @override
  String towerSpecificRequired(Object towerNumber) {
    return 'आपको केवल टॉवर $towerNumber का सर्वेक्षण करने के लिए असाइन किया गया है।';
  }

  @override
  String accuracyLow(Object requiredAccuracy) {
    return 'सटीकता $requiredAccuracyमी से कम है। कृपया बेहतर जीपीएस सिग्नल के लिए प्रतीक्षा करें या खुले क्षेत्र में जाएं।';
  }

  @override
  String towerAlreadyExists(Object distance, Object lineName, Object towerNumber) {
    return 'लाइन $lineName के लिए टॉवर $towerNumber पर इस स्थान ($distanceमी पिछले रिकॉर्ड से) पर एक सर्वेक्षण पहले से मौजूद है। कृपया सुनिश्चित करें कि आप एक नए टॉवर पर हैं या यदि यह पुनः सर्वेक्षण है तो मौजूदा रिकॉर्ड अपडेट करें।';
  }

  @override
  String towerTooClose(Object distance, Object lineName, Object minDistance, Object towerNumber) {
    return 'लाइन $lineName पर एक और सर्वेक्षण किया गया टॉवर बहुत करीब है ($distanceमी टॉवर $towerNumber से)। एक ही लाइन पर सभी अलग-अलग सर्वेक्षण बिंदु कम से कम $minDistance मीटर अलग होने चाहिए।';
  }

  @override
  String get userNotLoggedIn => 'उपयोगकर्ता लॉग इन नहीं है। सर्वेक्षण सहेजा नहीं जा सकता।';

  @override
  String errorProcessingDetails(Object error) {
    return 'विवरण संसाधित करने में त्रुटि: $error';
  }

  @override
  String errorSavingPhotoAndRecordLocally(Object error) {
    return 'फोटो और रिकॉर्ड स्थानीय रूप से सहेजने में त्रुटि: $error';
  }

  @override
  String errorSavingLineSurveyDetails(Object error) {
    return 'लाइन सर्वेक्षण विवरण सहेजने में त्रुटि: $error';
  }

  @override
  String errorLoadingLines(Object error) {
    return 'लाइनें लोड करने में त्रुटि: $error';
  }

  @override
  String errorInitializingLineStream(Object error) {
    return 'लाइन स्ट्रीम प्रारंभ करने में त्रुटि: $error';
  }

  @override
  String get invalidTowerNumberInput => 'अवैध \"से\" टॉवर संख्या। एक पूर्ण संख्या होनी चाहिए।';

  @override
  String get invalidToTowerNumberInput => 'अवैध \"तक\" टॉवर संख्या। एक पूर्ण संख्या होनी चाहिए।';

  @override
  String get selectWorkerError => 'कृपया एक कार्यकर्ता चुनें।';

  @override
  String get selectLineError => 'कृपया एक लाइन चुनें।';

  @override
  String get selectDueDateError => 'कृपया एक देय तिथि चुनें।';

  @override
  String get allTowersRequiresLine => '\"सभी\" के लिए परिभाषित टावरों के साथ एक चयनित लाइन की आवश्यकता है।';

  @override
  String get allTowers => 'सभी टावर';

  @override
  String get surveyEntry => 'सर्वेक्षण प्रविष्टि';

  @override
  String get moveToOpenArea => 'खुले क्षेत्र में जाएं।';

  @override
  String couldNotGetLocationWithinSeconds(Object seconds) {
    return 'समस्त $seconds सेकंड के भीतर कोई स्थान प्राप्त नहीं हो सका। कृपया पुनः प्रयास करें।';
  }

  @override
  String locationAcquired(Object accuracy) {
    return 'सर्वोत्तम उपलब्ध सटीकता के साथ स्थान प्राप्त हुआ: $accuracyमी।';
  }

  @override
  String unexpectedErrorStartingLocation(Object error) {
    return 'स्थान प्रारंभ करते समय एक अप्रत्याशित त्रुटि हुई: $error';
  }

  @override
  String timeoutInSeconds(Object seconds) {
    return 'समय समाप्त होने में $secondsसेकंड';
  }

  @override
  String get getCurrentLocation => 'वर्तमान स्थान प्राप्त करें';

  @override
  String get fillAllRequiredFields => 'कृपया सभी आवश्यक फ़ील्ड सही ढंग से भरें।';

  @override
  String get good => 'अच्छा';

  @override
  String get backfillingRequired => 'बैकफिलिंग आवश्यक';

  @override
  String get revetmentWallRequired => 'रिवेटमेंट वॉल आवश्यक';

  @override
  String get excavationOfSoilRequired => 'मिट्टी की खुदाई आवश्यक';

  @override
  String get rusted => 'जंग लगा हुआ';

  @override
  String get bent => 'मुड़ा हुआ';

  @override
  String get hanging => 'लटका हुआ';

  @override
  String get damaged => 'क्षतिग्रस्त';

  @override
  String get cracked => 'फटा हुआ';

  @override
  String get broken => 'टूटा हुआ';

  @override
  String get flashover => 'फ्लैशओवर';

  @override
  String get dirty => 'गंदा';

  @override
  String get loose => 'ढीला';

  @override
  String get boltMissing => 'बोल्ट गायब';

  @override
  String get spacersMissing => 'स्पेसर्स गायब';

  @override
  String get corroded => 'संक्षारित';

  @override
  String get faded => 'फीका पड़ा हुआ';

  @override
  String get disconnected => 'डिस्कनेक्टेड';

  @override
  String get open => 'खुला';

  @override
  String get leaking => 'लीक हो रहा है';

  @override
  String get present => 'उपस्थित';

  @override
  String get trimmingRequired => 'ट्रिमिंग आवश्यक';

  @override
  String get loppingRequired => 'लॉपिंग आवश्यक';

  @override
  String get cuttingRequired => 'कटिंग आवश्यक';

  @override
  String get minor => 'मामूली';

  @override
  String get moderate => 'मध्यम';

  @override
  String get severe => 'गंभीर';

  @override
  String get intact => 'अक्षुण्ण';

  @override
  String get notApplicable => 'लागू नहीं';

  @override
  String get taskAndAssociatedRecordsDeleted => 'कार्य और संबंधित स्थानीय रिकॉर्ड सफलतापूर्वक हटा दिए गए!';

  @override
  String get taskStatusUpdated => 'कार्य स्थिति अपडेट की गई!';

  @override
  String errorUpdatingTask(Object error) {
    return 'कार्य अपडेट करने में त्रुटि: $error';
  }

  @override
  String errorUploadingUnsyncedRecords(Object error) {
    return 'असिंक्रनाइज़ किए गए रिकॉर्ड अपलोड करने में त्रुटि: $error';
  }

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String welcomeUser(Object displayName, Object role) {
    return 'स्वागत है, $displayName ($role)!';
  }

  @override
  String get toPatrol => 'गश्त करने के लिए';

  @override
  String get yourSurveyLogForThisTask => 'इस कार्य के लिए आपका सर्वेक्षण लॉग:';

  @override
  String get noSurveysRecordedForThisTask => 'इस कार्य के लिए अभी तक कोई सर्वेक्षण रिकॉर्ड नहीं किया गया है।';

  @override
  String get at => 'पर';

  @override
  String get recheckingAccountStatus => 'खाता स्थिति पुनः जांच रहा है...';

  @override
  String errorLoadingLineRecords(Object error) {
    return 'लाइन रिकॉर्ड लोड करने में त्रुटि: $error';
  }

  @override
  String get nationalHighway => 'राष्ट्रीय राजमार्ग';

  @override
  String get stateHighway => 'राज्य राजमार्ग';

  @override
  String get localRoad => 'स्थानीय सड़क';

  @override
  String get overBridge => 'ओवर ब्रिज';

  @override
  String get underpass => 'अंडरपास';

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
  String get privateTubeWell => 'निजी ट्यूबवेल';

  @override
  String get notOkay => 'ठीक नहीं';

  @override
  String get oK => 'ठीक है';

  @override
  String get unassignedRole => 'असाइन नहीं किया गया';

  @override
  String get missing => 'गायब';

  @override
  String get patrollingDetails => 'गश्त विवरण';

  @override
  String get switchToHindi => 'हिंदी में बदलें';

  @override
  String get switchToEnglish => 'अंग्रेज़ी में बदलें';

  @override
  String errorDeletingTask(Object error) {
    return 'कार्य हटाने में त्रुटि: $error';
  }

  @override
  String get span => 'Span';

  @override
  String get spanLength => 'स्पैन लंबाई';

  @override
  String get on => 'पर';

  @override
  String get selectConditionOfOpgw => 'ओपीजीडब्ल्यू की स्थिति चुनें';

  @override
  String get selectConditionOfEarthWire => 'अर्थ वायर की स्थिति चुनें';

  @override
  String get selectConditionOfConductor => 'कंडक्टर की स्थिति चुनें';

  @override
  String get selectMidSpanJoint => 'मिड स्पैन जॉइंट चुनें';

  @override
  String get selectNewConstruction => 'नया निर्माण चुनें';

  @override
  String get selectSpacers => 'स्पेसर चुनें';

  @override
  String get selectVibrationDamper => 'वाइब्रेशन डैम्पर चुनें';

  @override
  String get selectRoadCrossing => 'सड़क क्रॉसिंग प्रकार चुनें';

  @override
  String get selectRiverCrossing => 'नदी क्रॉसिंग प्रकार चुनें';

  @override
  String get selectElectricalLine => 'विद्युत लाइन प्रकार चुनें';

  @override
  String get selectRailwayCrossing => 'रेलवे क्रॉसिंग प्रकार चुनें';

  @override
  String get selectRoadCrossingTypes => 'सड़क क्रॉसिंग प्रकार चुनें';

  @override
  String get selectElectricalLineTypes => 'विद्युत लाइन प्रकार चुनें';

  @override
  String get hasElectricalLineCrossing => 'विद्युत लाइन क्रॉसिंग है';

  @override
  String get hasRoadCrossing => 'सड़क क्रॉसिंग है';

  @override
  String get roadCrossingName => 'सड़क क्रॉसिंग नाम';

  @override
  String get enterRoadCrossingName => 'सड़क क्रॉसिंग नाम दर्ज करें';

  @override
  String get electricalLineName => 'विद्युत लाइन नाम';

  @override
  String get enterElectricalLineName => 'विद्युत लाइन नाम दर्ज करें';

  @override
  String get bottomConductor => 'तल कंडक्टर';

  @override
  String get topConductor => 'शीर्ष कंडक्टर';

  @override
  String get towerType => 'टॉवर प्रकार';

  @override
  String get selectTowerType => 'टॉवर प्रकार चुनें';

  @override
  String get overdue => 'अतिदेय';

  @override
  String daysLeft(Object daysLeft) {
    return '$daysLeft दिन शेष';
  }

  @override
  String get progress => 'प्रगति';

  @override
  String taskReassignedSuccessfully(Object displayName, Object email, Object lineName, Object targetTowerRange) {
    return 'कार्य सफलतापूर्वक पुनः असाइन किया गया!';
  }

  @override
  String get selectWorkerToReassign => 'इस कार्य को पुनः असाइन करने के लिए एक कार्यकर्ता चुनें';

  @override
  String taskCancelledSuccessfully(Object lineName, Object targetTowerRange) {
    return '$lineName से $targetTowerRange का कार्य सफलतापूर्वक रद्द किया गया!';
  }

  @override
  String get confirmCancellation => 'क्या आप इस कार्य को रद्द करना चाहते हैं? यह कार्रवाई पूर्ववत नहीं की जा सकती है।';

  @override
  String cancelTaskConfirmation(Object assignedToUserName, Object lineName, Object towerRange) {
    return 'क्या आप लाइन: $lineName, टावरों: $towerRange से $assignedToUserName का कार्य रद्द करना चाहते हैं? इससे इस कार्य के लिए ऐप में किसी भी संबंधित सर्वेक्षण प्रगति को भी हटा दिया जाएगा। यह कार्रवाई पूर्ववत नहीं की जा सकती है।';
  }

  @override
  String get cancelTask => 'कार्य रद्द करें';

  @override
  String get reassignTask => 'कार्य पुनः असाइन करें';

  @override
  String get suspension => 'सस्पेंशन';

  @override
  String get tension => 'टेंशन';

  @override
  String get angle => 'एंगल';

  @override
  String get transposition => 'ट्रांसपोज़िशन';

  @override
  String get deadEnd => 'डेड एंड';

  @override
  String get grantry => 'ग्रैंट्री';
}
