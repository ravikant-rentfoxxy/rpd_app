import 'package:get/get.dart';

const fallbackPostIssues = [
  {'code': 'WATER', 'name': 'Water', 'nameHi': 'पानी', 'nameBho': 'पानी', 'priority': 1, 'band': 'VERY_HIGH'},
  {'code': 'ROADS_TRANSPORT', 'name': 'Roads & Transport', 'nameHi': 'सड़क और परिवहन', 'nameBho': 'सड़क आ यातायात', 'priority': 2, 'band': 'VERY_HIGH'},
  {'code': 'ELECTRICITY', 'name': 'Electricity', 'nameHi': 'बिजली', 'nameBho': 'बिजली', 'priority': 3, 'band': 'VERY_HIGH'},
  {'code': 'HEALTH', 'name': 'Health', 'nameHi': 'स्वास्थ्य', 'nameBho': 'स्वास्थ्य', 'priority': 4, 'band': 'VERY_HIGH'},
  {'code': 'SANITATION_GARBAGE', 'name': 'Sanitation & Garbage', 'nameHi': 'स्वच्छता और कचरा', 'nameBho': 'सफाई आ कचरा', 'priority': 5, 'band': 'VERY_HIGH'},
  {'code': 'DRAINAGE_SEWERAGE', 'name': 'Drainage & Sewerage', 'nameHi': 'नाली और सीवर', 'nameBho': 'नाली आ सीवर', 'priority': 6, 'band': 'HIGH'},
  {'code': 'EDUCATION', 'name': 'Education', 'nameHi': 'शिक्षा', 'nameBho': 'शिक्षा', 'priority': 7, 'band': 'HIGH'},
  {'code': 'GOVERNMENT_SERVICES', 'name': 'Government Services', 'nameHi': 'सरकारी सेवाएँ', 'nameBho': 'सरकारी सेवा', 'priority': 8, 'band': 'HIGH'},
  {'code': 'PUBLIC_SAFETY', 'name': 'Public Safety', 'nameHi': 'सार्वजनिक सुरक्षा', 'nameBho': 'सार्वजनिक सुरक्षा', 'priority': 9, 'band': 'HIGH'},
  {'code': 'AGRICULTURE_RURAL', 'name': 'Agriculture & Rural Development', 'nameHi': 'कृषि और ग्रामीण विकास', 'nameBho': 'खेती आ गाँव विकास', 'priority': 10, 'band': 'MEDIUM_HIGH'},
  {'code': 'ENVIRONMENT', 'name': 'Environment', 'nameHi': 'पर्यावरण', 'nameBho': 'पर्यावरण', 'priority': 11, 'band': 'MEDIUM'},
  {'code': 'WOMEN_CHILD_WELFARE', 'name': 'Women & Child Welfare', 'nameHi': 'महिला एवं बाल कल्याण', 'nameBho': 'महिला आ बच्चा कल्याण', 'priority': 12, 'band': 'MEDIUM_HIGH'},
  {'code': 'OTHER', 'name': 'Other', 'nameHi': 'अन्य', 'nameBho': 'अउर', 'priority': 13, 'band': 'OTHER'},
];

String issueKey(Map<String, dynamic> issue) {
  final id = '${issue['id'] ?? ''}';
  if (id.isNotEmpty) return id;
  return '${issue['code'] ?? ''}';
}

int issuePriorityOf(Map<String, dynamic> row) {
  final nested = row['issue'];
  final raw = row['issuePriority'] ?? (nested is Map ? nested['priority'] : null);
  if (raw is num) return raw.toInt();
  return int.tryParse('$raw') ?? 999;
}

String issueLabelOf(Map<String, dynamic> row) {
  final nested = row['issue'] is Map ? Map<String, dynamic>.from(row['issue'] as Map) : row;
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

int comparePostsByIssuePriority(Map<String, dynamic> a, Map<String, dynamic> b) {
  final byPriority = issuePriorityOf(a).compareTo(issuePriorityOf(b));
  if (byPriority != 0) return byPriority;
  return '${b['createdAt'] ?? ''}'.compareTo('${a['createdAt'] ?? ''}');
}
