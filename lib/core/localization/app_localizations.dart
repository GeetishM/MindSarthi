import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Nav Tabs
      'nav_home': 'Home',
      'nav_experts': 'Experts',
      'nav_discover': 'Discover',
      'nav_connect': 'Connect',
      'nav_sarthi': 'Sarthi AI',
      
      // Sidebar
      'sb_namaste': 'Namaste,',
      'sb_app_lock': 'App Lock',
      'sb_theme': 'Dark Mode',
      'sb_logout': 'Log Out',
      'sb_language': 'Language / भाषा',
      
      // Profile
      'prof_title': 'Profile',
      'prof_username': 'Username',
      'prof_nickname': 'Nickname',
      'prof_phone': 'Phone Number',
      'prof_gender': 'Gender',
      'prof_select_gender': 'Select Gender',
      'prof_age': 'Age',
      'prof_dob': 'Date of Birth',
      'prof_save': 'Save Profile',
      'prof_saved': 'Profile saved!',
      
      // Home & SOS
      'home_greeting_m': 'Good Morning,',
      'home_greeting_a': 'Good Afternoon,',
      'home_greeting_e': 'Good Evening,',
      'home_daily_goals': "Today's Goals",
      'home_daily_goals_sub': 'Set and track your daily goals to stay motivated.',
      'home_journal': 'Journal',
      'home_journal_sub': 'Your safe space for reflection, growth, and self-discovery.',
      'sos_assist': 'Panic Assist',
      'sos_message': 'Send SOS Message',
      'sos_call': 'Call Now',
      'sos_call_help': 'Call Helpline',
      'sos_change_contact': 'Change SOS Contact',
      'sos_setup': 'Set up your SOS Contact',
      
      // Journal Dashboard
      'jr_title': 'My Journal',
      'jr_new': 'New Entry',
      'jr_search': 'Search journal entries...',
      'jr_filter_all': 'All',
      'jr_filter_written': 'Written',
      'jr_filter_voice': 'Voice',
      'jr_empty': 'No journal entries found.',
      'jr_feel_today': 'How are you feeling today?',
      'jr_record_start': 'Hold to record voice note',
      'jr_record_stop': 'Release to analyze with AI',
      'jr_sentiment': 'Sentiment Insights',
      'jr_ai_processing': 'MindSarthi AI is analyzing your entry...',
      
      // Community
      'comm_title': 'Connect',
      'comm_popular': 'Popular',
      'comm_my_posts': 'My posts',
      'comm_following': 'Following',
      'comm_saved': 'Saved',
      'comm_my_comments': 'My comments',
      'comm_new_post': 'New Post',
      'comm_report': 'Report Post',
      'comm_reported': 'Post reported successfully',
      'comm_loading': 'Loading community posts...',
    },
    'hi': {
      // Nav Tabs
      'nav_home': 'मुख्य पृष्ठ',
      'nav_experts': 'विशेषज्ञ',
      'nav_discover': 'खोजें',
      'nav_connect': 'समुदाय',
      'nav_sarthi': 'सारथी एआई',
      
      // Sidebar
      'sb_namaste': 'नमस्ते,',
      'sb_app_lock': 'ऐप लॉक',
      'sb_theme': 'डार्क मोड',
      'sb_logout': 'लॉग आउट',
      'sb_language': 'भाषा / Language',
      
      // Profile
      'prof_title': 'प्रोफ़ाइल',
      'prof_username': 'उपयोगकर्ता नाम',
      'prof_nickname': 'उपनाम',
      'prof_phone': 'फ़ोन नंबर',
      'prof_gender': 'लिंग',
      'prof_select_gender': 'लिंग चुनें',
      'prof_age': 'आयु',
      'prof_dob': 'जन्म तिथि',
      'prof_save': 'प्रोफ़ाइल सहेजें',
      'prof_saved': 'प्रोफ़ाइल सुरक्षित की गई!',
      
      // Home & SOS
      'home_greeting_m': 'शुभ प्रभात,',
      'home_greeting_a': 'नमस्कार / शुभ दोपहर,',
      'home_greeting_e': 'शुभ संध्या,',
      'home_daily_goals': 'आज के लक्ष्य',
      'home_daily_goals_sub': 'प्रेरित रहने के लिए अपने दैनिक लक्ष्यों को निर्धारित और ट्रैक करें।',
      'home_journal': 'डायरी',
      'home_journal_sub': 'आत्म-चिंतन, विकास और आत्म-खोज के लिए आपका सुरक्षित स्थान।',
      'sos_assist': 'आपातकालीन सहायता',
      'sos_message': 'एसओएस संदेश भेजें',
      'sos_call': 'अभी कॉल करें',
      'sos_call_help': 'हेल्पलाइन कॉल करें',
      'sos_change_contact': 'एसओएस संपर्क बदलें',
      'sos_setup': 'अपना एसओएस संपर्क सेट करें',
      
      // Journal Dashboard
      'jr_title': 'मेरी डायरी',
      'jr_new': 'नई प्रविष्टि',
      'jr_search': 'डायरी प्रविष्टियाँ खोजें...',
      'jr_filter_all': 'सभी',
      'jr_filter_written': 'लिखित',
      'jr_filter_voice': 'आवाज़',
      'jr_empty': 'कोई डायरी प्रविष्टि नहीं मिली।',
      'jr_feel_today': 'आज आप कैसा महसूस कर रहे हैं?',
      'jr_record_start': 'आवाज़ रिकॉर्ड करने के लिए दबाकर रखें',
      'jr_record_stop': 'एआई विश्लेषण के लिए छोड़ें',
      'jr_sentiment': 'भावना विश्लेषण',
      'jr_ai_processing': 'माइंडसारथी एआई आपकी प्रविष्टि का विश्लेषण कर रहा है...',
      
      // Community
      'comm_title': 'समुदाय',
      'comm_popular': 'लोकप्रिय',
      'comm_my_posts': 'मेरी पोस्ट',
      'comm_following': 'फ़ॉलो कर रहे हैं',
      'comm_saved': 'सहेजा गया',
      'comm_my_comments': 'मेरी टिप्पणियाँ',
      'comm_new_post': 'नई पोस्ट',
      'comm_report': 'पोस्ट की रिपोर्ट करें',
      'comm_reported': 'पोस्ट की रिपोर्ट सफलतापूर्वक की गई',
      'comm_loading': 'समुदाय पोस्ट लोड हो रहे हैं...',
    },
    'bn': {
      // Nav Tabs
      'nav_home': 'মূল পাতা',
      'nav_experts': 'বিশেষজ্ঞ',
      'nav_discover': 'অনুসন্ধান',
      'nav_connect': 'যোগাযোগ',
      'nav_sarthi': 'সারথি এআই',
      
      // Sidebar
      'sb_namaste': 'নমস্কার,',
      'sb_app_lock': 'অ্যাপ লক',
      'sb_theme': 'ডার্ক মোড',
      'sb_logout': 'লগ আউট',
      'sb_language': 'ভাষা / Language',
      
      // Profile
      'prof_title': 'প্রোফাইল',
      'prof_username': 'ব্যবহারকারীর নাম',
      'prof_nickname': 'ডাকনাম',
      'prof_phone': 'ফোন নম্বর',
      'prof_gender': 'লিঙ্গ',
      'prof_select_gender': 'লিঙ্গ নির্বাচন করুন',
      'prof_age': 'বয়স',
      'prof_dob': 'জন্ম তারিখ',
      'prof_save': 'প্রোফাইল সংরক্ষণ করুন',
      'prof_saved': 'প্রোফাইল সংরক্ষিত হয়েছে!',
      
      // Home & SOS
      'home_greeting_m': 'সুপ্রভাত,',
      'home_greeting_a': 'শুভ অপরাহ্ন,',
      'home_greeting_e': 'শুভ সন্ধ্যা,',
      'home_daily_goals': 'আজকের লক্ষ্য',
      'home_daily_goals_sub': 'অনুপ্রাণিত থাকতে আপনার দৈনন্দিন লক্ষ্যগুলি সেট করুন এবং ট্র্যাক করুন।',
      'home_journal': 'ডায়েরি',
      'home_journal_sub': 'আত্ম-প্রতিফলন, বিকাশ এবং আত্ম-আবিষ্কারের জন্য আপনার নিরাপদ স্থান।',
      'sos_assist': 'জরুরী সহায়তা',
      'sos_message': 'এসওএস বার্তা পাঠান',
      'sos_call': 'এখনই কল করুন',
      'sos_call_help': 'হেল্পলাইন কল করুন',
      'sos_change_contact': 'এসওএস যোগাযোগ পরিবর্তন করুন',
      'sos_setup': 'আপনার এসওএস যোগাযোগ সেট আপ করুন',
      
      // Journal Dashboard
      'jr_title': 'আমার ডায়েরি',
      'jr_new': 'নতুন এন্ট্রি',
      'jr_search': 'ডায়েরি এন্ট্রি অনুসন্ধান করুন...',
      'jr_filter_all': 'সব',
      'jr_filter_written': 'লিখিত',
      'jr_filter_voice': 'কণ্ঠস্বর',
      'jr_empty': 'কোন ডায়েরি এন্ট্রি পাওয়া যায়নি।',
      'jr_feel_today': 'আজ আপনার কেমন অনুভূতি হচ্ছে?',
      'jr_record_start': 'রেকর্ড করতে চেপে ধরে রাখুন',
      'jr_record_stop': 'এআই বিশ্লেষণের জন্য ছেড়ে দিন',
      'jr_sentiment': 'অনুভূতি বিশ্লেষণ',
      'jr_ai_processing': 'মাইন্ডসারথি এআই আপনার এন্ট্রি বিশ্লেষণ করছে...',
      
      // Community
      'comm_title': 'যোগাযোগ',
      'comm_popular': 'জনপ্রিয়',
      'comm_my_posts': 'আমার পোস্ট',
      'comm_following': 'অনুসরণ করছেন',
      'comm_saved': 'সংরক্ষিত',
      'comm_my_comments': 'আমার মন্তব্য',
      'comm_new_post': 'নতুন পোস্ট',
      'comm_report': 'পোস্ট রিপোর্ট করুন',
      'comm_reported': 'পোস্টটি সফলভাবে রিপোর্ট করা হয়েছে',
      'comm_loading': 'কমিউনিটি পোস্ট লোড হচ্ছে...',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi', 'bn'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
}
