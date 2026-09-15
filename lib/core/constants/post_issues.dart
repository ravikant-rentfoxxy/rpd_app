import 'package:get/get.dart';

const fallbackPostIssues = [
  {
    'code': 'LAND',
    'name': 'Land and revenue',
    'nameHi': 'ज़मीन और राजस्व',
    'nameBho': 'ज़मीन और राजस्व',
    'priority': 1,
    'band': 'VERY_HIGH',
    'children': [
      {'code': 'LAND_DISPUTE', 'name': 'Dispute over land ownership', 'nameHi': 'ज़मीन का विवाद', 'nameBho': 'ज़मीन का विवाद'},
      {'code': 'LAND_ENCROACHMENT', 'name': 'Someone has occupied our land', 'nameHi': 'ज़मीन पर कब्ज़ा', 'nameBho': 'ज़मीन पर कब्ज़ा'},
      {'code': 'COMMON_LAND_GRAB', 'name': 'Village common land taken over', 'nameHi': 'गाँव की सरकारी ज़मीन पर अतिक्रमण', 'nameBho': 'गाँव की सरकारी ज़मीन पर अतिक्रमण'},
      {'code': 'BOUNDARY', 'name': 'Land measurement or boundary marking needed', 'nameHi': 'पैमाइश / सीमांकन', 'nameBho': 'पैमाइश / सीमांकन'},
      {'code': 'MUTATION', 'name': 'Name not changed in land records', 'nameHi': 'दाखिल-खारिज नहीं हुआ', 'nameBho': 'दाखिल-खारिज नहीं हुआ'},
      {'code': 'LAND_RECORD_ERROR', 'name': 'Wrong entry in khatauni or khasra', 'nameHi': 'खतौनी में गलती', 'nameBho': 'खतौनी में गलती'},
      {'code': 'PARTITION', 'name': 'Family land division not done', 'nameHi': 'बंटवारा', 'nameBho': 'बंटवारा'},
      {'code': 'LEKHPAL', 'name': 'Lekhpal or tehsil office not helping', 'nameHi': 'लेखपाल / तहसील की शिकायत', 'nameBho': 'लेखपाल / तहसील की शिकायत'},
      {'code': 'COMPENSATION', 'name': 'Land taken for road or project, payment not received', 'nameHi': 'मुआवजा नहीं मिला', 'nameBho': 'मुआवजा नहीं मिला'},
    ],
  },
  {
    'code': 'WATER',
    'name': 'Drinking water',
    'nameHi': 'पेयजल',
    'nameBho': 'पेयजल',
    'priority': 2,
    'band': 'VERY_HIGH',
    'children': [
      {'code': 'HANDPUMP_BROKEN', 'name': 'Handpump not working', 'nameHi': 'हैंडपंप खराब', 'nameBho': 'हैंडपंप खराब'},
      {'code': 'HANDPUMP_NEEDED', 'name': 'New handpump needed', 'nameHi': 'नया हैंडपंप चाहिए', 'nameBho': 'नया हैंडपंप चाहिए'},
      {'code': 'WATER_DIRTY', 'name': 'Water is dirty or smells', 'nameHi': 'पानी गंदा आ रहा है', 'nameBho': 'पानी गंदा आ रहा है'},
      {'code': 'PIPELINE', 'name': 'Tap water pipeline not laid or leaking', 'nameHi': 'पाइपलाइन की समस्या', 'nameBho': 'पाइपलाइन की समस्या'},
      {'code': 'TANK_MOTOR', 'name': 'Water tank or motor not working', 'nameHi': 'टंकी / मोटर खराब', 'nameBho': 'टंकी / मोटर खराब'},
      {'code': 'WATER_SHORTAGE', 'name': 'No water in summer', 'nameHi': 'गर्मी में पानी की कमी', 'nameBho': 'गर्मी में पानी की कमी'},
    ],
  },
  {
    'code': 'POWER',
    'name': 'Electricity',
    'nameHi': 'बिजली',
    'nameBho': 'बिजली',
    'priority': 3,
    'band': 'VERY_HIGH',
    'children': [
      {'code': 'TRANSFORMER', 'name': 'Transformer burnt or not repaired', 'nameHi': 'ट्रांसफार्मर खराब', 'nameBho': 'ट्रांसफार्मर खराब'},
      {'code': 'POLE_WIRE', 'name': 'Pole broken or wires hanging low', 'nameHi': 'खंभा / तार लटका हुआ', 'nameBho': 'खंभा / तार लटका हुआ'},
      {'code': 'NO_SUPPLY', 'name': 'Very few hours of electricity', 'nameHi': 'बिजली नहीं आती', 'nameBho': 'बिजली नहीं आती'},
      {'code': 'WRONG_BILL', 'name': 'Wrong or inflated bill', 'nameHi': 'गलत बिल', 'nameBho': 'गलत बिल'},
      {'code': 'NEW_CONNECTION', 'name': 'New connection not given', 'nameHi': 'नया कनेक्शन नहीं मिला', 'nameBho': 'नया कनेक्शन नहीं मिला'},
      {'code': 'STREET_LIGHT', 'name': 'Street light not working', 'nameHi': 'स्ट्रीट लाइट खराब', 'nameBho': 'स्ट्रीट लाइट खराब'},
    ],
  },
  {
    'code': 'ROAD_SANITATION',
    'name': 'Roads, drains and sanitation',
    'nameHi': 'सड़क, नाली और सफाई',
    'nameBho': 'सड़क, नाली और सफाई',
    'priority': 4,
    'band': 'VERY_HIGH',
    'children': [
      {'code': 'ROAD_BROKEN', 'name': 'Road broken or full of potholes', 'nameHi': 'सड़क टूटी है', 'nameBho': 'सड़क टूटी है'},
      {'code': 'ROAD_NOT_BUILT', 'name': 'Sanctioned road never built', 'nameHi': 'मंज़ूर सड़क नहीं बनी', 'nameBho': 'मंज़ूर सड़क नहीं बनी'},
      {'code': 'KHARANJA', 'name': 'Village lane needs brick paving', 'nameHi': 'खड़ंजा / गली का काम', 'nameBho': 'खड़ंजा / गली का काम'},
      {'code': 'DRAIN', 'name': 'Drain blocked or overflowing', 'nameHi': 'नाली जाम / गंदा पानी', 'nameBho': 'नाली जाम / गंदा पानी'},
      {'code': 'WATERLOGGING', 'name': 'Water fills up in rain', 'nameHi': 'जलभराव', 'nameBho': 'जलभराव'},
      {'code': 'GARBAGE', 'name': 'Garbage not cleared', 'nameHi': 'कूड़ा नहीं उठता', 'nameBho': 'कूड़ा नहीं उठता'},
      {'code': 'CULVERT_BRIDGE', 'name': 'Culvert or small bridge broken', 'nameHi': 'पुलिया टूटी है', 'nameBho': 'पुलिया टूटी है'},
    ],
  },
  {
    'code': 'RATION',
    'name': 'Ration and food',
    'nameHi': 'राशन',
    'nameBho': 'राशन',
    'priority': 5,
    'band': 'HIGH',
    'children': [
      {'code': 'RATION_CARD_NEW', 'name': 'Ration card not made', 'nameHi': 'राशन कार्ड नहीं बना', 'nameBho': 'राशन कार्ड नहीं बना'},
      {'code': 'NAME_MISSING', 'name': "Family member's name missing", 'nameHi': 'नाम नहीं जुड़ा', 'nameBho': 'नाम नहीं जुड़ा'},
      {'code': 'CARD_CANCELLED', 'name': 'Card cancelled without reason', 'nameHi': 'कार्ड कट गया', 'nameBho': 'कार्ड कट गया'},
      {'code': 'LESS_GRAIN', 'name': 'Dealer gives less than the quota', 'nameHi': 'कम राशन मिलता है', 'nameBho': 'कम राशन मिलता है'},
      {'code': 'DEALER_SHOP', 'name': 'Shop stays shut or dealer misbehaves', 'nameHi': 'कोटेदार की शिकायत', 'nameBho': 'कोटेदार की शिकायत'},
      {'code': 'EKYC', 'name': 'Aadhaar or e-KYC problem on the card', 'nameHi': 'ई-केवाईसी की दिक्कत', 'nameBho': 'ई-केवाईसी की दिक्कत'},
    ],
  },
  {
    'code': 'PENSION',
    'name': 'Pension and welfare payments',
    'nameHi': 'पेंशन',
    'nameBho': 'पेंशन',
    'priority': 6,
    'band': 'HIGH',
    'children': [
      {'code': 'OLD_AGE', 'name': 'Old-age pension not coming', 'nameHi': 'वृद्धावस्था पेंशन नहीं आ रही', 'nameBho': 'वृद्धावस्था पेंशन नहीं आ रही'},
      {'code': 'WIDOW', 'name': 'Widow pension not coming', 'nameHi': 'विधवा पेंशन', 'nameBho': 'विधवा पेंशन'},
      {'code': 'DISABILITY', 'name': 'Disability pension not coming', 'nameHi': 'दिव्यांग पेंशन', 'nameBho': 'दिव्यांग पेंशन'},
      {'code': 'PENSION_NEW', 'name': 'Pension application not approved', 'nameHi': 'पेंशन आवेदन लंबित', 'nameBho': 'पेंशन आवेदन लंबित'},
      {'code': 'BANK_ISSUE', 'name': 'Money not reaching the bank account', 'nameHi': 'खाते में पैसा नहीं आया', 'nameBho': 'खाते में पैसा नहीं आया'},
    ],
  },
  {
    'code': 'NREGA',
    'name': 'MGNREGA and work',
    'nameHi': 'मनरेगा',
    'nameBho': 'मनरेगा',
    'priority': 7,
    'band': 'HIGH',
    'children': [
      {'code': 'JOB_CARD', 'name': 'Job card not made', 'nameHi': 'जॉब कार्ड नहीं बना', 'nameBho': 'जॉब कार्ड नहीं बना'},
      {'code': 'CARD_WITHHELD', 'name': 'Someone else is holding my job card', 'nameHi': 'जॉब कार्ड किसी और के पास है', 'nameBho': 'जॉब कार्ड किसी और के पास है'},
      {'code': 'NO_WORK', 'name': 'No work being given', 'nameHi': 'काम नहीं मिल रहा', 'nameBho': 'काम नहीं मिल रहा'},
      {'code': 'WAGE_DELAY', 'name': 'Wages not paid', 'nameHi': 'मजदूरी नहीं मिली', 'nameBho': 'मजदूरी नहीं मिली'},
      {'code': 'MUSTER_FAKE', 'name': 'Names of people who never worked', 'nameHi': 'फर्जी हाजिरी', 'nameBho': 'फर्जी हाजिरी'},
      {'code': 'WORK_NOT_DONE', 'name': 'Work shown on paper, nothing on ground', 'nameHi': 'कागज़ पर काम, ज़मीन पर नहीं', 'nameBho': 'कागज़ पर काम, ज़मीन पर नहीं'},
    ],
  },
  {
    'code': 'HOUSING',
    'name': 'Housing and toilets',
    'nameHi': 'आवास और शौचालय',
    'nameBho': 'आवास और शौचालय',
    'priority': 8,
    'band': 'HIGH',
    'children': [
      {'code': 'AWAS_NOT_GIVEN', 'name': 'House under PM Awas not sanctioned', 'nameHi': 'आवास नहीं मिला', 'nameBho': 'आवास नहीं मिला'},
      {'code': 'AWAS_INSTALMENT', 'name': 'Instalment not received', 'nameHi': 'किस्त नहीं आई', 'nameBho': 'किस्त नहीं आई'},
      {'code': 'LIST_WRONG', 'name': 'Eligible person left off the list', 'nameHi': 'पात्र का नाम सूची में नहीं', 'nameBho': 'पात्र का नाम सूची में नहीं'},
      {'code': 'TOILET_NOT_BUILT', 'name': 'Toilet money received, not built', 'nameHi': 'शौचालय नहीं बना', 'nameBho': 'शौचालय नहीं बना'},
      {'code': 'TOILET_NEEDED', 'name': 'Toilet needed', 'nameHi': 'शौचालय चाहिए', 'nameBho': 'शौचालय चाहिए'},
    ],
  },
  {
    'code': 'HEALTH',
    'name': 'Health',
    'nameHi': 'स्वास्थ्य',
    'nameBho': 'स्वास्थ्य',
    'priority': 9,
    'band': 'VERY_HIGH',
    'children': [
      {'code': 'PHC_CLOSED', 'name': 'Health centre closed or doctor absent', 'nameHi': 'अस्पताल बंद / डॉक्टर नहीं', 'nameBho': 'अस्पताल बंद / डॉक्टर नहीं'},
      {'code': 'NO_MEDICINE', 'name': 'Medicines not available', 'nameHi': 'दवा नहीं मिलती', 'nameBho': 'दवा नहीं मिलती'},
      {'code': 'ASHA_ANM', 'name': 'ASHA or ANM not visiting', 'nameHi': 'आशा / एएनएम नहीं आतीं', 'nameBho': 'आशा / एएनएम नहीं आतीं'},
      {'code': 'AMBULANCE', 'name': 'Ambulance did not come', 'nameHi': 'एम्बुलेंस नहीं आई', 'nameBho': 'एम्बुलेंस नहीं आई'},
      {'code': 'AYUSHMAN', 'name': 'Ayushman card not made or not accepted', 'nameHi': 'आयुष्मान कार्ड की समस्या', 'nameBho': 'आयुष्मान कार्ड की समस्या'},
      {'code': 'VACCINATION', 'name': 'Vaccination camp not held', 'nameHi': 'टीकाकरण नहीं हुआ', 'nameBho': 'टीकाकरण नहीं हुआ'},
    ],
  },
  {
    'code': 'EDUCATION',
    'name': 'Education and Anganwadi',
    'nameHi': 'शिक्षा और आंगनबाड़ी',
    'nameBho': 'शिक्षा और आंगनबाड़ी',
    'priority': 10,
    'band': 'HIGH',
    'children': [
      {'code': 'TEACHER_ABSENT', 'name': 'Teacher does not come', 'nameHi': 'शिक्षक नहीं आते', 'nameBho': 'शिक्षक नहीं आते'},
      {'code': 'SCHOOL_BUILDING', 'name': 'School building broken, no boundary wall', 'nameHi': 'स्कूल की इमारत खराब', 'nameBho': 'स्कूल की इमारत खराब'},
      {'code': 'MID_DAY_MEAL', 'name': 'Mid-day meal not given or poor quality', 'nameHi': 'मध्याह्न भोजन की शिकायत', 'nameBho': 'मध्याह्न भोजन की शिकायत'},
      {'code': 'ANGANWADI', 'name': 'Anganwadi closed or ration not given', 'nameHi': 'आंगनबाड़ी बंद / पोषाहार नहीं', 'nameBho': 'आंगनबाड़ी बंद / पोषाहार नहीं'},
      {'code': 'SCHOLARSHIP', 'name': 'Scholarship not received', 'nameHi': 'छात्रवृत्ति नहीं मिली', 'nameBho': 'छात्रवृत्ति नहीं मिली'},
      {'code': 'ADMISSION', 'name': 'Admission refused', 'nameHi': 'दाखिला नहीं मिला', 'nameBho': 'दाखिला नहीं मिला'},
    ],
  },
  {
    'code': 'FARMING',
    'name': 'Farming and irrigation',
    'nameHi': 'खेती और सिंचाई',
    'nameBho': 'खेती और सिंचाई',
    'priority': 11,
    'band': 'MEDIUM_HIGH',
    'children': [
      {'code': 'CANAL', 'name': 'Canal water not reaching fields', 'nameHi': 'नहर में पानी नहीं', 'nameBho': 'नहर में पानी नहीं'},
      {'code': 'TUBEWELL', 'name': 'Government tubewell not working', 'nameHi': 'राजकीय नलकूप खराब', 'nameBho': 'राजकीय नलकूप खराब'},
      {'code': 'FERTILIZER', 'name': 'Fertiliser or seed not available, or black-marketed', 'nameHi': 'खाद / बीज नहीं मिल रहा', 'nameBho': 'खाद / बीज नहीं मिल रहा'},
      {'code': 'CROP_INSURANCE', 'name': 'Crop insurance claim not paid', 'nameHi': 'फसल बीमा नहीं मिला', 'nameBho': 'फसल बीमा नहीं मिला'},
      {'code': 'CROP_DAMAGE', 'name': 'Crop damaged by rain, hail or flood', 'nameHi': 'फसल का नुकसान', 'nameBho': 'फसल का नुकसान'},
      {'code': 'STRAY_CATTLE', 'name': 'Stray cattle destroying crops', 'nameHi': 'छुट्टा पशु फसल खा रहे हैं', 'nameBho': 'छुट्टा पशु फसल खा रहे हैं'},
      {'code': 'MANDI_PAYMENT', 'name': 'Payment pending after selling at the mandi', 'nameHi': 'मंडी में भुगतान बाकी', 'nameBho': 'मंडी में भुगतान बाकी'},
    ],
  },
  {
    'code': 'DOCUMENTS',
    'name': 'Certificates and documents',
    'nameHi': 'प्रमाण पत्र',
    'nameBho': 'प्रमाण पत्र',
    'priority': 12,
    'band': 'HIGH',
    'children': [
      {'code': 'CASTE_CERT', 'name': 'Caste certificate not made', 'nameHi': 'जाति प्रमाण पत्र', 'nameBho': 'जाति प्रमाण पत्र'},
      {'code': 'INCOME_CERT', 'name': 'Income certificate not made', 'nameHi': 'आय प्रमाण पत्र', 'nameBho': 'आय प्रमाण पत्र'},
      {'code': 'RESIDENCE_CERT', 'name': 'Domicile certificate not made', 'nameHi': 'निवास प्रमाण पत्र', 'nameBho': 'निवास प्रमाण पत्र'},
      {'code': 'BIRTH_DEATH', 'name': 'Birth or death certificate not made', 'nameHi': 'जन्म / मृत्यु प्रमाण पत्र', 'nameBho': 'जन्म / मृत्यु प्रमाण पत्र'},
      {'code': 'AADHAAR', 'name': 'Aadhaar correction or update', 'nameHi': 'आधार में सुधार', 'nameBho': 'आधार में सुधार'},
    ],
  },
  {
    'code': 'COMMON_PROPERTY',
    'name': 'Village common property',
    'nameHi': 'गाँव की साझी संपत्ति',
    'nameBho': 'गाँव की साझी संपत्ति',
    'priority': 13,
    'band': 'MEDIUM_HIGH',
    'children': [
      {'code': 'POND', 'name': 'Village pond encroached or dried up', 'nameHi': 'तालाब पर कब्ज़ा', 'nameBho': 'तालाब पर कब्ज़ा'},
      {'code': 'GRAZING_LAND', 'name': 'Grazing land occupied', 'nameHi': 'चरागाह पर कब्ज़ा', 'nameBho': 'चरागाह पर कब्ज़ा'},
      {'code': 'CREMATION', 'name': 'No cremation or burial ground', 'nameHi': 'श्मशान / कब्रिस्तान नहीं', 'nameBho': 'श्मशान / कब्रिस्तान नहीं'},
      {'code': 'PANCHAYAT_BHAWAN', 'name': 'Panchayat building unusable', 'nameHi': 'पंचायत भवन खराब', 'nameBho': 'पंचायत भवन खराब'},
      {'code': 'PLAYGROUND', 'name': 'No playground or park', 'nameHi': 'खेल का मैदान नहीं', 'nameBho': 'खेल का मैदान नहीं'},
    ],
  },
  {
    'code': 'GOVERNANCE',
    'name': 'Governance and conduct',
    'nameHi': 'शासन और आचरण',
    'nameBho': 'शासन और आचरण',
    'priority': 14,
    'band': 'HIGH',
    'children': [
      {'code': 'BRIBE', 'name': 'Money demanded for government work', 'nameHi': 'रिश्वत माँगी गई', 'nameBho': 'रिश्वत माँगी गई'},
      {'code': 'FUND_MISUSE', 'name': 'Panchayat funds not spent properly', 'nameHi': 'पंचायत के पैसे का दुरुपयोग', 'nameBho': 'पंचायत के पैसे का दुरुपयोग'},
      {'code': 'NO_GRAM_SABHA', 'name': 'Gram Sabha meeting not held', 'nameHi': 'ग्राम सभा नहीं हुई', 'nameBho': 'ग्राम सभा नहीं हुई'},
      {'code': 'OFFICIAL_ABSENT', 'name': 'Secretary or official never available', 'nameHi': 'सचिव / कर्मचारी नहीं मिलते', 'nameBho': 'सचिव / कर्मचारी नहीं मिलते'},
      {'code': 'ILLEGAL_LIQUOR', 'name': 'Illegal liquor being sold', 'nameHi': 'अवैध शराब', 'nameBho': 'अवैध शराब'},
      {'code': 'TRANSPORT', 'name': 'No bus service or bad connectivity', 'nameHi': 'बस सेवा नहीं', 'nameBho': 'बस सेवा नहीं'},
      {'code': 'NETWORK', 'name': 'No mobile network', 'nameHi': 'मोबाइल नेटवर्क नहीं', 'nameBho': 'मोबाइल नेटवर्क नहीं'},
    ],
  },
];

String issueKey(Map<String, dynamic> issue) {
  final id = '${issue['id'] ?? ''}';
  if (id.isNotEmpty) return id;
  return '${issue['code'] ?? ''}';
}

List<Map<String, dynamic>> issueChildrenOf(Map<String, dynamic> issue) {
  return (issue['children'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
}

int issuePriorityOf(Map<String, dynamic> row) {
  final nested = row['issue'];
  final raw = row['issuePriority'] ?? (nested is Map ? nested['priority'] : null);
  if (raw is num) return raw.toInt();
  return int.tryParse('$raw') ?? 999;
}

String localizedIssueName(Map<String, dynamic> nested) {
  final locale = Get.locale?.languageCode ?? 'en';
  final name = switch (locale) {
    'hi' => nested['nameHi'] ?? nested['issueNameHi'] ?? nested['name'] ?? nested['issueName'],
    'bho' => nested['nameBho'] ?? nested['issueNameBho'] ?? nested['nameHi'] ?? nested['issueNameHi'] ?? nested['name'] ?? nested['issueName'],
    _ => nested['name'] ?? nested['issueName'],
  };
  final text = '${name ?? ''}'.trim();
  if (text.isNotEmpty) return text;
  final code = '${nested['code'] ?? nested['issueCode'] ?? ''}';
  return code.replaceAll('_', ' ');
}

String issueLabelOf(Map<String, dynamic> row) {
  final sub = row['subIssue'] is Map
      ? Map<String, dynamic>.from(row['subIssue'] as Map)
      : {
          if ('${row['subIssueName'] ?? ''}'.trim().isNotEmpty) 'name': row['subIssueName'],
          if ('${row['subIssueNameHi'] ?? ''}'.trim().isNotEmpty) 'nameHi': row['subIssueNameHi'],
          if ('${row['subIssueNameBho'] ?? ''}'.trim().isNotEmpty) 'nameBho': row['subIssueNameBho'],
          if ('${row['subIssueCode'] ?? ''}'.trim().isNotEmpty) 'code': row['subIssueCode'],
        };
  if (localizedIssueName(sub).trim().isNotEmpty) return localizedIssueName(sub);
  final nested = row['issue'] is Map ? Map<String, dynamic>.from(row['issue'] as Map) : row;
  return localizedIssueName(nested);
}

String issuePathLabelOf(Map<String, dynamic>? issue, Map<String, dynamic>? subIssue) {
  if (issue == null && subIssue == null) return '';
  final parent = issue == null ? '' : localizedIssueName(issue);
  final child = subIssue == null ? '' : localizedIssueName(subIssue);
  if (parent.isNotEmpty && child.isNotEmpty) return '$parent · $child';
  return child.isNotEmpty ? child : parent;
}

int comparePostsByIssuePriority(Map<String, dynamic> a, Map<String, dynamic> b) {
  final byPriority = issuePriorityOf(a).compareTo(issuePriorityOf(b));
  if (byPriority != 0) return byPriority;
  return '${b['createdAt'] ?? ''}'.compareTo('${a['createdAt'] ?? ''}');
}
