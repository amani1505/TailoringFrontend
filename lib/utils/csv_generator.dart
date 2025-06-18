import 'package:csv/csv.dart';

class CsvGenerator {
  static Future<void> exportMeasurements(Map<String, dynamic> measurements) async {
    List<List<dynamic>> rows = [
      ['Metric', 'Value'],
      ['Chest', measurements['chest']],
      ['Waist', measurements['waist']],
      ['Hip', measurements['hip']],
    ];
    String csv = const ListToCsvConverter().convert(rows);
    // Save CSV to device storage
  }
}