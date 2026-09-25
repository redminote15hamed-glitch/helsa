import 'package:flutter/material.dart';

class SetupText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String languageCode;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const SetupText(
    this.textKey, {
    super.key,
    this.style,
    this.textAlign,
    this.languageCode = 'fa',
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  static const Map<String, Map<String, String>> _localizedValues = {
    'fa': {
      'title': 'انتخاب زبان',
      'subtitle': 'لطفاً زبان مورد نظر خود را انتخاب نمایید',
      'btn_fa': 'فارسی',
      'btn_en': 'English',
      'btn_fr': 'Français',
      'continue': 'ادامه',
      'familiarity_title': 'نام شما',
      'hint_first_name': 'نام',
      'hint_last_name': 'نام خانوادگی',
      'err_lang': 'لطفاً زبان برنامه را انتخاب کنید.',
      'err_name': 'لطفاً نام و نام خانوادگی خود را وارد نمایید.',
      'gender_title': 'جنسیت شما',
      'gender_female': 'بانو',
      'gender_male': 'آقا',
      'err_gender': 'لطفاً جنسیت خود را مشخص کنید.',
      'age_title': 'سن شما',
      'err_age': 'لطفاً سن خود را وارد نمایید.',
      'age_subtitle': 'سن شما چقدر است؟',
      'physical_data_title': 'اطلاعات فیزیکی',
      'activity_title': 'سطح فعالیت بدنی',
      'weight_title': 'وزن (کیلوگرم)',
      'height_title': 'قد (سانتی‌متر)',
      'waist_title': 'دور کمر (سانتی‌متر)',
      'err_physical_data': 'لطفاً اطلاعات قد، وزن و دور کمر خود را تکمیل کنید.',
      'err_activity_level': 'لطفاً سطح فعالیت بدنی خود را انتخاب کنید.',
      'activity_sedentary': 'کم‌تحرک',
      'activity_light_very': 'بسیار سبک',
      'activity_light': 'متوسط',
      'activity_moderate': 'نسبتاً فعال',
      'activity_active': 'بسیار فعال',
      'activity_desc_sedentary':
          'کمتر از ۳۰ دقیقه فعالیت در هفته. اشتغال در مشاغل پشت میزنشین بدون فعالیت ورزشی منظم.',
      'activity_desc_light_very':
          '۱ تا ۳ ساعت فعالیت سبک در هفته، شامل پیاده‌روی ملایم روزانه یا تمرینات کششی.',
      'activity_desc_light':
          '۳ تا ۵ ساعت فعالیت منظم در هفته، شامل سه جلسه تمرین ورزشی یا پیاده‌روی تند.',
      'activity_desc_moderate':
          '۶ تا ۷ ساعت فعالیت ورزشی در هفته با تحرک بدنی قابل توجه.',
      'activity_desc_active':
          'تمرینات سنگین روزانه (۱.۵ تا ۲ ساعت)، شامل بدنسازی حرفه‌ای یا فعالیت‌های سنگین.',
      'activity_subtitle': 'میزان فعالیت بدنی خود را مشخص کنید.',
      'diet_title': 'رژیم غذایی',
      'diet_subtitle': 'نوع رژیم غذایی خود را انتخاب نمایید',
      'diet_omnivore': 'متعادل (همه چیز)',
      'diet_desc_omnivore':
          'مصرف انواع گروه‌های غذایی شامل گوشت، مرغ، ماهی و فرآورده‌های گیاهی بدون محدودیت.',
      'diet_vegetarian': 'گیاه‌خواری',
      'diet_desc_vegetarian':
          'عدم مصرف گوشت و مرغ، به همراه مصرف تخم‌مرغ و لبنیات.',
      'diet_vegan': 'وگان (گیاه‌خواری مطلق)',
      'diet_desc_vegan':
          'استفاده انحصاری از محصولات گیاهی بدون هیچ‌گونه فرآورده حیوانی.',
      'diet_keto': 'کتوژنیک',
      'diet_desc_keto': 'رژیم غذایی پرچربی و کم‌کربوهیدرات جهت مدیریت وزن.',
      'diet_low_carb': 'کم‌کربوهیدرات',
      'diet_desc_low_carb': 'کاهش میزان دریافت کربوهیدرات جهت تنظیم متابولیسم.',
      'err_diet_level': 'لطفاً نوع رژیم غذایی خود را تعیین کنید.',
      'restriction_title': 'حساسیت‌های غذایی',
      'restriction_subtitle':
          'حساسیت‌ها یا محدودیت‌های غذایی خود را مشخص کنید.',
      'err_restriction_level': 'لطفاً حساسیت‌های غذایی خود را اعلام نمایید.',
      'sleep_title': 'زمان خواب و بیداری',
      'sleep_subtitle': 'ساعات استراحت و خواب خود را مشخص کنید',
      'sleep_time_label': 'زمان خواب',
      'wake_time_label': 'زمان بیداری',
      'sleep_required_error':
          'لطفاً زمان خواب و زمان بیداری خود را انتخاب نمایید',
      'err_sleep': 'لطفاً زمان خواب و زمان بیداری خود را انتخاب نمایید',
    },
    'en': {
      'title': 'Select Language',
      'subtitle': 'Please select your preferred language',
      'btn_fa': 'Persian',
      'btn_en': 'English',
      'btn_fr': 'French',
      'continue': 'Continue',
      'familiarity_title': 'Your Name',
      'hint_first_name': 'First Name',
      'hint_last_name': 'Last Name',
      'err_lang': 'Please select a language.',
      'err_name': 'Please enter your full name.',
      'gender_title': 'Your Gender',
      'gender_female': 'Female',
      'gender_male': 'Male',
      'err_gender': 'Please specify your gender.',
      'age_title': 'Your Age',
      'err_age': 'Please enter your age.',
      'age_subtitle': 'What is your age?',
      'physical_data_title': 'Physical Information',
      'activity_title': 'Activity Level',
      'weight_title': 'Weight (kg)',
      'height_title': 'Height (cm)',
      'waist_title': 'Waist (cm)',
      'err_physical_data':
          'Please complete your height, weight, and waist measurements.',
      'err_activity_level': 'Please select your activity level.',
      'activity_sedentary': 'Sedentary',
      'activity_light_very': 'Very Light',
      'activity_light': 'Moderate',
      'activity_moderate': 'Moderately Active',
      'activity_active': 'Very Active',
      'activity_desc_sedentary':
          'Less than 30 mins/week. Desk job with no regular physical exercise.',
      'activity_desc_light_very':
          '1-3 hours/week of light activity, including daily walks or light stretching.',
      'activity_desc_light':
          '3-5 hours/week of regular exercise, including gym sessions or brisk walking.',
      'activity_desc_moderate': '6-7 hours/week of intense physical activity.',
      'activity_desc_active':
          'Heavy daily training (1.5-2 hours) including professional workouts.',
      'activity_subtitle': 'Select your physical activity level.',
      'diet_title': 'Diet Type',
      'diet_subtitle': 'Choose your dietary preference',
      'diet_omnivore': 'Omnivore',
      'diet_desc_omnivore':
          'Consuming all food groups including meat, poultry, fish, and plant products without restriction.',
      'diet_vegetarian': 'Vegetarian',
      'diet_desc_vegetarian':
          'Excluding meat and poultry, while consuming eggs and dairy products.',
      'diet_vegan': 'Vegan',
      'diet_desc_vegan':
          'Exclusively plant-based products without any animal-derived components.',
      'diet_keto': 'Ketogenic',
      'diet_desc_keto': 'High-fat, low-carb dietary approach.',
      'diet_low_carb': 'Low Carb',
      'diet_desc_low_carb':
          'Reduced carbohydrate intake for metabolic regulation.',
      'err_diet_level': 'Please select your diet type.',
      'restriction_title': 'Food Allergies',
      'restriction_subtitle': 'Specify your food allergies or restrictions.',
      'err_restriction_level': 'Please specify your dietary restrictions.',
      'sleep_title': 'Sleep & Wake Time',
      'sleep_subtitle': 'Configure your resting and sleeping hours',
      'sleep_time_label': 'Sleep time',
      'wake_time_label': 'Wake time',
      'sleep_required_error': 'Please select your sleep and wake times',
      'err_sleep': 'Please select your sleep and wake times',
    },
    'fr': {
      'title': 'Choisir la langue',
      'subtitle': 'Veuillez sélectionner votre langue',
      'btn_fa': 'Persan',
      'btn_en': 'Anglais',
      'btn_fr': 'Français',
      'continue': 'Continuer',
      'familiarity_title': 'Votre Nom',
      'hint_first_name': 'Prénom',
      'hint_last_name': 'Nom de famille',
      'err_lang': 'Veuillez sélectionner une langue.',
      'err_name': 'Veuillez entrer votre nom complet.',
      'gender_title': 'Votre Genre',
      'gender_female': 'Femme',
      'gender_male': 'Homme',
      'err_gender': 'Veuillez spécifier votre genre.',
      'age_title': 'Votre Âge',
      'err_age': 'Veuillez entrer votre âge.',
      'age_subtitle': 'Quel est votre âge ?',
      'physical_data_title': 'Informations Physiques',
      'activity_title': 'Niveau d’activité',
      'weight_title': 'Poids (kg)',
      'height_title': 'Taille (cm)',
      'waist_title': 'Tour de taille (cm)',
      'err_physical_data':
          'Veuillez compléter vos mesures de taille, poids et tour de taille.',
      'err_activity_level': 'Veuillez sélectionner votre niveau d’activité.',
      'activity_sedentary': 'Sédentaire',
      'activity_light_very': 'Très léger',
      'activity_light': 'Modéré',
      'activity_moderate': 'Modérément actif',
      'activity_active': 'Très actif',
      'activity_desc_sedentary':
          'Moins de 30 min/semaine. Travail de bureau sans exercice physique régulier.',
      'activity_desc_light_very':
          '1-3 h/semaine d’activité légère, incluant des promenades quotidiennes.',
      'activity_desc_light':
          '3-5 h/semaine d’exercice régulier, incluant des séances en salle de sport.',
      'activity_desc_moderate': '6-7 h/semaine d’activité physique intense.',
      'activity_desc_active':
          'Entraînement quotidien intense (1.5 à 2 heures).',
      'activity_subtitle': 'Sélectionnez votre niveau d’activité physique.',
      'diet_title': 'Type de Régime',
      'diet_subtitle': 'Choisissez votre préférence alimentaire',
      'diet_omnivore': 'Omnivore',
      'diet_desc_omnivore':
          'Consommation de tous les groupes d’aliments sans restriction.',
      'diet_vegetarian': 'Végétarien',
      'diet_desc_vegetarian':
          'Sans viande ni volaille, avec œufs et produits laitiers.',
      'diet_vegan': 'Vegan',
      'diet_desc_vegan': 'Produits exclusivement d’origine végétale.',
      'diet_keto': 'Cétogène',
      'diet_desc_keto': 'Régime riche en graisses et pauvre en glucides.',
      'diet_low_carb': 'Pauvre en Glucides',
      'diet_desc_low_carb': 'Apport réduit en glucides.',
      'err_diet_level': 'Veuillez sélectionner votre type de régime.',
      'restriction_title': 'Allergies Alimentaires',
      'restriction_subtitle':
          'Veuillez indiquer vos allergies ou restrictions alimentaires.',
      'err_restriction_level':
          'Veuillez spécifier vos restrictions alimentaires.',
      'sleep_title': 'Temps de sommeil et de réveil',
      'sleep_subtitle': 'Configurez vos heures de repos et de sommeil',
      'sleep_time_label': 'Heure de sommeil',
      'wake_time_label': 'Heure de réveil',
      'sleep_required_error':
          'Veuillez sélectionner votre heure de sommeil et votre heure de réveil',
      'err_sleep':
          'Veuillez sélectionner votre heure de sommeil et votre heure de réveil',
    },
  };

  static String getString(String languageCode, String key) {
    final langMap = _localizedValues[languageCode] ?? _localizedValues['fa']!;
    return langMap[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedText = getString(languageCode, textKey);

    // ترکیب استایل‌ها اگر پارامترهای مستقیم داده شده باشند
    final effectiveStyle = style?.copyWith(
          fontSize: fontSize ?? style?.fontSize,
          fontWeight: fontWeight ?? style?.fontWeight,
          color: color ?? style?.color,
        ) ??
        TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );

    return Text(
      resolvedText,
      style: effectiveStyle.fontSize == null &&
              effectiveStyle.color == null &&
              effectiveStyle.fontWeight == null &&
              style == null
          ? null
          : effectiveStyle,
      textAlign: textAlign,
    );
  }
}
