import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isUrdu => locale.languageCode == 'ur';

  String get _lang => locale.languageCode;

  // ============================================
  // Common / Shared
  // ============================================
  String get appName => _t('JEO KISSAN', 'جیو کسان');
  String get appTitle => _t('JeoKissan QMS', 'جیو کسان کیو ایم ایس');
  String get qualityManagementSystem => _t('5-Tier Quality Management System', '5 درجاتی کوالٹی مینجمنٹ سسٹم');
  String get loading => _t('Loading...', 'لوڈ ہو رہا ہے...');
  String get error => _t('Error', 'خرابی');
  String get cancel => _t('Cancel', 'منسوخ');
  String get ok => _t('OK', 'ٹھیک ہے');
  String get done => _t('Done', 'مکمل');
  String get yes => _t('Yes', 'ہاں');
  String get no => _t('No', 'نہیں');

  // ============================================
  // Splash Screen
  // ============================================
  String get splashTitle => _t('JEO KISSAN', 'جیو کسان');
  String get splashSubtitle => _t('5-Tier Quality Management System', '5 درجاتی کوالٹی مینجمنٹ سسٹم');
  String get splashLoading => _t('Loading...', 'لوڈ ہو رہا ہے...');

  // ============================================
  // Login Screen
  // ============================================
  String get welcomeTitle => _t('Welcome To Jeo Kissan', 'جیو کسان میں خوش آمدید');
  String get loginSubtitle => _t('Quality Management System', 'کوالٹی مینجمنٹ سسٹم');
  String get loginToAccount => _t('Login to your account', 'اپنے اکاؤنٹ میں لاگ ان کریں');
  String get enterEmail => _t('Enter Email', 'ای میل درج کریں');
  String get enterPassword => _t('Enter Password', 'پاسورڈ درج کریں');
  String get forgotPassword => _t('Forgot Password?', 'پاسورڈ بھول گئے؟');
  String get login => _t('Login', 'لاگ ان');
  String get dontHaveAccount => _t("Don't have an account?", 'اکاؤنٹ نہیں ہے؟');
  String get createAccount => _t('Create Account', 'اکاؤنٹ بنائیں');
  String get pleaseFillAllFields => _t('Please fill in all fields', 'براہ کرم تمام خانے پر کریں');
  String get loginSuccessful => _t('Login Successful! Welcome back!', 'لاگ ان کامیاب! دوبارہ خوش آمدید!');
  String get loginFailed => _t('Login Failed', 'لاگ ان ناکام');
  String get noAccountFound => _t('No account found with this email.', 'اس ای میل سے کوئی اکاؤنٹ نہیں ملا۔');
  String get incorrectPassword => _t('Incorrect password. Please try again.', 'غلط پاسورڈ۔ براہ کرم دوبارہ کوشش کریں۔');
  String get invalidEmail => _t('Please enter a valid email address.', 'براہ کرم درست ای میل درج کریں۔');
  String get accountDisabled => _t('This account has been disabled.', 'یہ اکاؤنٹ غیر فعال کر دیا گیا ہے۔');
  String get invalidCredentials => _t('Invalid credentials. Please check your email and password.', 'غلط معلومات۔ براہ کرم اپنا ای میل اور پاسورڈ چیک کریں۔');
  String get tooManyAttempts => _t('Too many attempts. Please try again later.', 'بہت زیادہ کوششیں۔ براہ کرم بعد میں دوبارہ کوشش کریں۔');
  String get somethingWentWrong => _t('Something went wrong. Please try again.', 'کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔');

  // ============================================
  // Register Screen
  // ============================================
  String get registerToGetStarted => _t('Register to get started', 'شروع کرنے کے لیے رجسٹر کریں');
  String get enterFirstName => _t('Enter First Name', 'پہلا نام درج کریں');
  String get enterLastName => _t('Enter Last Name', 'آخری نام درج کریں');
  String get register => _t('Register', 'رجسٹر');
  String get alreadyHaveAccount => _t('Already have an account? ', 'پہلے سے اکاؤنٹ ہے؟ ');
  String get clickHere => _t('Click Here', 'یہاں کلک کریں');
  String get registrationSuccessful => _t('Registration Successful! Welcome!', 'رجسٹریشن کامیاب! خوش آمدید!');
  String get registrationFailed => _t('Registration Failed', 'رجسٹریشن ناکام');
  String get weakPassword => _t('Password is too weak. Use at least 6 characters.', 'پاسورڈ کمزور ہے۔ کم از کم 6 حروف استعمال کریں۔');
  String get emailAlreadyInUse => _t('This email is already registered.', 'یہ ای میل پہلے سے رجسٹرڈ ہے۔');

  // ============================================
  // Forgot Password Screen
  // ============================================
  String get forgotPasswordTitle => _t('Forgot Password?', 'پاسورڈ بھول گئے؟');
  String get emailSentTitle => _t('Email Sent!', 'ای میل بھیج دی گئی!');
  String get forgotPasswordSubtitle => _t(
    'Enter your registered email address and we\'ll send you a link to reset your password.',
    'اپنا رجسٹرڈ ای میل درج کریں اور ہم آپ کو پاسورڈ ری سیٹ کا لنک بھیجیں گے۔',
  );
  String get emailSentSubtitle => _t(
    'We have sent a password reset link to your email. Please check your inbox and follow the link to reset your password.',
    'ہم نے آپ کے ای میل پر پاسورڈ ری سیٹ لنک بھیج دیا ہے۔ براہ کرم اپنا ان باکس چیک کریں۔',
  );
  String get enterYourEmail => _t('Enter your email', 'اپنا ای میل درج کریں');
  String get sendResetLink => _t('Send Reset Link', 'ری سیٹ لنک بھیجیں');
  String get resetLinkSentTo => _t('Reset link sent to:', 'ری سیٹ لنک بھیجا گیا:');
  String get sendAgain => _t('Send Again', 'دوبارہ بھیجیں');
  String get backToLogin => _t('Back to Login', 'لاگ ان پر واپس جائیں');
  String get checkSpamFolder => _t(
    'Check your spam/junk folder if you don\'t see the email in your inbox.',
    'اگر ان باکس میں ای میل نظر نہ آئے تو اسپیم فولڈر چیک کریں۔',
  );
  String get pleaseEnterEmail => _t('Please enter your email address', 'براہ کرم اپنا ای میل درج کریں');
  String get pleaseEnterValidEmail => _t('Please enter a valid email address', 'براہ کرم درست ای میل درج کریں');
  String get noAccountFoundSignUp => _t('No account found with this email. Please sign up first.', 'اس ای میل سے کوئی اکاؤنٹ نہیں ملا۔ پہلے سائن اپ کریں۔');

  // ============================================
  // Home Screen
  // ============================================
  String get jeokissan => _t('JEOKISSAN', 'جیو کسان');
  String get startInspection => _t('Start Inspection', 'معائنہ شروع کریں');
  String get startInspectionDesc => _t(
    'Upload or Capture picture of commodity for 5\ntier classification',
    'اجناس کی تصویر اپ لوڈ یا کیپچر کریں\n5 درجاتی درجہ بندی کے لیے',
  );
  String get selectImageSource => _t('Select Image Source', 'تصویر کا ذریعہ منتخب کریں');
  String get camera => _t('Camera', 'کیمرہ');
  String get gallery => _t('Gallery', 'گیلری');
  String get analyzingImages => _t('Analyzing images...', 'تصاویر کا تجزیہ ہو رہا ہے...');
  String get gettingFinalClassification => _t('Getting final classification...', 'حتمی درجہ بندی حاصل ہو رہی ہے...');
  String get classificationFailed => _t('Classification failed', 'درجہ بندی ناکام');
  String get notAgriculturalImage => _t(
    'This image does not contain an agricultural commodity. Please upload an image of a fruit, vegetable, grain, pulse, spice, or other farm produce.',
    'یہ تصویر زرعی اجناس پر مشتمل نہیں ہے۔ براہ کرم پھل، سبزی، اناج، دال، مصالحے، یا دیگر زرعی پیداوار کی تصویر اپ لوڈ کریں۔',
  );
  String get analysisFailed => _t('Analysis failed', 'تجزیہ ناکام');

  // Quality Labels
  String get excellent => _t('Excellent', 'بہترین');
  String get veryGood => _t('Very Good', 'بہت اچھا');
  String get good => _t('Good', 'اچھا');
  String get satisfactory => _t('Satisfactory', 'تسلی بخش');
  String get rotten => _t('Rotten', 'خراب');

  List<String> get qualityLabels => [excellent, veryGood, good, satisfactory, rotten];

  // ============================================
  // Preview Image Screen
  // ============================================
  String previewTitle(int count) => count > 1
      ? _t('Preview $count Images', '$count تصاویر کا جائزہ')
      : _t('Preview Image', 'تصویر کا جائزہ');
  String previewQuestion(int count) => count > 1
      ? _t('Are these the right images for classification?', 'کیا یہ درجہ بندی کے لیے صحیح تصاویر ہیں؟')
      : _t('Is this the right image for classification?', 'کیا یہ درجہ بندی کے لیے صحیح تصویر ہے؟');
  String classifyButton(int count) => count > 1
      ? _t('Classify Images', 'تصاویر کی درجہ بندی کریں')
      : _t('Classify Image', 'تصویر کی درجہ بندی کریں');
  String get changeImage => _t('Change Image', 'تصویر تبدیل کریں');
  String analysisInfo(int count) => count > 1
      ? _t(
          'Your $count images will be analyzed together\nfor 5-tier quality classification.',
          'آپ کی $count تصاویر مل کر تجزیہ ہوں گی\n5 درجاتی کوالٹی درجہ بندی کے لیے۔',
        )
      : _t(
          'Your image will be analyzed using AI\nfor 5-tier quality classification.',
          'آپ کی تصویر AI کے ذریعے تجزیہ ہوگی\n5 درجاتی کوالٹی درجہ بندی کے لیے۔',
        );
  String get jeoKissan => _t('Jeo Kissan', 'جیو کسان');
  String get fiveTierQMS => _t('5-Tier Quality Management System', '5 درجاتی کوالٹی مینجمنٹ سسٹم');

  // ============================================
  // Questions Screen
  // ============================================
  String get qualityAssessment => _t('Quality Assessment', 'کوالٹی تشخیص');
  String get followUpQuestions => _t('Follow-up Questions', 'فالو اپ سوالات');
  String get helpAIClassify => _t('Help AI classify more accurately', 'AI کو زیادہ درست درجہ بندی میں مدد کریں');
  String get selectAnAnswer => _t('Select an answer...', 'جواب منتخب کریں...');
  String get answerInfoText => _t(
    'Answer as many questions as you can for better accuracy. You can skip questions you don\'t know.',
    'بہتر درستگی کے لیے زیادہ سے زیادہ سوالات کے جوابات دیں۔ جو نہ جانیں وہ چھوڑ سکتے ہیں۔',
  );
  String get answerAtLeastOne => _t('Please answer at least one question', 'براہ کرم کم از کم ایک سوال کا جواب دیں');
  String get classifying => _t('Classifying...', 'درجہ بندی ہو رہی ہے...');
  String get getFinalClassification => _t('Get Final Classification', 'حتمی درجہ بندی حاصل کریں');

  // ============================================
  // Classification Result Screen
  // ============================================
  String get classificationResult => _t('Classification Result', 'درجہ بندی کا نتیجہ');
  String reasonsForRating(String rating) => _t('Reasons for "$rating" rating', '"$rating" ریٹنگ کی وجوہات');
  String get classifyAnotherImage => _t('Classify Another Image', 'ایک اور تصویر کی درجہ بندی کریں');

  // ============================================
  // Quality Manual Screen
  // ============================================
  String get qualityManual => _t('Quality Manual', 'کوالٹی مینول');
  String get searchCommodity => _t('Search commodity...', 'کمودٹی تلاش کریں...');
  String get quickSearch => _t('Quick Search', 'فوری تلاش');
  String get commodityNotFound => _t('Commodity not found. Please try another search.', 'کمودٹی نہیں ملی۔ براہ کرم دوسری تلاش کریں۔');
  String get failedToLoadManual => _t('Failed to load Quality Manual. Please try again.', 'کوالٹی مینول لوڈ کرنے میں ناکام۔ براہ کرم دوبارہ کوشش کریں۔');

  // ============================================
  // Settings Screen
  // ============================================
  String get settings => _t('Settings', 'ترتیبات');
  String get about => _t('About', 'بارے میں');
  String get aboutThathalITS => _t('About Thathal ITS', 'تھتھال آئی ٹی ایس کے بارے میں');
  String get aboutGeoKissan => _t('About Geo Kissan', 'جیو کسان کے بارے میں');
  String get help => _t('Help', 'مدد');
  String get gettingStartedGuide => _t('Getting started guide', 'شروع کرنے کا رہنما');
  String get frequentlyAskedQuestions => _t('Frequently asked questions', 'اکثر پوچھے جانے والے سوالات');
  String get contactSupport => _t('Contact Support', 'سپورٹ سے رابطہ');
  String get tapToCall => _t('Tap to call', 'کال کرنے کے لیے ٹیپ کریں');
  String get tapToSendEmail => _t('Tap to send email', 'ای میل بھیجنے کے لیے ٹیپ کریں');
  String get language => _t('Language', 'زبان');
  String get signOut => _t('Sign Out', 'سائن آؤٹ');
  String get signOutConfirm => _t('Are you sure you want to sign out?', 'کیا آپ واقعی سائن آؤٹ کرنا چاہتے ہیں؟');

  // ============================================
  // FAQ Screen
  // ============================================
  String get faqs => _t('FAQs', 'سوالات');
  String get faqsFullTitle => _t('Frequently Asked Questions', 'اکثر پوچھے جانے والے سوالات');
  String get tapQuestionToSee => _t('Tap any question to see the answer', 'جواب دیکھنے کے لیے سوال پر ٹیپ کریں');
  String get stillHaveQuestions => _t('Still have questions? Contact Support from Settings.', 'مزید سوالات؟ ترتیبات سے سپورٹ سے رابطہ کریں۔');

  // FAQ Questions and Answers
  List<Map<String, String>> get faqItems => [
    {
      'question': _t(
        'What is the 5-Tier Quality Classification System?',
        '5 درجاتی کوالٹی درجہ بندی نظام کیا ہے؟',
      ),
      'answer': _t(
        'Jeo Kissan uses AI to grade your crop or fruit into one of five quality tiers:\n\n'
        '• Excellent – Premium export-grade with no defects.\n'
        '• Very Good – High domestic-market grade with only minor cosmetic marks.\n'
        '• Good – Standard market-acceptable quality, safe and nutritious.\n'
        '• Satisfactory – Below average, suitable for processing or value-addition only.\n'
        '• Unsatisfactory – Rejected quality with rot, mould, or heavy damage.\n\n'
        'This helps you know the true market value of your produce before selling.',
        'جیو کسان AI کا استعمال کرتے ہوئے آپ کی فصل یا پھل کو پانچ درجات میں سے ایک میں درجہ بندی کرتا ہے:\n\n'
        '• بہترین – بغیر نقص کے پریمیم برآمدی درجے کا۔\n'
        '• بہت اچھا – صرف معمولی نشانات کے ساتھ اعلیٰ مقامی مارکیٹ کا درجہ۔\n'
        '• اچھا – معیاری مارکیٹ قابل قبول کوالٹی، محفوظ اور غذائیت بخش۔\n'
        '• تسلی بخش – اوسط سے کم، صرف پروسیسنگ کے لیے موزوں۔\n'
        '• غیر تسلی بخش – سڑن، پھپھوندی یا شدید نقصان کے ساتھ مسترد۔\n\n'
        'اس سے آپ کو فروخت سے پہلے اپنی پیداوار کی حقیقی مارکیٹ قیمت معلوم ہوتی ہے۔',
      ),
    },
    {
      'question': _t(
        'How do I inspect my crop or fruit?',
        'میں اپنی فصل یا پھل کا معائنہ کیسے کروں؟',
      ),
      'answer': _t(
        '1. Tap "Start Inspection" on the home screen.\n'
        '2. Choose to capture a photo using your camera or pick one from your gallery.\n'
        '3. Preview the image and tap "Classify Image".\n'
        '4. The AI will analyze the image and ask you 4–5 follow-up questions about the physical condition of the produce.\n'
        '5. Answer the questions using the dropdown options.\n'
        '6. Tap "Get Final Classification" to receive your quality tier and detailed reasons.',
        '1. ہوم اسکرین پر "معائنہ شروع کریں" پر ٹیپ کریں۔\n'
        '2. کیمرے سے تصویر لیں یا گیلری سے منتخب کریں۔\n'
        '3. تصویر کا جائزہ لیں اور "تصویر کی درجہ بندی کریں" پر ٹیپ کریں۔\n'
        '4. AI تصویر کا تجزیہ کرے گا اور آپ سے پیداوار کی جسمانی حالت کے بارے میں 4-5 سوالات پوچھے گا۔\n'
        '5. ڈراپ ڈاؤن آپشنز کا استعمال کرتے ہوئے سوالات کے جوابات دیں۔\n'
        '6. اپنی کوالٹی درجہ اور تفصیلی وجوہات حاصل کرنے کے لیے "حتمی درجہ بندی حاصل کریں" پر ٹیپ کریں۔',
      ),
    },
    {
      'question': _t(
        'What types of commodities can I inspect?',
        'میں کس قسم کی اجناس کا معائنہ کر سکتا ہوں؟',
      ),
      'answer': _t(
        'You can inspect any agricultural commodity including:\n\n'
        '• Fruits – Mango, Apple, Banana, Grapes, Citrus, etc.\n'
        '• Vegetables – Tomato, Potato, Onion, Carrot, etc.\n'
        '• Grains & Cereals – Wheat, Rice, Maize, Barley, etc.\n'
        '• Pulses & Legumes – Lentils, Chickpeas, Beans, etc.\n'
        '• Spices – Turmeric, Chili, Cumin, etc.\n'
        '• Nuts & Dry Fruits – Almonds, Cashews, Raisins, Dates, etc.\n'
        '• Other farm produce – Sugarcane, Cotton, Tea leaves, etc.\n\n'
        'Non-agricultural items will be rejected by the AI.',
        'آپ کسی بھی زرعی جنس کا معائنہ کر سکتے ہیں بشمول:\n\n'
        '• پھل – آم، سیب، کیلا، انگور، مالٹا وغیرہ۔\n'
        '• سبزیاں – ٹماٹر، آلو، پیاز، گاجر وغیرہ۔\n'
        '• اناج – گندم، چاول، مکئی، جو وغیرہ۔\n'
        '• دالیں – مسور، چنے، لوبیا وغیرہ۔\n'
        '• مصالحے – ہلدی، مرچ، زیرہ وغیرہ۔\n'
        '• خشک میوے – بادام، کاجو، کشمش، کھجور وغیرہ۔\n'
        '• دیگر زرعی پیداوار – گنا، کپاس، چائے کے پتے وغیرہ۔\n\n'
        'غیر زرعی اشیاء کو AI مسترد کر دے گا۔',
      ),
    },
    {
      'question': _t(
        'Can I upload multiple images of the same produce?',
        'کیا میں ایک ہی پیداوار کی متعدد تصاویر اپ لوڈ کر سکتا ہوں؟',
      ),
      'answer': _t(
        'Yes! You can select multiple images from your gallery for the same commodity. '
        'The AI will analyze all images together to give a more accurate quality classification. '
        'This is especially useful when you want to show different angles, the top, bottom, or any damaged areas of the produce.',
        'جی ہاں! آپ ایک ہی جنس کے لیے گیلری سے متعدد تصاویر منتخب کر سکتے ہیں۔ '
        'AI تمام تصاویر کا مل کر تجزیہ کرے گا تاکہ زیادہ درست درجہ بندی دے سکے۔ '
        'یہ خاص طور پر مفید ہے جب آپ پیداوار کے مختلف زاویے، اوپر، نیچے، یا خراب حصے دکھانا چاہیں۔',
      ),
    },
    {
      'question': _t(
        'Why does the AI ask follow-up questions after scanning my image?',
        'AI تصویر سکین کرنے کے بعد فالو اپ سوالات کیوں پوچھتا ہے؟',
      ),
      'answer': _t(
        'Some quality factors cannot be determined from a photo alone — such as firmness when pressed, '
        'smell or aroma, internal flesh condition, juiciness, or weight. '
        'The follow-up questions help the AI gather this physical/sensory information from you '
        'so it can give a much more accurate and fair quality rating. '
        'Answer as many as you can; you may skip questions you don\'t know.',
        'کچھ کوالٹی عوامل صرف تصویر سے معلوم نہیں ہو سکتے — جیسے دبانے پر سختی، '
        'خوشبو، اندرونی گوشت کی حالت، رس، یا وزن۔ '
        'فالو اپ سوالات AI کو آپ سے یہ جسمانی/حسیاتی معلومات حاصل کرنے میں مدد کرتے ہیں '
        'تاکہ وہ زیادہ درست اور منصفانہ ریٹنگ دے سکے۔ '
        'جتنے جوابات دے سکیں دیں؛ جو نہ جانیں وہ چھوڑ سکتے ہیں۔',
      ),
    },
    {
      'question': _t(
        'Is an internet connection required?',
        'کیا انٹرنیٹ کنکشن ضروری ہے؟',
      ),
      'answer': _t(
        'Yes, an active internet connection is required for the AI quality analysis. '
        'The app sends your image securely to the AI model for processing. '
        'Without internet, you can still open the app, but the classification feature will not work.',
        'جی ہاں، AI کوالٹی تجزیہ کے لیے فعال انٹرنیٹ کنکشن ضروری ہے۔ '
        'ایپ آپ کی تصویر محفوظ طریقے سے AI ماڈل کو بھیجتی ہے۔ '
        'انٹرنیٹ کے بغیر آپ ایپ کھول سکتے ہیں، لیکن درجہ بندی کا فیچر کام نہیں کرے گا۔',
      ),
    },
    {
      'question': _t(
        'How accurate is the AI classification?',
        'AI درجہ بندی کتنی درست ہے؟',
      ),
      'answer': _t(
        'The AI uses Google\'s Gemini vision model, which is trained on a wide range of agricultural data. '
        'Accuracy improves significantly when you:\n\n'
        '• Take clear, well-lit photos of the produce.\n'
        '• Upload multiple angles if possible.\n'
        '• Answer all follow-up questions honestly.\n\n'
        'The system is designed to be conservative — when uncertain between two tiers, it picks the lower one to protect buyers and maintain trust.',
        'AI گوگل کا Gemini ویژن ماڈل استعمال کرتا ہے جو وسیع زرعی ڈیٹا پر تربیت یافتہ ہے۔ '
        'درستگی نمایاں طور پر بہتر ہوتی ہے جب آپ:\n\n'
        '• پیداوار کی صاف، اچھی روشنی والی تصاویر لیں۔\n'
        '• ممکن ہو تو متعدد زاویوں سے تصاویر اپ لوڈ کریں۔\n'
        '• تمام فالو اپ سوالات کے ایمانداری سے جوابات دیں۔\n\n'
        'نظام محتاط ہے — جب دو درجوں کے درمیان غیر یقینی ہو تو خریداروں کی حفاظت اور اعتماد برقرار رکھنے کے لیے نچلا درجہ منتخب کرتا ہے۔',
      ),
    },
  ];

  // ============================================
  // Helper
  // ============================================
  String _t(String en, String ur) => _lang == 'ur' ? ur : en;

  // Font families for each language
  String get fontFamily => isUrdu ? 'JameelNooriNastaleeq' : 'Roboto';
}

// ============================================
// Delegate
// ============================================
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ur'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
