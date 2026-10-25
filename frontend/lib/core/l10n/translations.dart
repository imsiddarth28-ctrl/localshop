class AppStrings {
  // Common
  final String appTitle;
  final String appTagline;
  final String continueBtn;
  final String saveBtn;
  final String cancelBtn;
  final String submitBtn;
  final String loading;
  final String or;
  final String logout;
  final String call;
  final String optional;

  // Language Switch
  final String language;
  final String english;
  final String telugu;

  // Login
  final String loginTitle;
  final String loginSubtitle;
  final String phoneLabel;
  final String phoneHint;
  final String passwordLabel;
  final String passwordHint;
  final String showPassword;
  final String hidePassword;
  final String loginBtn;
  final String noAccount;
  final String signupLink;
  final String forgotPassword;
  final String requestPasswordReset;
  final String resetRequestedSuccess;
  final String lockoutNotice;

  // Signup & Roles
  final String signupTitle;
  final String signupSubtitle;
  final String confirmPasswordLabel;
  final String confirmPasswordHint;
  final String chooseRoleTitle;
  final String chooseRoleSubtitle;
  final String customerRoleTitle;
  final String customerRoleDesc;
  final String shopOwnerRoleTitle;
  final String shopOwnerRoleDesc;
  final String alreadyHaveAccount;
  final String loginLink;

  // Onboarding - Customer
  final String customerOnboardingTitle;
  final String customerOnboardingSubtitle;
  final String fullNameLabel;
  final String fullNameHint;
  final String colonyCodeLabel;
  final String colonyCodeHint;
  final String colonyCodeHelp;
  final String flatLabel;
  final String flatHint;
  final String addPhoto;
  final String completeProfileBtn;

  // Onboarding - Shop Owner
  final String shopOnboardingTitle;
  final String shopOnboardingSubtitle;
  final String shopNameLabel;
  final String shopNameHint;
  final String categoryLabel;
  final String hoursLabel;
  final String hoursHint;
  final String addressLabel;
  final String addressHint;
  final String deliverySlotsOffered;
  final String instantSlotDesc;
  final String morningSlotDesc;
  final String eveningSlotDesc;
  final String submitForApprovalBtn;

  // Pending Approval
  final String pendingApprovalTitle;
  final String pendingApprovalDesc;
  final String pendingApprovalHint;
  final String checkStatusBtn;

  // Forced Change Password
  final String changePasswordTitle;
  final String changePasswordSubtitle;
  final String newPasswordLabel;
  final String newPasswordHint;
  final String updatePasswordBtn;

  // Validation Errors
  final String enterValidPhone;
  final String enterValidPassword;
  final String passwordsDoNotMatch;
  final String enterFullName;
  final String enterColonyCode;
  final String enterFlatNumber;
  final String enterShopName;
  final String enterShopAddress;

  const AppStrings({
    required this.appTitle,
    required this.appTagline,
    required this.continueBtn,
    required this.saveBtn,
    required this.cancelBtn,
    required this.submitBtn,
    required this.loading,
    required this.or,
    required this.logout,
    required this.call,
    required this.optional,
    required this.language,
    required this.english,
    required this.telugu,
    required this.loginTitle,
    required this.loginSubtitle,
    required this.phoneLabel,
    required this.phoneHint,
    required this.passwordLabel,
    required this.passwordHint,
    required this.showPassword,
    required this.hidePassword,
    required this.loginBtn,
    required this.noAccount,
    required this.signupLink,
    required this.forgotPassword,
    required this.requestPasswordReset,
    required this.resetRequestedSuccess,
    required this.lockoutNotice,
    required this.signupTitle,
    required this.signupSubtitle,
    required this.confirmPasswordLabel,
    required this.confirmPasswordHint,
    required this.chooseRoleTitle,
    required this.chooseRoleSubtitle,
    required this.customerRoleTitle,
    required this.customerRoleDesc,
    required this.shopOwnerRoleTitle,
    required this.shopOwnerRoleDesc,
    required this.alreadyHaveAccount,
    required this.loginLink,
    required this.customerOnboardingTitle,
    required this.customerOnboardingSubtitle,
    required this.fullNameLabel,
    required this.fullNameHint,
    required this.colonyCodeLabel,
    required this.colonyCodeHint,
    required this.colonyCodeHelp,
    required this.flatLabel,
    required this.flatHint,
    required this.addPhoto,
    required this.completeProfileBtn,
    required this.shopOnboardingTitle,
    required this.shopOnboardingSubtitle,
    required this.shopNameLabel,
    required this.shopNameHint,
    required this.categoryLabel,
    required this.hoursLabel,
    required this.hoursHint,
    required this.addressLabel,
    required this.addressHint,
    required this.deliverySlotsOffered,
    required this.instantSlotDesc,
    required this.morningSlotDesc,
    required this.eveningSlotDesc,
    required this.submitForApprovalBtn,
    required this.pendingApprovalTitle,
    required this.pendingApprovalDesc,
    required this.pendingApprovalHint,
    required this.checkStatusBtn,
    required this.changePasswordTitle,
    required this.changePasswordSubtitle,
    required this.newPasswordLabel,
    required this.newPasswordHint,
    required this.updatePasswordBtn,
    required this.enterValidPhone,
    required this.enterValidPassword,
    required this.passwordsDoNotMatch,
    required this.enterFullName,
    required this.enterColonyCode,
    required this.enterFlatNumber,
    required this.enterShopName,
    required this.enterShopAddress,
  });

  static const AppStrings en = AppStrings(
    appTitle: 'The Local Shop',
    appTagline: 'Colony Groceries & Daily Needs in One Tap',
    continueBtn: 'Continue',
    saveBtn: 'Save',
    cancelBtn: 'Cancel',
    submitBtn: 'Submit',
    loading: 'Please wait...',
    or: 'OR',
    logout: 'Log Out',
    call: 'Call Shop',
    optional: 'Optional',
    language: 'Language',
    english: 'English',
    telugu: 'తెలుగు (Telugu)',
    loginTitle: 'Welcome Back!',
    loginSubtitle: 'Enter your 10-digit mobile number and password',
    phoneLabel: 'Mobile Number',
    phoneHint: '10 digit mobile number',
    passwordLabel: 'Password',
    passwordHint: 'At least 6 characters',
    showPassword: 'Show Password',
    hidePassword: 'Hide Password',
    loginBtn: 'Log In',
    noAccount: "Don't have an account?",
    signupLink: 'Sign Up Here',
    forgotPassword: 'Forgot Password?',
    requestPasswordReset: 'Request Password Reset',
    resetRequestedSuccess: 'Password reset request sent to Admin. You will be notified once processed.',
    lockoutNotice: 'Account temporarily locked due to 5 wrong attempts. Please try again after 15 minutes.',
    signupTitle: 'Create Account',
    signupSubtitle: 'Fast & simple registration for your colony',
    confirmPasswordLabel: 'Confirm Password',
    confirmPasswordHint: 'Re-enter your password',
    chooseRoleTitle: 'How will you use The Local Shop?',
    chooseRoleSubtitle: 'Select your account type to proceed',
    customerRoleTitle: "I'm a Customer",
    customerRoleDesc: 'Order daily groceries, dairy & veggies from colony shops with doorstep delivery.',
    shopOwnerRoleTitle: 'I own a Shop',
    shopOwnerRoleDesc: 'Receive colony orders, send bills, and organize batch morning & evening runs.',
    alreadyHaveAccount: 'Already have an account?',
    loginLink: 'Log In Here',
    customerOnboardingTitle: 'Customer Details',
    customerOnboardingSubtitle: 'Tell us your name and where you live in the colony',
    fullNameLabel: 'Full Name',
    fullNameHint: 'e.g. Sita Devi / Rajesh Rao',
    colonyCodeLabel: 'Colony Join Code',
    colonyCodeHint: '6-character code (e.g. GRN101)',
    colonyCodeHelp: 'Get this code from your Resident Welfare Association or Admin',
    flatLabel: 'Block / Flat / House Number',
    flatHint: 'e.g. Tower B, Flat 304',
    addPhoto: 'Add Profile Photo',
    completeProfileBtn: 'Start Shopping',
    shopOnboardingTitle: 'Shop Setup',
    shopOnboardingSubtitle: 'Register your colony shop for admin approval',
    shopNameLabel: 'Shop Name',
    shopNameHint: 'e.g. Sri Balaji Kirana & General Store',
    categoryLabel: 'Shop Category',
    hoursLabel: 'Operating Hours',
    hoursHint: 'e.g. 7:00 AM - 9:30 PM',
    addressLabel: 'Shop Location / Colony Address',
    addressHint: 'e.g. Shop No 1, Commercial Complex',
    deliverySlotsOffered: 'Supported Delivery Slots',
    instantSlotDesc: 'Instant Delivery (+₹10)',
    morningSlotDesc: 'Morning 7:00 AM Batch (+₹5)',
    eveningSlotDesc: 'Evening 6:00 PM Batch (+₹5)',
    submitForApprovalBtn: 'Submit Shop for Approval',
    pendingApprovalTitle: 'Application Under Review',
    pendingApprovalDesc: 'Your shop registration has been submitted. Our colony administrator will review and verify your details shortly.',
    pendingApprovalHint: 'Usually approved within 1-2 hours.',
    checkStatusBtn: 'Check Approval Status',
    changePasswordTitle: 'Set New Password',
    changePasswordSubtitle: 'Your password was reset by the administrator. Please choose a new secure password.',
    newPasswordLabel: 'New Password',
    newPasswordHint: 'Minimum 6 characters',
    updatePasswordBtn: 'Update Password & Proceed',
    enterValidPhone: 'Please enter a valid 10-digit mobile number',
    enterValidPassword: 'Password must be at least 6 characters',
    passwordsDoNotMatch: 'Passwords do not match',
    enterFullName: 'Please enter your full name',
    enterColonyCode: 'Please enter a valid 6-character colony code',
    enterFlatNumber: 'Please specify your block or flat number',
    enterShopName: 'Please enter your shop name',
    enterShopAddress: 'Please enter the shop address in colony',
  );

  static const AppStrings te = AppStrings(
    appTitle: 'ద లోకల్ షాప్',
    appTagline: 'కాలనీ సరుకులు మరియు నిత్యావసరాలు ఒకే క్లిక్‌తో',
    continueBtn: 'కొనసాగించండి',
    saveBtn: 'భద్రపరచండి',
    cancelBtn: 'రద్దు చేయండి',
    submitBtn: 'సమర్పించండి',
    loading: 'దయచేసి వేచి ఉండండి...',
    or: 'లేదా',
    logout: 'లాగ్ అవుట్',
    call: 'షాపుకు కాల్ చేయండి',
    optional: 'ఐచ్ఛికం',
    language: 'భాష',
    english: 'English',
    telugu: 'తెలుగు (Telugu)',
    loginTitle: 'స్వాగతం!',
    loginSubtitle: 'మీ 10 అంకెల మొబైల్ నంబర్ మరియు పాస్‌వర్డ్ నమోదు చేయండి',
    phoneLabel: 'మొబైల్ నంబర్',
    phoneHint: '10 అంకెల మొబైల్ నంబర్',
    passwordLabel: 'పాస్‌వర్డ్',
    passwordHint: 'కనీసం 6 అక్షరాలు',
    showPassword: 'పాస్‌వర్డ్ చూపించు',
    hidePassword: 'పాస్‌వర్డ్ దాచు',
    loginBtn: 'లాగిన్ అవ్వండి',
    noAccount: 'ఖాతా లేదా?',
    signupLink: 'ఇక్కడ నమోదు చేసుకోండి',
    forgotPassword: 'పాస్‌వర్డ్ మర్చిపోయారా?',
    requestPasswordReset: 'పాస్‌వర్డ్ రీసెట్ అభ్యర్థించండి',
    resetRequestedSuccess: 'పాస్‌వర్డ్ రీసెట్ అభ్యర్థన అడ్మిన్‌కు పంపబడింది. త్వరలో రీసెట్ చేయబడుతుంది.',
    lockoutNotice: '5 తప్పుడు ప్రయత్నాల వల్ల ఖాతా 15 నిమిషాల పాటు లాక్ చేయబడింది.',
    signupTitle: 'కొత్త ఖాతా సృష్టించండి',
    signupSubtitle: 'మీ కాలనీ కోసం సులభమైన నమోదు',
    confirmPasswordLabel: 'పాస్‌వర్డ్ నిర్ధారించండి',
    confirmPasswordHint: 'పాస్‌వర్డ్‌ను మళ్లీ నమోదు చేయండి',
    chooseRoleTitle: 'మీరు ఎలా ఉపయోగించాలనుకుంటున్నారు?',
    chooseRoleSubtitle: 'కొనసాగడానికి మీ పాత్రను ఎంచుకోండి',
    customerRoleTitle: 'నేను కొనుగోలుదారుడిని (కస్టమర్)',
    customerRoleDesc: 'కాలనీ షాపుల నుండి ఇంటి వద్దకే సరుకులు, పాలు, కూరగాయలు ఆర్డర్ చేసుకోండి.',
    shopOwnerRoleTitle: 'నాకు షాప్ ఉంది (షాపు యజమాని)',
    shopOwnerRoleDesc: 'ఆర్డర్లు స్వీకరించండి, బిల్లులు పంపండి, ఉదయం-సాయంత్రం డెలివరీ నిర్వహించండి.',
    alreadyHaveAccount: 'ఇప్పటికే ఖాతా ఉందా?',
    loginLink: 'ఇక్కడ లాగిన్ అవ్వండి',
    customerOnboardingTitle: 'కస్టమర్ వివరాలు',
    customerOnboardingSubtitle: 'మీ పేరు మరియు కాలనీలో మీ ఫ్లాట్ నంబర్ తెలియజేయండి',
    fullNameLabel: 'పూర్తి పేరు',
    fullNameHint: 'ఉదా: సీతాదేవి / రాజేష్ రావు',
    colonyCodeLabel: 'కాలనీ జాయిన్ కోడ్',
    colonyCodeHint: '6 అక్షరాల కోడ్ (ఉదా: GRN101)',
    colonyCodeHelp: 'ఈ కోడ్ మీ కాలనీ అసోసియేషన్ లేదా అడ్మిన్ నుండి పొందండి',
    flatLabel: 'బ్లాక్ / ఫ్లాట్ / ఇంటి నంబర్',
    flatHint: 'ఉదా: టవర్ B, ఫ్లాట్ 304',
    addPhoto: 'ప్రొఫైల్ ఫోటో జోడించండి',
    completeProfileBtn: 'షాపింగ్ ప్రారంభించండి',
    shopOnboardingTitle: 'షాప్ వివరాలు',
    shopOnboardingSubtitle: 'అడ్మిన్ ఆమోదం కోసం మీ షాపును నమోదు చేయండి',
    shopNameLabel: 'షాప్ పేరు',
    shopNameHint: 'ఉదా: శ్రీ బాలాజీ కిరాణా & జనరల్ స్టోర్',
    categoryLabel: 'షాప్ కేటగిరీ',
    hoursLabel: 'షాప్ తెరిచే వేళలు',
    hoursHint: 'ఉదా: ఉదయం 7:00 - రాత్రి 9:30',
    addressLabel: 'కాలనీలో షాప్ చిరునామా',
    addressHint: 'ఉదా: షాప్ నెం. 1, కమ్యూనిటీ సెంటర్',
    deliverySlotsOffered: 'డెలివరీ సమయాలు',
    instantSlotDesc: 'తక్షణ డెలివరీ (+₹10)',
    morningSlotDesc: 'ఉదయం 7:00 AM బ్యాచ్ (+₹5)',
    eveningSlotDesc: 'సాయంత్రం 6:00 PM బ్యాచ్ (+₹5)',
    submitForApprovalBtn: 'ఆమోదం కోసం సమర్పించండి',
    pendingApprovalTitle: 'పరిశీలనలో ఉంది',
    pendingApprovalDesc: 'మీ షాపు నమోదు విజయవంతంగా సమర్పించబడింది. కాలనీ అడ్మిన్ త్వరలోనే పరిశీలించి ఆమోదిస్తారు.',
    pendingApprovalHint: 'సాధారణంగా 1-2 గంటల్లో ఆమోదించబడుతుంది.',
    checkStatusBtn: 'ఆమోద స్థితిని తనిఖీ చేయండి',
    changePasswordTitle: 'కొత్త పాస్‌వర్డ్ సెట్ చేయండి',
    changePasswordSubtitle: 'అడ్మిన్ మీ పాస్‌వర్డ్ రీసెట్ చేశారు. దయచేసి కొత్త పాస్‌వర్డ్ ఎంచుకోండి.',
    newPasswordLabel: 'కొత్త పాస్‌వర్డ్',
    newPasswordHint: 'కనీసం 6 అక్షరాలు',
    updatePasswordBtn: 'పాస్‌వర్డ్ అప్‌డేట్ చేసి కొనసాగండి',
    enterValidPhone: 'దయచేసి సరైన 10 అంకెల మొబైల్ నంబర్ నమోదు చేయండి',
    enterValidPassword: 'పాస్‌వర్డ్ కనీసం 6 అక్షరాలు ఉండాలి',
    passwordsDoNotMatch: 'పాస్‌వర్డ్‌లు సరిపోలడం లేదు',
    enterFullName: 'దయచేసి మీ పూర్తి పేరు నమోదు చేయండి',
    enterColonyCode: 'దయచేసి సరైన 6 అక్షరాల కాలనీ కోడ్ నమోదు చేయండి',
    enterFlatNumber: 'దయచేసి మీ ఫ్లాట్ లేదా ఇంటి నంబర్ నమోదు చేయండి',
    enterShopName: 'దయచేసి షాప్ పేరు నమోదు చేయండి',
    enterShopAddress: 'దయచేసి కాలనీలో షాప్ చిరునామా నమోదు చేయండి',
  );
}
